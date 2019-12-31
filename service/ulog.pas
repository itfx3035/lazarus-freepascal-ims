unit uLog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uPath, dateutils, uStrUtils;


type
  TOnLineMonitoringElement = record
    olm_msg:string;
    olm_index:int64;
    olm_dt:tDateTime;
    olm_type:byte;
  end;

procedure AddOnLineMsg(olm_msg:string;olm_type:byte);

procedure WriteLogMsg(log_msg:string);
procedure WriteReportMsg(rep_msg:string);
procedure WriteReportData(rep_msg:string);

procedure WriteOfflinePeriodMsg(td_begin,td_end:TdateTime;msg:string);

implementation

uses uMain;

// olm_type:
// 1 - log
// 2 - report msg
procedure AddOnLineMsg(olm_msg:string;olm_type:byte);
var
  l,x,ind:integer;
  prev_index:int64;
  count_to_delete:integer;
  const5min:Double;
  const_now:TDateTime;
begin
  const5min:=1/288;
  const_now:=now;



  // calculating how many elements we had to delete
  count_to_delete:=0;
  l:=length(uMain.arrOnLineMonitoring);
  for x:=1 to l do
    begin
      ind:=l-x+1;
      if (uMain.arrOnLineMonitoring[ind-1].olm_dt)<(const_now-const5min) then
        begin
          count_to_delete:=count_to_delete+1;
        end;
    end;
  if (l-count_to_delete)<1 then
    begin
      count_to_delete:=l-1;
    end;
  if count_to_delete<0 then
    begin
      count_to_delete:=0;
    end;
  // deleting
  for x:=1 to (l-count_to_delete) do
    begin
      uMain.arrOnLineMonitoring[x-1]:=uMain.arrOnLineMonitoring[x-1+count_to_delete];
    end;
  SetLength(uMain.arrOnLineMonitoring,l-count_to_delete);


  l:=length(uMain.arrOnLineMonitoring);
  if l=0 then
    begin
      prev_index:=0;
    end
    else
    begin
      prev_index:=uMain.arrOnLineMonitoring[l-1].olm_index;
    end;

  setlength(uMain.arrOnLineMonitoring,l+1);
  uMain.arrOnLineMonitoring[l].olm_dt:=const_now;
  uMain.arrOnLineMonitoring[l].olm_index:=prev_index+1;
  uMain.arrOnLineMonitoring[l].olm_msg:=olm_msg;
  uMain.arrOnLineMonitoring[l].olm_type:=olm_type;

end;

procedure WriteLogMsg(log_msg:string);
var
  tf:textfile;
  path:string;
  prefix:string;
  pNow:tDateTime;
begin
  pNow:=now;
  prefix:=DT2STR(pNow)+': ';
  path:=uPath.GetDailyLogFilePath(pNow);

  cs2.Enter;

  AddOnLineMsg(prefix+log_msg,1);

  AssignFile(tf,path);
  try
    if FileExists(path) then
      begin
        Append(tf);
      end
      else
      begin
        rewrite(tf);
      end;
  except
  end;
  try
    writeln(tf,prefix+log_msg);
  except
  end;
  try
    closefile(tf);
  except
  end;

  cs2.Leave;
end;


procedure WriteReportMsg(rep_msg:string);
var
  tf:textfile;
  path:string;
  prefix:string;
  pNow:tDateTime;
begin
  pNow:=now;
  prefix:=DT2STR(pNow)+': ';
  path:=uPath.GetReportLogsFilePath(pNow);

  cs2.Enter;

  AddOnLineMsg(prefix+rep_msg,2);

  AssignFile(tf,path);
  try
    if FileExists(path) then
      begin
        Append(tf);
      end
      else
      begin
        rewrite(tf);
      end;
  except
  end;
  try
    writeln(tf,prefix+rep_msg);
  except
  end;
  try
    closefile(tf);
  except
  end;

  cs2.Leave;
end;


procedure WriteReportData(rep_msg:string);
var
  tf:textfile;
  path:string;
begin
  path:=uPath.GetReportDataFilePath(now);

  cs3.Enter;

  AssignFile(tf,path);

  try
    if FileExists(path) then
      begin
        Append(tf);
      end
      else
      begin
        rewrite(tf);
      end;
  except
  end;
  try
    writeln(tf,rep_msg);
  except
  end;
  try
    closefile(tf);
  except
  end;

  cs3.Leave;
end;

procedure WriteOfflinePeriodMsg(td_begin,td_end:TdateTime;msg:string);
var
  tf:textfile;
  path:string;
  pNow:tDateTime;
  first_dt,curr_dt,last_dt:tDateTime;
  prefix:string;
  tmp_begin_dt,tmp_end_dt:TDateTime;
begin
  pNow:=now;

  first_dt:=int(td_begin);
  curr_dt:=int(td_begin);
  last_dt:=int(td_end);

  cs4.Enter;

  while curr_dt<=last_dt do
    begin
      path:=uPath.GetOfflineLogFilePath(curr_dt);
      AssignFile(tf,path);

      try
        if FileExists(path) then
          begin
            Append(tf);
          end
          else
          begin
            rewrite(tf);
          end;
      except
      end;
      try
        //tmp_begin_dt
        if curr_dt=first_dt then
          begin
            tmp_begin_dt:=td_begin;
          end
          else
          begin
            tmp_begin_dt:=curr_dt;
          end;

        //tmp_end_dt
        if curr_dt=last_dt then
          begin
            tmp_end_dt:=td_end;
          end
          else
          begin
            tmp_end_dt:=dateutils.EndOfTheDay(curr_dt);
          end;

        prefix:=DT2STR(tmp_begin_dt)+' - ';
        prefix:=prefix+DT2STR(tmp_end_dt)+': ';
        writeln(tf,prefix+msg);
      except
      end;
      try
        closefile(tf);
      except
      end;
      curr_dt:=curr_dt+1;
    end;

  cs4.Leave;
end;


end.

