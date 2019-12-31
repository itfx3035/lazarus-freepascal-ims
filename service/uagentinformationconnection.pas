unit uAgentInformationConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, synsock, uLog, uNetwork, uCrypt, uStrUtils,
  uSchedulerExecuter, uAlarm;

type
  TThreadAgentInformationConnection = class(TThread)
  private
    ss:TSocket;
    trAgentInformationLogonPwd:string;

    // status msg array to send
    trArrEventResults:array of uSchedulerExecuter.TEventResult;
    // alarm msg array to send
    trArrAlarmResults:array of uAlarm.TAlarmForIA;


    trLogMsg:string;
    //procedure toLog;
    procedure trWriteLog(msg_str:string);
    procedure trGetSettings;
    procedure trGetActualEventResults;
    procedure trGetActualAlarmResults;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(in_ss: TSocket);
  end;

implementation
uses uMain;

constructor TThreadAgentInformationConnection.Create(in_ss: TSocket);
begin
  inherited create(false);
  FreeOnTerminate := true;
  ss := in_ss;
end;

procedure TThreadAgentInformationConnection.Execute;
var
  S:TTCPBlockSocket;
  alive:boolean;
  res_str:string;
  tmp_int1:integer;
  tmp_str1,tmp_str2,tmp_str3,tmp_str4:string;
  is_valid_logon,is_valid_version:boolean;
  tmp_bool1:boolean;
  x:integer;
begin
  is_valid_logon:=false;
  is_valid_version:=false;
  //Synchronize(@trGetSettings);
  trGetSettings;

  S := TTCPBlockSocket.Create;
  S.Socket:=ss;
  alive:=true;
  While alive do
    begin
      res_str:=uNetwork.GetStringViaSocket(S,600000); // 10 min
      if res_str='' then
        begin
          alive:=false;
          break;
        end;

      // login ==================================
      if leftstr(res_str,9)='log_in_ai' then
        begin
          tmp_str1:=rightstr(res_str,length(res_str)-9);
          tmp_str1:=uCrypt.DecodeString(tmp_str1);
          if tmp_str1=trAgentInformationLogonPwd then
            begin
              is_valid_logon:=true;
              uNetwork.SendStringViaSocket(S,'LOGON SUCCESS',SNDRCVTimeout);
            end
            else
            begin
              uNetwork.SendStringViaSocket(S,'MSGInvalid password!',SNDRCVTimeout);
              alive:=false;
              break;
            end;
          Continue;
        end;
      if leftstr(res_str,7)='app_ver' then
        begin
          tmp_str1:=rightstr(res_str,length(res_str)-7);
          if tmp_str1=umain.GetAppVer() then
            begin
              is_valid_version:=true;
              uNetwork.SendStringViaSocket(S,'APP VERSION VALID',SNDRCVTimeout);
            end
            else
            begin
              uNetwork.SendStringViaSocket(S,'MSGIMS server and agent version must be identical!',SNDRCVTimeout);
              alive:=false;
              break;
            end;
          Continue;
        end;

      // ============ logon must be finished at this time ======================

      if (not is_valid_logon) or (not is_valid_version) then
        begin
          uNetwork.SendStringViaSocket(S,'MSGInvalid logon sequence!',SNDRCVTimeout);
          alive:=false;
          break;
        end;

      if leftstr(res_str,7)='log_out' then
        begin
          uNetwork.SendStringViaSocket(S,'LOGOUT SUCCESS',SNDRCVTimeout);
          alive:=false;
          break;
        end;

      if leftstr(res_str,6)='os_ver' then
        begin
          {$IFDEF WINDOWS}
          uNetwork.SendStringViaSocket(S,'WIN',SNDRCVTimeout);
          {$ENDIF}
          {$IFDEF UNIX}
          uNetwork.SendStringViaSocket(S,'LIN',SNDRCVTimeout);
          {$ENDIF}
          Continue;
        end;
      // ========================================

      // echo ===================================
      if res_str='echo' then
        begin
          uNetwork.SendStringViaSocket(S,'echo_answer',SNDRCVTimeout);
          Continue;
        end;
      // =========================================

      // sts to send ==============================
      if res_str='read_sts' then
        begin
          //Synchronize(@trGetActualEventResults);
          trGetActualEventResults;
          uNetwork.SendStringViaSocket(S,'sts_cnt'+inttostr(Length(trArrEventResults)),SNDRCVTimeout);
          for x:=1 to length(trArrEventResults) do
            begin
              if trArrEventResults[x-1].er_result then
                begin
                  uNetwork.SendStringViaSocket(S,'sts_dta'+trArrEventResults[x-1].er_name+ParamLimiter+'1'+ParamLimiter+floattostr(trArrEventResults[x-1].er_datetime),SNDRCVTimeout);
                end
                else
                begin
                  uNetwork.SendStringViaSocket(S,'sts_dta'+trArrEventResults[x-1].er_name+ParamLimiter+'0'+ParamLimiter+floattostr(trArrEventResults[x-1].er_datetime),SNDRCVTimeout);
                end;
            end;
          Continue;
        end;
      // ==========================================

      // alarm to send ==============================
      if res_str='read_alrm' then
        begin
          //Synchronize(@trGetActualAlarmResults);
          trGetActualAlarmResults;
          uNetwork.SendStringViaSocket(S,'alrm_cnt'+inttostr(Length(trArrAlarmResults)),SNDRCVTimeout);
          for x:=1 to length(trArrAlarmResults) do
            begin
              uNetwork.SendStringViaSocket(S,'alrm_dta'+trArrAlarmResults[x-1].alarm_name+ParamLimiter+floattostr(trArrAlarmResults[x-1].alarm_dt),SNDRCVTimeout);
            end;
          Continue;
        end;
      // ==========================================
    end;
  s.CloseSocket;
end;

procedure TThreadAgentInformationConnection.trGetSettings;
begin
 cs1.Enter;
 trAgentInformationLogonPwd:=uMain.sAgentInformationLogonPwd;
 cs1.Leave;
end;

//procedure TThreadAgentInformationConnection.toLog;
//begin
// uLog.WriteLogMsg(trLogMsg);
//end;

procedure TThreadAgentInformationConnection.trWriteLog(msg_str:string);
begin
 //trLogMsg:=msg_str;
 //Synchronize(@toLog);
 uLog.WriteLogMsg(msg_str);
end;

procedure TThreadAgentInformationConnection.trGetActualEventResults;
var
  x,l:integer;
begin
 cs8.Enter;
 l:=length(uMain.arrEventResultArray);
 setlength(trArrEventResults,l);
 for x:=1 to l do
   begin
     trArrEventResults[x-1]:=uMain.arrEventResultArray[x-1];
   end;
 cs8.Leave;
end;

procedure TThreadAgentInformationConnection.trGetActualAlarmResults;
var
  x,l:integer;
begin
 cs16.Enter;
 l:=length(uMain.arrAlarmForIA);
 setlength(trArrAlarmResults,l);
 for x:=1 to l do
   begin
     trArrAlarmResults[x-1]:=uMain.arrAlarmForIA[x-1];
   end;
 cs16.Leave;
end;

end.

