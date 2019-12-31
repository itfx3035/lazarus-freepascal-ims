unit uMCConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, synsock, uLog, uNetwork, uCrypt, uStrUtils, uScheduler,
  uBatchExecute, uSchedulerExecuter, uAlarm, uReportBuilder;

type
  TThreadMCConnection = class(TThread)
  private
    ss: TSocket;
    trMCLogonPwd: string;

    // settings mirror
    trsManagerConsoleListeningPort: integer;
    trsAgentCollectorListeningPort: integer;
    trsAgentInformationListeningPort: integer;
    trsReservServiceListeningPort: integer;
    trsSudoPwd: string;
    trsMCLogonPwd: string;
    trsAgentInformationLogonPwd: string;

    trarrSchedulerEventsArr: uScheduler.TSchedulerEventArr;
    trarrBatchData: uBatchExecute.TBatchArray;
    trarrAlarmTemplates: uAlarm.TAlarmTemplateArray;

    trarrRTM: array of uLog.TOnLineMonitoringElement;

    trUptimeSec: int64;

    // status msg array to send
    trArrMSG: array of string;

    trLogMsg: string;
    //procedure toLog;
    procedure trWriteLog(msg_str: string);
    procedure trGetSettings;

    procedure trGetRTM;

    procedure trGetSchArr;
    procedure trSetSchArr;
    procedure trGetBatchList;
    procedure trSetBatchList;
    procedure trGetAlarmTemplates;
    procedure trSetAlarmTemplates;

    procedure trGetPrm;
    procedure trSetPrm;

    procedure trGetUptime;

    procedure trAddMSGToSend(m: string);
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(in_ss: TSocket);
  end;

implementation

{ TThreadMCConnection }
uses uMain;

constructor TThreadMCConnection.Create(in_ss: TSocket);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  ss := in_ss;
end;

procedure TThreadMCConnection.trGetUptime;
begin
  cs14.Enter;
  trUptimeSec := trunc((Now - uMain.ServerStartTime) * 24 * 3600);
  cs14.Leave;
end;

procedure TThreadMCConnection.trGetSchArr;
var
  x: integer;
begin
  cs12.Enter;
  Setlength(trarrSchedulerEventsArr, length(uMain.arrSchedulerEventsArr));
  for x := 1 to Length(uMain.arrSchedulerEventsArr) do
  begin
    trarrSchedulerEventsArr[x - 1] := uMain.arrSchedulerEventsArr[x - 1];
  end;
  cs12.Leave;
end;

procedure TThreadMCConnection.trGetRTM;
var
  x: integer;
begin
  cs15.Enter;
  Setlength(trarrRTM, length(uMain.arrOnLineMonitoring));
  for x := 1 to Length(uMain.arrOnLineMonitoring) do
  begin
    trarrRTM[x - 1] := uMain.arrOnLineMonitoring[x - 1];
  end;
  cs15.Leave;
end;

procedure TThreadMCConnection.trSetSchArr;
var
  x, y: integer;
  tmpArrEventResult: array of uSchedulerExecuter.TEventResult;
  found: boolean;
begin
  cs12.Enter;
  Setlength(uMain.arrSchedulerEventsArr, length(trarrSchedulerEventsArr));
  for x := 1 to Length(trarrSchedulerEventsArr) do
  begin
    uMain.arrSchedulerEventsArr[x - 1] := trarrSchedulerEventsArr[x - 1];
  end;
  cs12.Leave;

  // check Event Result array
  cs8.Enter;
  SetLength(tmpArrEventResult, length(uMain.arrEventResultArray));
  for x := 1 to length(uMain.arrEventResultArray) do
  begin
    tmpArrEventResult[x - 1] := uMain.arrEventResultArray[x - 1];
  end;
  setlength(uMain.arrEventResultArray, 0);
  for x := 1 to Length(tmpArrEventResult) do
  begin
    found := False;
    for y := 1 to length(trarrSchedulerEventsArr) do
    begin
      if tmpArrEventResult[x - 1].er_name = trarrSchedulerEventsArr[y - 1].event_name then
      begin
        found := True;
        Continue;
      end;
    end;
    if found then
    begin
      setlength(uMain.arrEventResultArray, length(uMain.arrEventResultArray) + 1);
      uMain.arrEventResultArray[length(uMain.arrEventResultArray) - 1] :=
        tmpArrEventResult[x - 1];
    end;
  end;
  cs8.Leave;


  uMain.SaveSchedulerEvents;
  cs13.Enter;
  uMain.NeedSchedulerUpdate := True;
  cs13.Leave;
end;

procedure TThreadMCConnection.trGetBatchList;
var
  x: integer;
begin
  cs9.Enter;

  Setlength(trarrBatchData, length(uMain.arrBatchData));
  for x := 1 to Length(uMain.arrBatchData) do
  begin
    trarrBatchData[x - 1] := uMain.arrBatchData[x - 1];
  end;

  cs9.Leave;
end;

procedure TThreadMCConnection.trSetBatchList;
var
  x: integer;
begin
  cs9.Enter;
  Setlength(uMain.arrBatchData, length(trarrBatchData));
  for x := 1 to Length(trarrBatchData) do
  begin
    uMain.arrBatchData[x - 1] := trarrBatchData[x - 1];
  end;
  cs9.Leave;

  //cs13.Enter;
  //uMain.NeedSchedulerUpdate := True;
  //cs13.Leave;

  uMain.SaveBatchData;
end;

procedure TThreadMCConnection.trGetAlarmTemplates;
var
  x: integer;
begin
  cs10.Enter;
  Setlength(trarrAlarmTemplates, length(uMain.arrAlarmTemplates));
  for x := 1 to Length(uMain.arrAlarmTemplates) do
  begin
    trarrAlarmTemplates[x - 1] := uMain.arrAlarmTemplates[x - 1];
  end;
  cs10.Leave;
end;

procedure TThreadMCConnection.trSetAlarmTemplates;
var
  x: integer;
begin
  cs10.Enter;
  Setlength(uMain.arrAlarmTemplates, length(trarrAlarmTemplates));
  for x := 1 to Length(trarrAlarmTemplates) do
  begin
    uMain.arrAlarmTemplates[x - 1] := trarrAlarmTemplates[x - 1];
  end;
  cs10.Leave;

  //cs13.Enter;
  //uMain.NeedSchedulerUpdate:=true;
  //cs13.Leave;

  uMain.SaveAlarmTemplates;
end;

procedure TThreadMCConnection.trAddMSGToSend(m: string);
begin
  SetLength(trArrMSG, length(trArrMSG) + 1);
  trArrMSG[length(trArrMSG) - 1] := m;
end;

procedure TThreadMCConnection.Execute;
var
  S: TTCPBlockSocket;
  alive: boolean;
  res_str: string;
  tmp_int1: integer;
  tmp_str1, tmp_str2, tmp_str3, tmp_str4: string;
  tmp_dt1, tmp_dt2: tdatetime;
  is_valid_logon, is_valid_version: boolean;
  tmp_bool1: boolean;
  x: integer;
  curr_bch_cnt, max_bch_cnt, curr_bch_cnt_finished: integer;
  curr_alr_cnt, max_alr_cnt, curr_alr_cnt_finished: integer;
  curr_sch_cnt, max_sch_cnt, curr_sch_cnt_finished: integer;
  tf: textfile;

  last_rtm_index: int64;
  arrTMPRTM: array of uLog.TOnLineMonitoringElement;
begin
  is_valid_logon := False;
  is_valid_version := False;
  //Synchronize(@trGetSettings);
  trGetSettings;

  SetLength(trArrMSG, 0);

  S := TTCPBlockSocket.Create;
  S.Socket := ss;
  alive := True;
  while alive do
  begin
    res_str := uNetwork.GetStringViaSocket(S, 600000); // 10 min
    if res_str = '' then
    begin
      alive := False;
      break;
    end;

    // login ==================================
    if leftstr(res_str, 9) = 'log_in_mc' then
    begin
      tmp_str1 := rightstr(res_str, length(res_str) - 9);
      tmp_str1 := uCrypt.DecodeString(tmp_str1);
      if tmp_str1 = trMCLogonPwd then
      begin
        is_valid_logon := True;
        uNetwork.SendStringViaSocket(S, 'LOGON SUCCESS', SNDRCVTimeout);
      end
      else
      begin
        uNetwork.SendStringViaSocket(S, 'MSGInvalid password!', SNDRCVTimeout);
        alive := False;
        break;
      end;
      Continue;
    end;
    if leftstr(res_str, 7) = 'app_ver' then
    begin
      tmp_str1 := rightstr(res_str, length(res_str) - 7);
      if tmp_str1 = umain.GetAppVer() then
      begin
        is_valid_version := True;
        uNetwork.SendStringViaSocket(S, 'APP VERSION VALID', SNDRCVTimeout);
      end
      else
      begin
        uNetwork.SendStringViaSocket(
          S, 'MSGIMS server and console version must be identical!', SNDRCVTimeout);
        alive := False;
        break;
      end;
      Continue;
    end;

    if (not is_valid_logon) or (not is_valid_version) then
    begin
      uNetwork.SendStringViaSocket(S, 'MSGInvalid logon sequence!', SNDRCVTimeout);
      alive := False;
      break;
    end;

    if leftstr(res_str, 7) = 'log_out' then
    begin
      uNetwork.SendStringViaSocket(S, 'LOGOUT SUCCESS', SNDRCVTimeout);
      alive := False;
      break;
    end;

    if leftstr(res_str, 6) = 'os_ver' then
    begin
          {$IFDEF WINDOWS}
      uNetwork.SendStringViaSocket(S, 'WIN', SNDRCVTimeout);
          {$ENDIF}
          {$IFDEF UNIX}
      uNetwork.SendStringViaSocket(S, 'LIN', SNDRCVTimeout);
          {$ENDIF}
      Continue;
    end;
    // ========================================

    // echo ==========================
    if res_str = 'echo' then
    begin
      uNetwork.SendStringViaSocket(S, 'echo_answer', SNDRCVTimeout);
      Continue;
    end;
    // =========================================

    // uptime ===================================
    if res_str = 'get_uptime' then
    begin
      //Synchronize(@trGetUptime);
      trGetUptime;
      uNetwork.SendStringViaSocket(S, 'uptime' + IntToStr(trUptimeSec), SNDRCVTimeout);
      Continue;
    end;
    // ==========================================

    // msg to send ==============================
    if res_str = 'read_msg' then
    begin
      uNetwork.SendStringViaSocket(S, 'msg_cnt' + IntToStr(Length(trArrMSG)),
        SNDRCVTimeout);
      for x := 1 to length(trArrMSG) do
      begin
        uNetwork.SendStringViaSocket(S, 'msg_str' + trArrMSG[x - 1], SNDRCVTimeout);
      end;
      SetLength(trArrMSG, 0);
      Continue;
    end;
    // ==========================================

    // real time monitoring =======================
    if res_str = 'set_rtm_time' then
    begin
      last_rtm_index := 0;
      //Synchronize(@trGetRTM);
      trGetRTM;
      if Length(trarrRTM) > 0 then
      begin
        last_rtm_index := trarrRTM[Length(trarrRTM) - 1].olm_index;
      end;
      uNetwork.SendStringViaSocket(S, 'rtm_time_ok', SNDRCVTimeout);
      Continue;
    end;
    if res_str = 'read_rtm' then
    begin
      //Synchronize(@trGetRTM);
      trGetRTM;
      // selecting actual data to send
      SetLength(arrTMPRTM, 0);
      for x := 1 to Length(trarrRTM) do
      begin
        if trarrRTM[x - 1].olm_index > last_rtm_index then
        begin
          setlength(arrTMPRTM, length(arrTMPRTM) + 1);
          arrTMPRTM[length(arrTMPRTM) - 1] := trarrRTM[x - 1];
        end;
      end;
      if Length(trarrRTM) > 0 then
      begin
        last_rtm_index := trarrRTM[Length(trarrRTM) - 1].olm_index;
      end;

      // sending data
      uNetwork.SendStringViaSocket(S, 'rtm_cnt' + IntToStr(
        Length(arrTMPRTM)), SNDRCVTimeout);
      for x := 1 to length(arrTMPRTM) do
      begin
        uNetwork.SendStringViaSocket(S, 'rtm_str' + arrTMPRTM[x - 1].olm_msg,
          SNDRCVTimeout);
        uNetwork.SendStringViaSocket(S, 'rtm_typ' + IntToStr(
          arrTMPRTM[x - 1].olm_type), SNDRCVTimeout);
      end;
      Continue;
    end;
    // ==========================================

    // settings param rsv and snd =============
    if leftstr(res_str, 7) = 'get_prm' then
    begin
      //Synchronize(@trGetPrm);
      trGetPrm;

      tmp_str1 := rightstr(res_str, length(res_str) - 7); // param name

      if tmp_str1 = 'ManagerConsoleListeningPort' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + IntToStr(
          trsManagerConsoleListeningPort), SNDRCVTimeout);
      end;
      if tmp_str1 = 'AgentCollectorListeningPort' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + IntToStr(
          trsAgentCollectorListeningPort), SNDRCVTimeout);
      end;
      if tmp_str1 = 'AgentInformationListeningPort' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + IntToStr(
          trsAgentInformationListeningPort), SNDRCVTimeout);
      end;
      if tmp_str1 = 'ReservServiceListeningPort' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + IntToStr(
          trsReservServiceListeningPort), SNDRCVTimeout);
      end;
      if tmp_str1 = 'SudoPwd' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + uCrypt.EncodeString(
          trsSudoPwd), SNDRCVTimeout);
      end;
      if tmp_str1 = 'MCLogonPwd' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + uCrypt.EncodeString(
          trsMCLogonPwd), SNDRCVTimeout);
      end;
      if tmp_str1 = 'AILogonPwd' then
      begin
        uNetwork.SendStringViaSocket(S, 'res_prm' + uCrypt.EncodeString(
          trsAgentInformationLogonPwd), SNDRCVTimeout);
      end;
      Continue;
    end;
    if leftstr(res_str, 7) = 'set_prm' then
    begin
      tmp_str1 := rightstr(res_str, length(res_str) - 7); // param name and new value
      tmp_str2 := GetFieldFromString(tmp_str1, uMain.ParamLimiter, 1); // param name
      tmp_str3 := GetFieldFromString(tmp_str1, uMain.ParamLimiter, 2); // param value
      if tmp_str2 = 'ManagerConsoleListeningPort' then
      begin
        tmp_int1 := trsManagerConsoleListeningPort;
        try
          trsManagerConsoleListeningPort := StrToInt(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_int1 <> trsManagerConsoleListeningPort then
        begin
          trAddMSGToSend('Restarting MC listening service...');
          //Synchronize(@trSetPrm);
          trSetPrm;
          trAddMSGToSend('MC listening service restarted!');
        end;
      end;
      if tmp_str2 = 'AgentCollectorListeningPort' then
      begin
        tmp_int1 := trsAgentCollectorListeningPort;
        try
          trsAgentCollectorListeningPort := StrToInt(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_int1 <> trsAgentCollectorListeningPort then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      if tmp_str2 = 'AgentInformationListeningPort' then
      begin
        tmp_int1 := trsAgentInformationListeningPort;
        try
          trsAgentInformationListeningPort := StrToInt(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_int1 <> trsAgentInformationListeningPort then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      if tmp_str2 = 'ReservServiceListeningPort' then
      begin
        tmp_int1 := trsReservServiceListeningPort;
        try
          trsReservServiceListeningPort := StrToInt(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_int1 <> trsReservServiceListeningPort then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      if tmp_str2 = 'SudoPwd' then
      begin
        tmp_str4 := trsSudoPwd;
        try
          trsSudoPwd := uCrypt.DecodeString(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_str4 <> trsSudoPwd then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      if tmp_str2 = 'MCLogonPwd' then
      begin
        tmp_str4 := trsMCLogonPwd;
        try
          trsMCLogonPwd := uCrypt.DecodeString(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_str4 <> trsMCLogonPwd then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      if tmp_str2 = 'AILogonPwd' then
      begin
        tmp_str4 := trsAgentInformationLogonPwd;
        try
          trsAgentInformationLogonPwd := uCrypt.DecodeString(tmp_str3);
          uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        if tmp_str4 <> trsAgentInformationLogonPwd then
        begin
          //Synchronize(@trSetPrm);
          trSetPrm;
        end;
      end;
      Continue;
    end;
    // ========================================

    // sch list rsv and snd ===================
    if leftstr(res_str, 8) = 'read_sch' then
    begin
      //Synchronize(@trGetSchArr);
      trGetSchArr;
      uNetwork.SendStringViaSocket(S, 'sch_cnt' + IntToStr(
        Length(trarrSchedulerEventsArr)), SNDRCVTimeout);
      for x := 1 to length(trarrSchedulerEventsArr) do
      begin
        //ev_days_of_month: string; // 1,2,5,10,24,31
        //ev_days_of_week: string;  // 1,2,5
        //ev_repeat_type: integer; // 1-once per day, 2-every X seconds
        //ev_repeat_interval: integer; // X seconds
        //ev_time_h: word;
        //ev_time_m: word;
        //ev_time_s: word;
        //ev_end_time_h: word;
        //ev_end_time_m: word;
        //ev_end_time_s: word; - by single string
        tmp_str1 := trarrSchedulerEventsArr[x - 1].ev_days_of_month + ParamLimiter;
        tmp_str1 := tmp_str1 + trarrSchedulerEventsArr[x - 1].ev_days_of_week +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_repeat_type) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(
          trarrSchedulerEventsArr[x - 1].ev_repeat_interval) + ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_time_h) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_time_m) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_time_s) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_end_time_h) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_end_time_m) +
          ParamLimiter;
        tmp_str1 := tmp_str1 + IntToStr(trarrSchedulerEventsArr[x - 1].ev_end_time_s);
        uNetwork.SendStringViaSocket(S, 'sch_prm1' + tmp_str1, SNDRCVTimeout);

        //event_name: string;
        uNetwork.SendStringViaSocket(
          S, 'sch_prm2' + trarrSchedulerEventsArr[x - 1].event_name, SNDRCVTimeout);

        //event_str: string;
        uNetwork.SendStringViaSocket(
          S, 'sch_prm3' + trarrSchedulerEventsArr[x - 1].event_str, SNDRCVTimeout);

        //event_main_param: string;
        uNetwork.SendStringViaSocket(
          S, 'sch_prm4' + trarrSchedulerEventsArr[x - 1].event_main_param, SNDRCVTimeout);

        //event_alarm_str: string;
        uNetwork.SendStringViaSocket(
          S, 'sch_prm5' + trarrSchedulerEventsArr[x - 1].event_alarm_str, SNDRCVTimeout);

        //event_execution_str: string;
        uNetwork.SendStringViaSocket(
          S, 'sch_prm6' + trarrSchedulerEventsArr[x - 1].event_execution_str, SNDRCVTimeout);
      end;
      Continue;
    end;
    if leftstr(res_str, 11) = 'set_sch_cnt' then
    begin
      max_sch_cnt := StrToInt(rightstr(res_str, length(res_str) - 11));
      setlength(trarrSchedulerEventsArr, max_sch_cnt);
      curr_sch_cnt := 0;
      curr_sch_cnt_finished := 0;
      if max_sch_cnt = 0 then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetSchArr);
        trSetSchArr;
      end;
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm1' then
    begin
      curr_sch_cnt := curr_sch_cnt + 1;

      tmp_str1 := rightstr(res_str, length(res_str) - 12);
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_days_of_month :=
        GetFieldFromString(tmp_str1, uMain.ParamLimiter, 1);
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_days_of_week :=
        GetFieldFromString(tmp_str1, uMain.ParamLimiter, 2);
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_repeat_type :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 3));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_repeat_interval :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 4));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_time_h :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 5));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_time_m :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 6));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_time_s :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 7));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_end_time_h :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 8));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_end_time_m :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 9));
      trarrSchedulerEventsArr[curr_sch_cnt - 1].ev_end_time_s :=
        StrToInt(GetFieldFromString(tmp_str1, uMain.ParamLimiter, 10));

      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm2' then
    begin
      trarrSchedulerEventsArr[curr_sch_cnt - 1].event_name :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm3' then
    begin
      trarrSchedulerEventsArr[curr_sch_cnt - 1].event_str :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm4' then
    begin
      trarrSchedulerEventsArr[curr_sch_cnt - 1].event_main_param :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm5' then
    begin
      trarrSchedulerEventsArr[curr_sch_cnt - 1].event_alarm_str :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_sch_prm6' then
    begin
      trarrSchedulerEventsArr[curr_sch_cnt - 1].event_execution_str :=
        rightstr(res_str, length(res_str) - 12);
      curr_sch_cnt_finished := curr_sch_cnt_finished + 1;
      if curr_sch_cnt_finished = max_sch_cnt then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetSchArr);
        trSetSchArr;
      end;
      Continue;
    end;
    // ========================================

    // bch list rsv and snd =============
    if leftstr(res_str, 8) = 'read_bch' then
    begin
      //Synchronize(@trGetBatchList);
      trGetBatchList;
      uNetwork.SendStringViaSocket(S, 'bch_cnt' + IntToStr(
        Length(trarrBatchData)), SNDRCVTimeout);
      for x := 1 to length(trarrBatchData) do
      begin
        //event_name: string;
        uNetwork.SendStringViaSocket(
          S, 'bch_prm1' + trarrBatchData[x - 1].batch_name, SNDRCVTimeout);

        //batch_str: string;
        uNetwork.SendStringViaSocket(
          S, 'bch_prm2' + trarrBatchData[x - 1].batch_str, SNDRCVTimeout);

        //batch_params: string;
        uNetwork.SendStringViaSocket(
          S, 'bch_prm3' + trarrBatchData[x - 1].batch_params, SNDRCVTimeout);
      end;
      Continue;
    end;
    if leftstr(res_str, 11) = 'set_bch_cnt' then
    begin
      max_bch_cnt := StrToInt(rightstr(res_str, length(res_str) - 11));
      setlength(trarrBatchData, max_bch_cnt);
      curr_bch_cnt := 0;
      curr_bch_cnt_finished := 0;
      if max_bch_cnt = 0 then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetBatchList);
        trSetBatchList;
      end;
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_bch_prm1' then
    begin
      curr_bch_cnt := curr_bch_cnt + 1;
      trarrBatchData[curr_bch_cnt - 1].batch_name :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_bch_prm2' then
    begin
      trarrBatchData[curr_bch_cnt - 1].batch_str := rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_bch_prm3' then
    begin
      trarrBatchData[curr_bch_cnt - 1].batch_params :=
        rightstr(res_str, length(res_str) - 12);
      curr_bch_cnt_finished := curr_bch_cnt_finished + 1;
      if curr_bch_cnt_finished = max_bch_cnt then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetBatchList);
        trSetBatchList;
      end;
      Continue;
    end;
    // ========================================

    // alarm templates rsv and snd =============
    if leftstr(res_str, 8) = 'read_alr' then
    begin
      //Synchronize(@trGetAlarmTemplates);
      trGetAlarmTemplates;
      uNetwork.SendStringViaSocket(S, 'alr_cnt' + IntToStr(
        Length(trarrAlarmTemplates)), SNDRCVTimeout);
      for x := 1 to length(trarrAlarmTemplates) do
      begin
        //event_name: string;
        uNetwork.SendStringViaSocket(
          S, 'alr_prm1' + trarrAlarmTemplates[x - 1].alarm_template_name, SNDRCVTimeout);

        //batch_str: string;
        uNetwork.SendStringViaSocket(
          S, 'alr_prm2' + trarrAlarmTemplates[x - 1].alarm_template_str, SNDRCVTimeout);

        //batch_params: string;
        uNetwork.SendStringViaSocket(
          S, 'alr_prm3' + trarrAlarmTemplates[x - 1].alarm_template_params, SNDRCVTimeout);
      end;
      Continue;
    end;
    if leftstr(res_str, 11) = 'set_alr_cnt' then
    begin
      max_alr_cnt := StrToInt(rightstr(res_str, length(res_str) - 11));
      setlength(trarrAlarmTemplates, max_alr_cnt);
      curr_alr_cnt := 0;
      curr_alr_cnt_finished := 0;
      if max_alr_cnt = 0 then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetAlarmTemplates);
        trSetAlarmTemplates;
      end;
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_alr_prm1' then
    begin
      curr_alr_cnt := curr_alr_cnt + 1;
      trarrAlarmTemplates[curr_alr_cnt - 1].alarm_template_name :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_alr_prm2' then
    begin
      trarrAlarmTemplates[curr_alr_cnt - 1].alarm_template_str :=
        rightstr(res_str, length(res_str) - 12);
      Continue;
    end;
    if leftstr(res_str, 12) = 'set_alr_prm3' then
    begin
      trarrAlarmTemplates[curr_alr_cnt - 1].alarm_template_params :=
        rightstr(res_str, length(res_str) - 12);
      curr_alr_cnt_finished := curr_alr_cnt_finished + 1;
      if curr_alr_cnt_finished = max_alr_cnt then
      begin
        uNetwork.SendStringViaSocket(S, 'res_suc', SNDRCVTimeout);
        // reload execution
        //Synchronize(@trSetAlarmTemplates);
        trSetAlarmTemplates;
      end;
      Continue;
    end;
    // ========================================

    // report generate ========================
    if leftstr(res_str, 7) = 'get_rep' then
    begin
      tmp_str1 := rightstr(res_str, length(res_str) - 7);
      tmp_dt1 := strtofloat(GetFieldFromString(tmp_str1, ParamLimiter, 1));
      tmp_dt2 := strtofloat(GetFieldFromString(tmp_str1, ParamLimiter, 2));
      tmp_str2 := GetFieldFromString(tmp_str1, ParamLimiter, 3);
      tmp_str3 := uReportBuilder.BuildReport(tmp_dt1, tmp_dt2, tmp_str2, True, S);
      if FileExists(tmp_str3) then
      begin
        uNetwork.SendStringViaSocket(S, 'rep_res_fname' +
          ExtractFileName(tmp_str3), SNDRCVTimeout);
        assignFile(tf, tmp_str3);
        try
          reset(tf);
          while not EOF(tf) do
          begin
            readln(tf, tmp_str2);
            uNetwork.SendStringViaSocket(S, 'rep_res_str' + tmp_str2, SNDRCVTimeout);
          end;
          closefile(tf);
        except
          uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
        end;
        try
          DeleteFile(tmp_str3);
        except
        end;
        uNetwork.SendStringViaSocket(S, 'rep_fin', SNDRCVTimeout);
      end
      else
      begin
        uNetwork.SendStringViaSocket(S, 'res_err', SNDRCVTimeout);
      end;
    end;
    // ========================================
  end;
  s.CloseSocket;
end;

procedure TThreadMCConnection.trGetSettings;
begin
  cs1.Enter;
  trMCLogonPwd := uMain.sMCLogonPwd;
  cs1.Leave;
end;

procedure TThreadMCConnection.trGetPrm;
begin
  cs1.Enter;
  trsMCLogonPwd := uMain.sMCLogonPwd;
  trsAgentInformationLogonPwd := uMain.sAgentInformationLogonPwd;
  trsManagerConsoleListeningPort := umain.sManagerConsoleListeningPort;
  trsAgentCollectorListeningPort := umain.sAgentCollectorListeningPort;
  trsAgentInformationListeningPort := umain.sAgentInformationListeningPort;
  trsReservServiceListeningPort := umain.sReservServiceListeningPort;
  trsSudoPwd := umain.sSudoPwd;
  cs1.Leave;
end;

procedure TThreadMCConnection.trSetPrm;
begin
  cs1.Enter;
  if uMain.sManagerConsoleListeningPort <> trsManagerConsoleListeningPort then
  begin
    uMain.sManagerConsoleListeningPort := trsManagerConsoleListeningPort;
    // restart  ManagerConsoleListening thread
    uMain.StopManagerConsoleListener;
    uMain.StartManagerConsoleListener;
  end;
  if uMain.sAgentCollectorListeningPort <> trsAgentCollectorListeningPort then
  begin
    uMain.sAgentCollectorListeningPort := trsAgentCollectorListeningPort;
    // restart  AgentCollectorListening thread

  end;
  if uMain.sAgentInformationListeningPort <> trsAgentInformationListeningPort then
  begin
    uMain.sAgentInformationListeningPort := trsAgentInformationListeningPort;
    // restart  AgentInformationListening thread

  end;
  if uMain.sReservServiceListeningPort <> trsReservServiceListeningPort then
  begin
    uMain.sReservServiceListeningPort := trsReservServiceListeningPort;
    // restart  ReservServiceListening thread

  end;
  if uMain.sMCLogonPwd <> trsMCLogonPwd then
  begin
    uMain.sMCLogonPwd := trsMCLogonPwd;
  end;
  if uMain.sAgentInformationLogonPwd <> trsAgentInformationLogonPwd then
  begin
    uMain.sAgentInformationLogonPwd := trsAgentInformationLogonPwd;
  end;
  if uMain.sSudoPwd <> trsSudoPwd then
  begin
    uMain.sSudoPwd := trsSudoPwd;
  end;
  cs1.Leave;

  uMain.SaveSettings;
end;

//procedure TThreadMCConnection.toLog;
//begin
// uLog.WriteLogMsg(trLogMsg);
//end;

procedure TThreadMCConnection.trWriteLog(msg_str: string);
begin
  //trLogMsg:=msg_str;
  //Synchronize(@toLog);
  uLog.WriteLogMsg(msg_str);
end;

end.
