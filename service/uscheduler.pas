unit uScheduler;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, strutils;

type
  TSchedulerEvent = record
    ev_days_of_month: string; // 1,2,5,10,24,31
    ev_days_of_week: string;  // 1,2,5
    ev_repeat_type: integer; // 1-once per day, 2-every X seconds
    ev_repeat_interval: integer; // X seconds
    ev_time_h: word;
    ev_time_m: word;
    ev_time_s: word;
    ev_end_time_h: word;
    ev_end_time_m: word;
    ev_end_time_s: word;

    event_name: string;
    event_str: string;
    event_main_param: string;

    event_alarm_str: string;
    event_execution_str: string;
  end;
  TSchedulerEventArr = array of TSchedulerEvent;

  TNextEvent = record
    nev: TDateTime;   // date and time of next event execution
    nev_s_ev: TSchedulerEvent;
  end;
  TNextEventArr = array of TNextEvent;


  TThreadScheduler = class(TThread)
  private
    { Private declarations }
    trNeedRecalc: boolean;
    trSchedulerEventsArr: TSchedulerEventArr;
    trNextEventsArr: TNextEventArr;
    trExecuteEventQArr:TSchedulerEventArr;

    procedure SchedulerUpdate;
    procedure ExecuterUpdate;
  protected
    { Protected declarations }
    procedure Execute; override;
  end;

implementation

{ TThreadScheduler }
uses uMain;

procedure TThreadScheduler.Execute;
var
  x: integer;
  day_o_w, day_o_m: integer;
  day_o_m_text:string;
  day_o_y, last_day: word;
  pNow: tDateTime;
  cSchedulerEvent: TSchedulerEvent;
  cNextEvent: TNextEvent;
  next_dt,finish_dt: tdatetime;
  last_pNow: TDateTime;
begin
  { Write your thread code here }
  last_day := 0;
  last_pNow := Now;
  setlength(trSchedulerEventsArr, 0);
  SetLength(trNextEventsArr, 0);
  SetLength(trExecuteEventQArr, 0);
  trNeedRecalc := True;

  while True do
    begin
      if Terminated then
        begin
          exit;
        end;

      pNow := now;
      day_o_y := DayOfTheYear(pNow);
      if last_day <> day_o_y then
        begin
          trNeedRecalc := True;
        end;
      //Synchronize(@SchedulerUpdate); // cheking if we need to update event list
      SchedulerUpdate; // cheking if we need to update event list
      if trNeedRecalc then // checkin' if we need to recalculate next events list
        begin
          SetLength(trNextEventsArr, 0);
          for x := 1 to length(trSchedulerEventsArr) do
            begin
              cSchedulerEvent := trSchedulerEventsArr[x - 1];
              day_o_m := DayOfTheMonth(pNow);
              day_o_m_text:=inttostr(day_o_m);
              if length(day_o_m_text)=1 then
                begin
                  day_o_m_text:='0'+day_o_m_text;
                end;
              if not strutils.AnsiContainsText(cSchedulerEvent.ev_days_of_month, day_o_m_text+',') then
                begin
                  Continue; // no that day of month
                end;
              day_o_w := DayOfTheWeek(pNow);
              if not strutils.AnsiContainsText(cSchedulerEvent.ev_days_of_week, IntToStr(day_o_w)+',') then
                begin
                  Continue; // no that day of week
                end;
              next_dt := EncodeDateTime(YearOf(pNow), MonthOf(pNow), day_o_m,
                                        cSchedulerEvent.ev_time_h,
                                        cSchedulerEvent.ev_time_m,
                                        cSchedulerEvent.ev_time_s, 0);
              if cSchedulerEvent.ev_repeat_type = 1 then
                begin // once a day
                  if (next_dt<=last_pNow) then
                    begin
                      Continue; // already in past
                    end;
                end;
              if cSchedulerEvent.ev_repeat_type = 2 then
                begin // repeat
                  finish_dt := EncodeDateTime(YearOf(pNow), MonthOf(pNow), day_o_m,
                                              cSchedulerEvent.ev_end_time_h,
                                              cSchedulerEvent.ev_end_time_m,
                                              cSchedulerEvent.ev_end_time_s, 0);

                  while (next_dt<=last_pNow) and (day_o_y=DayOfTheYear(next_dt)) do
                    begin
                      next_dt:=next_dt+cSchedulerEvent.ev_repeat_interval/86400;
                    end;
                  if next_dt>finish_dt then
                     begin
                       Continue; // no next event today
                     end;
                  if day_o_y<>DayOfTheYear(next_dt) then
                    begin
                      Continue; // no next event today
                    end;
                  if next_dt<=last_pNow then
                    begin
                      Continue; // no next event today
                    end;
                end;
              Setlength(trNextEventsArr,length(trNextEventsArr)+1);
              trNextEventsArr[length(trNextEventsArr)-1].nev:=next_dt;
              trNextEventsArr[length(trNextEventsArr)-1].nev_s_ev:=cSchedulerEvent;
            end;
          trNeedRecalc := False;
        end;

      // proceed with ready array of TNextEvent
      For x:=1 to length(trNextEventsArr) do
        begin
          cNextEvent:=trNextEventsArr[x-1];
          if cNextEvent.nev<=pNow then
            begin
              // need to execute this event
              setlength(trExecuteEventQArr,length(trExecuteEventQArr)+1);
              trExecuteEventQArr[length(trExecuteEventQArr)-1]:=cNextEvent.nev_s_ev;
              trNeedRecalc := true;
            end;
        end;
      if Length(trExecuteEventQArr)>0 then
        begin
          //Synchronize(@ExecuterUpdate);
          ExecuterUpdate;
        end;

      last_day := day_o_y;
      last_pNow := pNow;
      sleep(700);
    end;
end;

procedure TThreadScheduler.SchedulerUpdate;
var
  x:integer;
  pNeedSchedulerUpdate:boolean;
begin
  cs13.Enter;
  pNeedSchedulerUpdate:=uMain.NeedSchedulerUpdate;
  cs13.Leave;

  if pNeedSchedulerUpdate then
    begin
      cs12.Enter;
      setlength(trSchedulerEventsArr,length(uMain.arrSchedulerEventsArr));
      for x:=1 to length(uMain.arrSchedulerEventsArr) do
        begin
          trSchedulerEventsArr[x-1]:=uMain.arrSchedulerEventsArr[x-1];
        end;
      trNeedRecalc := True;
      cs12.Leave;

      cs13.Enter;
      uMain.NeedSchedulerUpdate := False;
      cs13.Leave;
    end;
end;

procedure TThreadScheduler.ExecuterUpdate;
var
  x:integer;
begin
  cs5.Enter;
  for x:=1 to length(trExecuteEventQArr) do
    begin
      setlength(uMain.arrExecuteEventArr,length(uMain.arrExecuteEventArr)+1);
      uMain.arrExecuteEventArr[length(uMain.arrExecuteEventArr)-1]:=trExecuteEventQArr[x-1];
    end;
  cs5.Leave;

  cs6.Enter;
  uMain.NeedExecuterUpdate:=true;
  cs6.Leave;

  setlength(trExecuteEventQArr,0);
end;


end.




