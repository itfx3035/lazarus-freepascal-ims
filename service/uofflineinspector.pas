unit uOfflineInspector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uConst, uLog;

type
  TThreadOfflineInspector = class(TThread)
  private
    { Private declarations }
    to_log_msg:string;
    to_log_dt_begin,to_log_dt_end:TDateTime;
    procedure toLog;
    procedure WriteOffline(dt_b,dt_e:tdatetime;msg:string);
  protected
    { Protected declarations }
    procedure Execute; override;
  end;

implementation

{ TThreadOfflineInspector }

procedure TThreadOfflineInspector.Execute;
var
  tmp:string;
  c_name,c_name_ui:string;
  dt,pNow,dt_90sec:tDateTime;
  x:integer;
begin
  FreeOnTerminate:=true;
  c_name:='OfflineInspectorHeartbeat';
  c_name_ui:='OfflineInspectorHeartbeatUI';
  dt_90sec:=1.5/(24*60);
  While true do
   begin
     pNow:=now;
     tmp:=ReadConst(c_name);
     if tmp='' then
       begin
         // write offline period
         WriteOffline(int(pNow),pNow,'Offline before first run');
         // ====================
       end
       else
       begin
         dt:=strtofloat(tmp);
         if pNow-dt>dt_90sec then
           begin
             // write offline period
             WriteOffline(dt,pNow,'Offline');
             // ====================
           end;
       end;
     WriteConst(c_name,floattostr(pNow));
     WriteConst(c_name_ui,FormatDateTime('yyyy.mm.dd hh:nn.ss',pNow));
     //Sleep(60000);
     for x:=1 to 60 do
       begin
         if Terminated then
           begin
             exit;
           end;
         sleep(1000);
       end;
   end;
end;

procedure TThreadOfflineInspector.WriteOffline(dt_b,dt_e:tdatetime;msg:string);
begin
  to_log_msg:=msg;
  to_log_dt_begin:=dt_b;
  to_log_dt_end:=dt_e;
  //Synchronize(@toLog);
  toLog;
end;

procedure TThreadOfflineInspector.toLog;
begin
  WriteOfflinePeriodMsg(to_log_dt_begin,to_log_dt_end,to_log_msg);
end;

end.

