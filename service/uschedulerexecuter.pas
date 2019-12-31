unit uSchedulerExecuter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uScheduler, uStrUtils, pingsend, synaip, blcksock,
  uLog, uNetwork, httpsend, uBatchExecute, uConst, uReportBuilder, uMail,
  uAlarm;

type
  TEventResult = record
    er_name: string;
    er_datetime: tdatetime;
    er_result: boolean;
  end;

  TThreadSchedulerExecuter = class(TThread)
  private
    { Private declarations }
    trExecuteEventArr: uScheduler.TSchedulerEventArr;
    trLogMsg: string;
    trBatchData: uBatchExecute.TBatchArray;
    trBatchName: string;
    trAlarmTemplateName: string;
    trBatchRes: uBatchExecute.TBatch;
    trAlarmTemplateRes: uAlarm.TAlarmTemplate;
    trSudoPwd: string;

    trEventName: string;
    trEventResult: boolean;
    trEventDT: tdatetime;

    trCurrThreadEvent: uScheduler.TSchedulerEvent;
    trarrAddAlarmForIA:array of TDateTime;

    // var for report generating
    trReportFilePath: string;
    trReport_dt_begin, trReport_dt_end: TDateTime;
    trReport_params: string;
    procedure trBuildReport;
    // =========================

    procedure trWriteEventResult;
    procedure SyncWriteEventResult(event:TSchedulerEvent; event_result: boolean;
      event_dt: tdatetime);

    procedure ExecuterUpdate;
    procedure FindBatchByName;
    procedure FindAlarmTemplateByName;
    procedure AddAlarmForIA;

    procedure DoExecution(Res: boolean; trEvent:uScheduler.TSchedulerEvent);
    procedure DoAlarm(Res: boolean; trEvent:uScheduler.TSchedulerEvent);

    //procedure toLog;
    procedure trWriteLog(msg_str: string);
    //procedure toReportMSG;
    procedure trWriteReportMSG(msg_str: string);
    //procedure toReportData;
    procedure trWriteReportData(msg_str: string);

    function trCheckLastResult(ConstName: string; curr_res:boolean; max_count: integer): boolean;
    function trIsResultChanged(ConstName: string; curr_res:boolean; max_count: integer): boolean;
    procedure trSetNewResult(ConstName:string; curr_res:boolean);
  protected
    { Protected declarations }
    procedure Execute; override;
  end;

const
  ev_report_prefix = 'ev_rprt_';
  ev_execution_prefix = 'ev_exec_';
  ev_alarm_prefix = 'ev_alrm_';

implementation

{ TThreadSchedulerExecuter }
uses uMain;

procedure TThreadSchedulerExecuter.trBuildReport;
var
  bs: blcksock.TTCPBlockSocket;
begin
  trReportFilePath := uReportBuilder.BuildReport(trReport_dt_begin,
    trReport_dt_end, trReport_params, False, bs);
end;

procedure TThreadSchedulerExecuter.Execute;
var
  SR: TSocketResult;
  r:integer;
  r_str:string;
  tbs: blcksock.TBlockSocket;
  tps: pingsend.TPINGSend;
  event_inc_x: integer;
  trEvent: uScheduler.TSchedulerEvent;
  event_str, event_alarm_str, event_main_param: string;
  event_class, event_class2, event_class3: string;
  tmp_param1, tmp_param2, tmp_param3: string;
  x: integer;
  tmp_bool1: boolean;
  tmp_int1: integer;
  tmp_str1, tmp_str2: string;
  tmp_date1, tmp_date2: tdatetime;
  event_report_type, event_alarm_type: string;
  event_stat_type, event_stat_name: string;
  result_max_count: integer;
  HTTP: httpsend.THTTPSend;
  tmp_string_list: TStringList;
  OperationResult: boolean;
  found:boolean;
begin
  SetLength(trExecuteEventArr, 0);
  while True do
  begin
    if Terminated then
    begin
      exit;
    end;
    //Synchronize(@ExecuterUpdate);
    ExecuterUpdate;
    for event_inc_x := 1 to length(trExecuteEventArr) do
    begin
      trEvent := trExecuteEventArr[event_inc_x - 1];
      trCurrThreadEvent:=trEvent;
      event_str := trEvent.event_str;
      event_main_param := trEvent.event_main_param;
      event_alarm_str := trEvent.event_alarm_str;
      event_class := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 1);

      // 1 - network skanning
      // ======================================================================
      if event_class = '1' then
      begin
        event_class2 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 2);
        // (1°1) get all ip's in network
        if event_class2 = '1' then
        begin
          tmp_param3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 3);
          // ping timeout

          tps := pingsend.TPINGSend.Create;
          tps.Timeout := StrToInt(tmp_param3);

          trWriteReportMSG('9 Begin network scan execution log: [' +
            trEvent.event_name + ']');
          tmp_int1 := 0;
          for x := 1 to 255 do
          begin
            tmp_param2 := trim(event_main_param) + '.' + IntToStr(x);
            // ip to check
            tmp_bool1 := False;
            // ping
            if tps.Ping(tmp_param2) then
            begin
              tmp_bool1 := True;
            end;
            if tmp_bool1 then
            begin
              tmp_int1 := tmp_int1 + 1;
              trWriteReportMSG('9 - Online IP: ' + tmp_param2);
            end;
          end;
          trWriteReportMSG('9 > 255 checked, ' + IntToStr(tmp_int1) + ' online');
          trWriteReportMSG('9 End network scan execution log: [' +
            trEvent.event_name + ']');
        end;
      end;
      // ===========================================================




      // 2 - execute any process
      // ============================================================
      if event_class = '2' then
      begin
        tmp_param3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 2);
        trBatchName := trim(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 3));
        //Synchronize(@FindBatchByName);
        FindBatchByName;
        if trBatchRes.batch_name = '' then
        begin
          trWriteLog('Internal error! Batch not found: ' + trBatchName);
        end
        else
        begin
          tmp_string_list := uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
          for x := 1 to tmp_string_list.Count do
          begin
            if tmp_string_list[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Batch ' + trBatchName + ' decoding error!');
              Break;
            end;
            if tmp_param3 = '1' then
            begin
              trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
            end;
          end;
        end;
      end;
      // =================================================================



      // 3 - report
      // ==================================================================
      if event_class = '3' then
      begin
        event_class2 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 2);
        if event_class2 = '1' then // report
        begin
          event_class3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 3);
          if event_class3 = '1' then // e-mail
          begin

            tmp_date2 := now;
            tmp_str1 := ReadConst('LastReportSendingEMailDate');
            if tmp_str1 = '' then
            begin
              tmp_date1 := tmp_date2 - 7;
            end
            else
            begin
              tmp_date1 := strtofloat(tmp_str1);
            end;
            tmp_str2 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 4);

            //tmp_str1 := uReportBuilder.BuildReport(
            //  tmp_date1, tmp_date2, tmp_str2, False, bs);
            trReport_dt_begin := tmp_date1;
            trReport_dt_end := tmp_date2;
            trReport_params := tmp_str2;
            //Synchronize(@trBuildReport);
            trBuildReport;
            tmp_str1 := trReportFilePath;

            if (tmp_str1 = '') or (not FileExists(tmp_str1)) then
            begin
              trWriteLog('Error creating report file!');
            end
            else
            begin
              // sending file

              tmp_str2 := uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 3);
              if uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 4) <> '' then
              begin
                tmp_str2 := tmp_str2 + ':' +
                  uStrUtils.GetFieldFromString(event_main_param, ParamLimiter, 4);
              end;
              tmp_int1 := uMail.SendMailAttachment(uStrUtils.GetFieldFromString(
                event_main_param, ParamLimiter, 1), // send from email
                uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 2), // send to email
                uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 7), // subject
                tmp_str2, // smtp host[:port]
                uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 5), // login
                uStrUtils.GetFieldFromString(event_main_param,
                ParamLimiter, 6), // password
                tmp_str1  // file path
                );

              if tmp_int1 = 1 then
              begin
                // seems to be OK, must save last report generating datetime
                uConst.WriteConst('LastReportSendingEMailDate',
                  floattostr(tmp_date2));
              end
              else
              begin
                trWriteLog('Error sending report file! Check e-mail settings, please.');
              end;
              try
                DeleteFile(tmp_str1);
              except
              end;
            end;
          end;
        end;
      end;
      // ==================================================================



      // 4 - on-demand monitoring
      // ==================================================================
      if event_class = '4' then
      begin
        event_class2 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 2);
        // (4°1) external (passive)
        if event_class2 = '1' then
        begin
          event_class3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 3);

          // (4°1°1) ping ----------------------------
          if event_class3 = '1' then
          begin
            OperationResult := False;

            event_report_type :=
              uStrUtils.GetFieldFromString(event_str, ParamLimiter, 4);
            event_alarm_type :=
              uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 1);
            event_stat_type := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 6);
            event_stat_name := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 7);
            // 1 - direct log, 2 - stat. collect.
            tmp_param1 := event_main_param; // ip or network name
            tmp_param2 := tmp_param1;
            if not synaip.IsIP(tmp_param1) then
            begin
              tbs := blcksock.TBlockSocket.Create;
              tmp_param1 := tbs.ResolveName(tmp_param1);
            end;

            if (not synaip.IsIP(tmp_param1)) or (tmp_param1 = '0.0.0.0') then
            begin   // (4°1°1) ping NEGATIVE - wrong IP
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; network name [' +
                  tmp_param2 + '] not resolved!');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG('0 Event: [' + trEvent.event_name +
                    ']; network name [' + tmp_param2 + '] not resolved!');
                end;
              end;
              if event_report_type = '1/4' then // first n errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG('0 Event: [' + trEvent.event_name +
                    ']; network name [' + tmp_param2 + '] not resolved!');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // stat
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' name not resolved: ' + tmp_param2);
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
              Continue;
            end;

            tmp_int1 := pingsend.PingHost(tmp_param2);
            if tmp_int1 = -1 then // no answer
            begin   // (4°1°1) ping NEGATIVE - no answer
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; host [' +
                  tmp_param2 + ']: ping timeout');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + ']: ping timeout');
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + ']: ping timeout');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then  // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' host [' + tmp_param2 + ']: ping timeout');
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
            end
            else
            begin  // (4°1°1) ping POSITIVE
              OperationResult := True;
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; host [' +
                  tmp_param2 + ']; ping ' + IntToStr(tmp_int1) + 'ms');
              end;
              if event_report_type = '1/3' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + ']; ping ' + IntToStr(tmp_int1) + 'ms');
                end;
              end;
              if event_report_type = '1/5' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + ']; ping ' + IntToStr(tmp_int1) + 'ms');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,true);
              end;
              if event_stat_type = '1' then  // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('1 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' host [' + tmp_param2 + ']: ping success');
              end;
              // execution
              DoExecution(true,trEvent);
              // alarm
              DoAlarm(true,trEvent);
            end;
            SyncWriteEventResult(trEvent, OperationResult, now);
          end;
          // -----------------------------------------------------------

          // (4°1°2) is port opened ------------------------------------
          if event_class3 = '2' then
          begin
            OperationResult := False;

            event_report_type :=
              uStrUtils.GetFieldFromString(event_str, ParamLimiter, 4);
            event_alarm_type :=
              uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 1);
            event_stat_type := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 6);
            event_stat_name := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 7);
            // 1 - direct log, 2 - stat. collect.
            tmp_param1 := event_main_param; // ip or network name
            tmp_param3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 8);
            // port
            tmp_param2 := tmp_param1;
            if not synaip.IsIP(tmp_param1) then
            begin
              tbs := blcksock.TBlockSocket.Create;
              tmp_param1 := tbs.ResolveName(tmp_param1);
            end;
            if (not synaip.IsIP(tmp_param1)) or (tmp_param1 = '0.0.0.0') then
            begin  // (4°1°2) is port opened NEGATIVE - wrong IP
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; network name [' +
                  tmp_param2 + '] not resolved!');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; network name [' +
                    tmp_param2 + '] not resolved!');
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; network name [' +
                    tmp_param2 + '] not resolved!');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' name not resolved: ' + tmp_param2);
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
              Continue;
            end;
            tmp_int1 := uNetwork.CheckPortOpened(tmp_param1, tmp_param3);
            if tmp_int1 <> 1 then // no answer
            begin   // (4°1°2) is port opened NEGATIVE - no answer
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; host [' +
                  tmp_param2 + '], port [' + tmp_param3 + ']: closed');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + '], port [' + tmp_param3 + ']: closed');
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + '], port [' + tmp_param3 + ']: closed');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' host [' + tmp_param2 + '], port [' +
                  tmp_param3 + ']: closed');
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
            end
            else
            begin  // (4°1°2) is port opened POSITIVE
              OperationResult := True;

              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; host [' +
                  tmp_param2 + '], port [' + tmp_param3 + ']: open');
              end;
              if event_report_type = '1/3' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + '], port [' + tmp_param3 + ']: open');
                end;
              end;
              if event_report_type = '1/5' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; host [' +
                    tmp_param2 + '], port [' + tmp_param3 + ']: open');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,true);
              end;
              if event_stat_type = '1' then    // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('1 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' host [' + tmp_param2 + '], port [' +
                  tmp_param3 + ']: open');
              end;
              // execution
              DoExecution(true,trEvent);
              // alarm
              DoAlarm(true,trEvent);
            end;
            SyncWriteEventResult(trEvent, OperationResult, now);
          end;
          // ---------------------------------------------

          // (4°1°5) http get any file -------------------
          if event_class3 = '5' then
          begin
            OperationResult := False;

            event_report_type :=
              uStrUtils.GetFieldFromString(event_str, ParamLimiter, 4);
            // 1 - direct log, 2 - stat. collect.
            event_alarm_type :=
              uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 1);
            event_stat_type := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 6);
            event_stat_name := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 7);
            tmp_param1 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 8);
            // valid header

            HTTP := httpsend.THTTPSend.Create;
            tmp_bool1 := False;
            try
              if HTTP.HTTPMethod('GET', event_main_param) then
              begin
                if UPPERCASE(HTTP.Headers[0]) = UPPERCASE(tmp_param1) then
                begin
                  tmp_bool1 := True;
                end;
              end;
            except
            end;
            try
              http.Free;
            except
            end;

            if not tmp_bool1 then  // (4°1°5) http get any file NEGATIVE
            begin
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; page [' +
                  event_main_param + '] not available');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; page [' +
                    event_main_param + '] not available');
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; page [' +
                    event_main_param + '] not available');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' page [' + event_main_param + '] not available');
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
            end
            else
            begin // (4°1°5) http get any file POSITIVE
              OperationResult := True;

              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; page [' +
                  event_main_param + '] available');
              end;
              if event_report_type = '1/3' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; page [' +
                    event_main_param + '] available');
                end;
              end;
              if event_report_type = '1/5' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '1 Event: [' + trEvent.event_name + ']; page [' +
                    event_main_param + '] available');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,true);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('1 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' page [' + event_main_param + '] available');
              end;
              // execution
              DoExecution(true,trEvent);
              // alarm
              DoAlarm(true,trEvent);
            end;
            SyncWriteEventResult(trEvent, OperationResult, now);
          end;

          // (4°1°8) check IMS server -------------------
          if event_class3 = '8' then
          begin
            OperationResult := False;

            event_report_type :=
              uStrUtils.GetFieldFromString(event_str, ParamLimiter, 4);
            event_alarm_type :=
              uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 1);
            event_stat_type := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 6);
            event_stat_name := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 7);
            // 1 - direct log, 2 - stat. collect.
            tmp_param1 := event_main_param; // ip or network name
            tmp_param3 := uStrUtils.GetFieldFromString(event_str, ParamLimiter, 8);
            // port
            tmp_param2 := tmp_param1;
            if not synaip.IsIP(tmp_param1) then
            begin
              tbs := blcksock.TBlockSocket.Create;
              tmp_param1 := tbs.ResolveName(tmp_param1);
            end;
            if (not synaip.IsIP(tmp_param1)) or (tmp_param1 = '0.0.0.0') then
            begin  // (4°1°8) is port opened NEGATIVE - wrong IP
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; network name [' +
                  tmp_param2 + '] not resolved!');
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; network name [' +
                    tmp_param2 + '] not resolved!');
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                    '0 Event: [' + trEvent.event_name + ']; network name [' +
                    tmp_param2 + '] not resolved!');
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' name not resolved: ' + tmp_param2);
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
              Continue;
            end;

            // IMS server check
            tmp_str2:='';
            tmp_bool1:=false;
            SR:=uNetwork.PrepereSocketToConnect(tmp_param1, strtoint(tmp_param3));
            if SR.res<>1 then
            begin
              tmp_str2:='Connection to IMS server at host '+tmp_param1+' port '+tmp_param3+' failed!';
              tmp_bool1:=false;
              SR.S.Free;
            end
            else
            begin
              // test app version (must be identical)
              r:=SendStringViaSocket(SR.S,'app_ver'+GetAppVer(),5000);
              if r<>1 then
              begin
                tmp_str2:='Check version of IMS server failed!';
                tmp_bool1:=false;
                SR.S.CloseSocket;
                SR.S.Free;
              end
              else
              begin
                r_str:=GetStringViaSocket(SR.S,5000);
                if r_str<>'APP VERSION VALID' then
                begin
                  tmp_str2:='Main and reserve server version must be identical!';
                  tmp_bool1:=false;
                  SR.S.CloseSocket;
                  SR.S.Free;
                end
                else
                begin
                  tmp_str2:='IMS server v.'+GetAppVer()+' is running on host '+tmp_param1+' port '+tmp_param3;
                  tmp_bool1:=true;
                  SendStringViaSocket(SR.S,'log_out',5000);
                end;
              end;
            end;

            if not tmp_bool1 then // NEGATIVE
            begin   // (4°1°8) is port opened NEGATIVE - no answer
              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; '+tmp_str2);
              end;
              if event_report_type = '1/2' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; '+tmp_str2);
                end;
              end;
              if event_report_type = '1/4' then // errors only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  false, result_max_count)) then
                begin
                  trWriteReportMSG(
                  '0 Event: [' + trEvent.event_name + ']; '+tmp_str2);
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,false);
              end;
              if event_stat_type = '1' then   // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('0 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' ' +tmp_str2);
              end;
              // execution
              DoExecution(false,trEvent);
              // alarm
              DoAlarm(false,trEvent);
            end
            else
            begin  // (4°1°8) is port opened POSITIVE
              OperationResult := True;

              // report
              found:=false;
              if event_report_type = '1/1' then // full log
              begin
                trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; '+tmp_str2);
              end;
              if event_report_type = '1/3' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trCheckLastResult(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; '+tmp_str2);
                end;
              end;
              if event_report_type = '1/5' then // positive only
              begin
                found:=true;
                result_max_count :=
                  StrToInt(uStrUtils.GetFieldFromString(event_str, ParamLimiter, 5));
                if (trIsResultChanged(ev_report_prefix + trEvent.event_name,
                  true, result_max_count)) then
                begin
                  trWriteReportMSG(
                  '1 Event: [' + trEvent.event_name + ']; '+tmp_str2);
                end;
              end;
              if not found then
              begin
                trSetNewResult(ev_report_prefix + trEvent.event_name,true);
              end;
              if event_stat_type = '1' then    // statistic
              begin
                if event_stat_name = '' then
                begin
                  tmp_str1 := trEvent.event_name;
                end
                else
                begin
                  tmp_str1 := event_stat_name;
                end;
                trWriteReportData('1 ' + IntToStr(length(tmp_str1)) +
                  ' ' + tmp_str1 + ' '+tmp_str2);
              end;
              // execution
              DoExecution(true,trEvent);
              // alarm
              DoAlarm(true,trEvent);
            end;
            SyncWriteEventResult(trEvent, OperationResult, now);
          end;
          // -----------------------------------------------------

        end;
      end;
      // --------------------------------------------------------------
      // ==============================================================
    end;
    setlength(trExecuteEventArr, 0);
    sleep(1000);
  end;
end;

procedure TThreadSchedulerExecuter.ExecuterUpdate;
var
  x: integer;
  pNeedUpdate:boolean;
begin
  cs1.Enter;
  trSudoPwd := uMain.sSudoPwd;
  cs1.Leave;

  cs6.Enter;
  pNeedUpdate:=uMain.NeedExecuterUpdate;
  cs6.Leave;

  if pNeedUpdate then // need execution update
  begin
    cs5.Enter;
    for x := 1 to length(uMain.arrExecuteEventArr) do
    begin
      setlength(trExecuteEventArr, length(trExecuteEventArr) + 1);
      trExecuteEventArr[length(trExecuteEventArr) - 1] :=
        uMain.arrExecuteEventArr[x - 1];
    end;
    setlength(uMain.arrExecuteEventArr, 0);
    cs5.Leave;

    cs6.Enter;
    uMain.NeedExecuterUpdate:=false;
    cs6.Leave;
  end;
end;

procedure TThreadSchedulerExecuter.FindBatchByName;
begin
  cs9.Enter;
  trBatchRes := uBatchExecute.FindBatch(umain.arrBatchData, trBatchName);
  cs9.Leave;
end;

procedure TThreadSchedulerExecuter.FindAlarmTemplateByName;
begin
  cs10.Enter;
  trAlarmTemplateRes := uAlarm.FindAlarm(umain.arrAlarmTemplates, trAlarmTemplateName);
  cs10.Leave;
end;

//procedure TThreadSchedulerExecuter.toLog;
//begin
//  uLog.WriteLogMsg(trLogMsg);
//end;

procedure TThreadSchedulerExecuter.trWriteLog(msg_str: string);
begin
  //trLogMsg := msg_str;
  //Synchronize(@toLog);
  uLog.WriteLogMsg(msg_str);
end;

//procedure TThreadSchedulerExecuter.toReportMSG;
//begin
//  uLog.WriteReportMsg(trLogMsg);
//end;

procedure TThreadSchedulerExecuter.trWriteReportMSG(msg_str: string);
begin
  //trLogMsg := msg_str;
  //Synchronize(@toReportMSG);
  uLog.WriteReportMsg(msg_str);
end;


//procedure TThreadSchedulerExecuter.toReportData;
//begin
//  uLog.WriteReportData(trLogMsg);
//end;

procedure TThreadSchedulerExecuter.trWriteReportData(msg_str: string);
begin
  //trLogMsg := msg_str;
  //Synchronize(@toReportData);
  uLog.WriteReportData(msg_str);
end;

function TThreadSchedulerExecuter.trCheckLastResult(ConstName: string;
  curr_res:boolean; max_count: integer): boolean;
var
  last_str: string;
  last_res_cnt: integer;
  last_res: boolean;
begin
  if max_count = 1 then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '1');
      end
      else
      begin
        WriteConst(ConstName, '0'+ uMain.ParamLimiter + '1');
      end;
    Result := True;
    exit;
  end;

  // if max_count>1
  last_str := ReadConst(ConstName);
  if last_str = '' then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '1');
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + '1');
      end;
    Result := False;
    exit;
  end;

  if uStrUtils.GetFieldFromString(last_str, ParamLimiter, 1)='1' then
    begin
      last_res :=true;
    end
    else
    begin
      last_res :=false;
    end;

  last_res_cnt := StrToInt(uStrUtils.GetFieldFromString(last_str, ParamLimiter, 2));
  if last_res <> curr_res then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '1');
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + '1');
      end;
    Result := False;
    exit;
  end;
  if last_res_cnt + 1 >= max_count then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '0');
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + '0');
      end;
    Result := True;
    exit;
  end
  else
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + IntToStr(last_res_cnt + 1));
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + IntToStr(last_res_cnt + 1));
      end;
    Result := False;
    exit;
  end;
end;


function TThreadSchedulerExecuter.trIsResultChanged(ConstName: string;
  curr_res:boolean; max_count: integer): boolean;
var
  last_str: string;
  last_res_cnt: integer;
  last_res:boolean;
begin
  {if max_count = 1 then
  begin
    WriteConst(ConstName, curr_res + uMain.ParamLimiter + '1');
    Result := True;
    exit;
  end;}

  last_str := ReadConst(ConstName);
  if last_str = '' then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '1');
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + '1');
      end;
    if max_count=1 then
      begin
        Result := true;
      end
      else
      begin
        Result := false;
      end;
    exit;
  end;

  if uStrUtils.GetFieldFromString(last_str, ParamLimiter, 1)='1' then
    begin
      last_res := true;
    end
    else
    begin
      last_res := false;
    end;

  last_res_cnt := StrToInt(uStrUtils.GetFieldFromString(last_str, ParamLimiter, 2));

  // if result changed
  if last_res <> curr_res then
  begin
    if curr_res then
      begin
        WriteConst(ConstName, '1' + uMain.ParamLimiter + '1');
      end
      else
      begin
        WriteConst(ConstName, '0' + uMain.ParamLimiter + '1');
      end;
    if max_count=1 then
      begin
        Result := true;
      end
      else
      begin
        Result := false;
      end;
    exit;
  end;
  // if result not changed
  if ((last_res_cnt + 1) = max_count) then
  begin
    Result := True;
  end
  else
  begin
    Result := False;
  end;
  if last_res_cnt>=999999 then
    begin
      last_res_cnt:=999998;
    end;
  if curr_res then
    begin
      WriteConst(ConstName, '1' + uMain.ParamLimiter + IntToStr(last_res_cnt + 1));
    end
    else
    begin
      WriteConst(ConstName, '0' + uMain.ParamLimiter + IntToStr(last_res_cnt + 1));
    end;
end;


procedure TThreadSchedulerExecuter.trSetNewResult(ConstName:string; curr_res:boolean);
begin
  if curr_res then
    begin
      WriteConst(ConstName, '1' + uMain.ParamLimiter + IntToStr(1));
    end
    else
    begin
      WriteConst(ConstName, '0' + uMain.ParamLimiter + IntToStr(1));
    end;
end;

procedure TThreadSchedulerExecuter.SyncWriteEventResult(event:TSchedulerEvent; event_result: boolean;
      event_dt: tdatetime);
begin
  if uStrUtils.GetFieldFromString(event.event_alarm_str, ParamLimiter, 1)='1' then
  begin
    trEventName := event.event_name;
    trEventResult := event_result;
    trEventDT := event_dt;
    //Synchronize(@trWriteEventResult);
    trWriteEventResult;
  end;
end;

procedure TThreadSchedulerExecuter.trWriteEventResult;
var
  x, l: integer;
  found: boolean;
begin
  cs8.Enter;

  l := Length(uMain.arrEventResultArray);
  found := False;
  for x := 1 to l do
  begin
    if uMain.arrEventResultArray[x - 1].er_name = trEventName then
    begin
      found := True;
      uMain.arrEventResultArray[x - 1].er_result := trEventResult;
      uMain.arrEventResultArray[x - 1].er_datetime := trEventDT;
      Break;
    end;
  end;
  if not found then
  begin
    setlength(uMain.arrEventResultArray, l + 1);
    uMain.arrEventResultArray[l].er_name := trEventName;
    uMain.arrEventResultArray[l].er_result := trEventResult;
    uMain.arrEventResultArray[l].er_datetime := trEventDT;
  end;

  cs8.Leave;
end;

procedure TThreadSchedulerExecuter.DoExecution(Res: boolean; trEvent:uScheduler.TSchedulerEvent);
var
  result_max_count:integer;
  event_execution_str,event_execution_type:string;
  tmp_string_list: TStringList;
  x:integer;
  found:boolean;
begin
  event_execution_str:= trEvent.event_execution_str;
  event_execution_type := uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 1);
  trBatchName := trim(uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 3));

  if event_execution_type = '1/1' then  // always
  begin
    //Synchronize(@FindBatchByName);
    FindBatchByName;
    if trBatchRes.batch_name = '' then
    begin
      trWriteLog('Internal error! Batch not found: ' + trBatchName);
    end
    else
    begin
      trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: batch [' + trBatchName + '] allowed to execution!');
      tmp_string_list := uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
      for x := 1 to tmp_string_list.Count do
      begin
        if tmp_string_list[x - 1] = 'err' then
        begin
          trWriteLog('Internal error! Batch ' + trBatchName +
                     ' decoding error!');
          Break;
        end;
        trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
      end;
      trSetNewResult(ev_execution_prefix + trEvent.event_name, Res);
    end;
    exit;
  end;

  if not res then
  begin
    found:=False;
    if event_execution_type = '1/2' then // errors only
    begin
      found:=True;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 2));
      trBatchName := uStrUtils.GetFieldFromString(event_execution_str,
        ParamLimiter, 3);
      if (trCheckLastResult(ev_execution_prefix + trEvent.event_name,
        false, result_max_count)) then
      begin
        //Synchronize(@FindBatchByName);
        FindBatchByName;
        if trBatchRes.batch_name = '' then
        begin
          trWriteLog('Internal error! Batch not found: ' + trBatchName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
            ']: batch [' + trBatchName + '] allowed to execution!');
          tmp_string_list := uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
          for x := 1 to tmp_string_list.Count do
          begin
            if tmp_string_list[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Batch ' + trBatchName +
                ' decoding error!');
              Break;
            end;
            trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
          end;
        end;
      end;
    end;
    if event_execution_type = '1/4' then // errors only
    begin
      found:=True;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 2));
      trBatchName := uStrUtils.GetFieldFromString(event_execution_str,
        ParamLimiter, 3);
      if (trIsResultChanged(ev_execution_prefix + trEvent.event_name,
        false, result_max_count)) then
      begin
        //Synchronize(@FindBatchByName);
        FindBatchByName;
        if trBatchRes.batch_name = '' then
        begin
          trWriteLog('Internal error! Batch not found: ' + trBatchName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
            ']: batch [' + trBatchName + '] allowed to execution!');
          tmp_string_list := uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
          for x := 1 to tmp_string_list.Count do
          begin
            if tmp_string_list[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Batch ' + trBatchName +
                ' decoding error!');
              Break;
            end;
            trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
          end;
        end;
      end;
    end;
    if not found then
    begin
      trSetNewResult(ev_execution_prefix + trEvent.event_name, Res);
    end;
  end
  else
  begin
    found:=False;
    if event_execution_type = '1/3' then // positive only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 2));
      trBatchName := uStrUtils.GetFieldFromString(event_execution_str,
        ParamLimiter, 3);
      if (trCheckLastResult(ev_execution_prefix + trEvent.event_name,
        true, result_max_count)) then
      begin
        //Synchronize(@FindBatchByName);
        FindBatchByName;
        if trBatchRes.batch_name = '' then
        begin
          trWriteLog('Internal error! Batch not found: ' + trBatchName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
            ']: batch [' + trBatchName + '] allowed to execution!');
          tmp_string_list :=
            uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
          for x := 1 to tmp_string_list.Count do
          begin
            if tmp_string_list[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Batch ' + trBatchName +
                ' decoding error!');
              Break;
            end;
            trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
          end;
        end;
      end;
    end;
    if event_execution_type = '1/5' then // positive only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_execution_str, ParamLimiter, 2));
      trBatchName := uStrUtils.GetFieldFromString(event_execution_str,
        ParamLimiter, 3);
      if (trIsResultChanged(ev_execution_prefix + trEvent.event_name,
        true, result_max_count)) then
      begin
        //Synchronize(@FindBatchByName);
        FindBatchByName;
        if trBatchRes.batch_name = '' then
        begin
          trWriteLog('Internal error! Batch not found: ' + trBatchName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
            ']: batch [' + trBatchName + '] allowed to execution!');
          tmp_string_list := uBatchExecute.ExecuteBatch(trBatchRes, trSudoPwd);
          for x := 1 to tmp_string_list.Count do
          begin
            if tmp_string_list[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Batch ' + trBatchName + ' decoding error!');
              Break;
            end;
            trWriteReportMSG('4 ' + tmp_string_list[x - 1]);
          end;
        end;
      end;
    end;
    if not found then
    begin
      trSetNewResult(ev_execution_prefix + trEvent.event_name, Res);
    end;
  end;
end;

procedure TThreadSchedulerExecuter.DoAlarm(Res: boolean; trEvent:uScheduler.TSchedulerEvent);
var
  result_max_count:integer;
  event_alarm_str,event_alarm_type:string;
  //tmp_string_list: TStringList;
  tmp_alarm_exec_res:TExecuteAlarmTemplateResult;
  x:integer;
  found:boolean;
begin
  event_alarm_str:= trEvent.event_alarm_str;
  event_alarm_type := uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 2);
  trAlarmTemplateName := trim(uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 4));


  if event_alarm_type = '1/1' then  // always
  begin
    //Synchronize(@FindAlarmTemplateByName);
    FindAlarmTemplateByName;
    if trAlarmTemplateRes.alarm_template_name = '' then
    begin
      trWriteLog('Internal error! Alarm template not found: ' + trAlarmTemplateName);
    end
    else
    begin
      trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: alarm template [' + trAlarmTemplateName + '] allowed to execution!');
      tmp_alarm_exec_res := uAlarm.ExecuteAlarmTemplate(trAlarmTemplateRes,trEvent.event_name,trSudoPwd);
      setlength(trarrAddAlarmForIA,Length(tmp_alarm_exec_res.arrAddAlarmForIA));
      for x := 1 to length(tmp_alarm_exec_res.arrAddAlarmForIA) do
      begin
        trarrAddAlarmForIA[x-1]:=tmp_alarm_exec_res.arrAddAlarmForIA[x-1];
      end;
      //Synchronize(@AddAlarmForIA);
      AddAlarmForIA;
      for x := 1 to tmp_alarm_exec_res.arrRes.Count do
      begin
        if tmp_alarm_exec_res.arrRes[x - 1] = 'err' then
        begin
          trWriteLog('Internal error! Alarm template ' + trAlarmTemplateName +
                     ' decoding error!');
          Break;
        end;
        trWriteReportMSG('5 ' + tmp_alarm_exec_res.arrRes[x - 1]);
      end;
      trSetNewResult(ev_alarm_prefix + trEvent.event_name, Res);
    end;
    exit;
  end;

  if not res then
  begin
    found:=false;
    if event_alarm_type = '1/2' then // errors only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 3));
      trAlarmTemplateName := uStrUtils.GetFieldFromString(event_alarm_str,
        ParamLimiter, 4);
      if (trCheckLastResult(ev_alarm_prefix + trEvent.event_name,
        false, result_max_count)) then
      begin
        //Synchronize(@FindAlarmTemplateByName);
        FindAlarmTemplateByName;
        if trAlarmTemplateRes.alarm_template_name = '' then
        begin
          trWriteLog('Internal error! Alarm template not found: ' + trAlarmTemplateName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: alarm template [' + trAlarmTemplateName + '] allowed to execution!');
          tmp_alarm_exec_res := uAlarm.ExecuteAlarmTemplate(trAlarmTemplateRes,trEvent.event_name, trSudoPwd);
          setlength(trarrAddAlarmForIA,Length(tmp_alarm_exec_res.arrAddAlarmForIA));
          for x := 1 to length(tmp_alarm_exec_res.arrAddAlarmForIA) do
          begin
            trarrAddAlarmForIA[x-1]:=tmp_alarm_exec_res.arrAddAlarmForIA[x-1];
          end;
          //Synchronize(@AddAlarmForIA);
          AddAlarmForIA;
          for x := 1 to tmp_alarm_exec_res.arrRes.Count do
          begin
            if tmp_alarm_exec_res.arrRes[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Alarm template ' + trAlarmTemplateName +
                     ' decoding error!');
              Break;
            end;
            trWriteReportMSG('5 ' + tmp_alarm_exec_res.arrRes[x - 1]);
          end;
        end;
      end;
    end;
    if event_alarm_type = '1/4' then // first errors only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 3));
      trAlarmTemplateName := uStrUtils.GetFieldFromString(event_alarm_str,
        ParamLimiter, 4);
      if (trIsResultChanged(ev_alarm_prefix + trEvent.event_name,
        false, result_max_count)) then
      begin
        //Synchronize(@FindAlarmTemplateByName);
        FindAlarmTemplateByName;
        if trAlarmTemplateRes.alarm_template_name = '' then
        begin
          trWriteLog('Internal error! Alarm template not found: ' + trAlarmTemplateName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: alarm template [' + trAlarmTemplateName + '] allowed to execution!');
          tmp_alarm_exec_res := uAlarm.ExecuteAlarmTemplate(trAlarmTemplateRes,trEvent.event_name, trSudoPwd);
          setlength(trarrAddAlarmForIA,Length(tmp_alarm_exec_res.arrAddAlarmForIA));
          for x := 1 to length(tmp_alarm_exec_res.arrAddAlarmForIA) do
          begin
            trarrAddAlarmForIA[x-1]:=tmp_alarm_exec_res.arrAddAlarmForIA[x-1];
          end;
          //Synchronize(@AddAlarmForIA);
          AddAlarmForIA;
          for x := 1 to tmp_alarm_exec_res.arrRes.Count do
          begin
            if tmp_alarm_exec_res.arrRes[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Alarm template ' + trAlarmTemplateName +
                     ' decoding error!');
              Break;
            end;
            trWriteReportMSG('5 ' + tmp_alarm_exec_res.arrRes[x - 1]);
          end;
        end;
      end;
    end;
    if not found then
    begin
      trSetNewResult(ev_alarm_prefix + trEvent.event_name, Res);
    end;
  end
  else
  begin
    found:=false;
    if event_alarm_type = '1/3' then // positive only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 3));
      trAlarmTemplateName := uStrUtils.GetFieldFromString(event_alarm_str,
        ParamLimiter, 4);
      if (trCheckLastResult(ev_alarm_prefix + trEvent.event_name,
        true, result_max_count)) then
      begin
        //Synchronize(@FindAlarmTemplateByName);
        FindAlarmTemplateByName;
        if trAlarmTemplateRes.alarm_template_name = '' then
        begin
          trWriteLog('Internal error! Alarm template not found: ' + trAlarmTemplateName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: alarm template [' + trAlarmTemplateName + '] allowed to execution!');
          tmp_alarm_exec_res := uAlarm.ExecuteAlarmTemplate(trAlarmTemplateRes,trEvent.event_name, trSudoPwd);
          setlength(trarrAddAlarmForIA,Length(tmp_alarm_exec_res.arrAddAlarmForIA));
          for x := 1 to length(tmp_alarm_exec_res.arrAddAlarmForIA) do
          begin
            trarrAddAlarmForIA[x-1]:=tmp_alarm_exec_res.arrAddAlarmForIA[x-1];
          end;
          //Synchronize(@AddAlarmForIA);
          AddAlarmForIA;
          for x := 1 to tmp_alarm_exec_res.arrRes.Count do
          begin
            if tmp_alarm_exec_res.arrRes[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Alarm template ' + trAlarmTemplateName +
                     ' decoding error!');
              Break;
            end;
            trWriteReportMSG('5 ' + tmp_alarm_exec_res.arrRes[x - 1]);
          end;
        end;
      end;
    end;
    if event_alarm_type = '1/5' then // first positive only
    begin
      found:=true;
      result_max_count :=
        StrToInt(uStrUtils.GetFieldFromString(event_alarm_str, ParamLimiter, 3));
      trAlarmTemplateName := uStrUtils.GetFieldFromString(event_alarm_str,
        ParamLimiter, 4);
      if (trIsResultChanged(ev_alarm_prefix + trEvent.event_name,
        true, result_max_count)) then
      begin
        //Synchronize(@FindAlarmTemplateByName);
        FindAlarmTemplateByName;
        if trAlarmTemplateRes.alarm_template_name = '' then
        begin
          trWriteLog('Internal error! Alarm template not found: ' + trAlarmTemplateName);
        end
        else
        begin
          trWriteReportMSG('9 Event [' + trEvent.event_name +
                       ']: alarm template [' + trAlarmTemplateName + '] allowed to execution!');
          tmp_alarm_exec_res := uAlarm.ExecuteAlarmTemplate(trAlarmTemplateRes,trEvent.event_name, trSudoPwd);
          setlength(trarrAddAlarmForIA,Length(tmp_alarm_exec_res.arrAddAlarmForIA));
          for x := 1 to length(tmp_alarm_exec_res.arrAddAlarmForIA) do
          begin
            trarrAddAlarmForIA[x-1]:=tmp_alarm_exec_res.arrAddAlarmForIA[x-1];
          end;
          //Synchronize(@AddAlarmForIA);
          AddAlarmForIA;
          for x := 1 to tmp_alarm_exec_res.arrRes.Count do
          begin
            if tmp_alarm_exec_res.arrRes[x - 1] = 'err' then
            begin
              trWriteLog('Internal error! Alarm template ' + trAlarmTemplateName +
                     ' decoding error!');
              Break;
            end;
            trWriteReportMSG('5 ' + tmp_alarm_exec_res.arrRes[x - 1]);
          end;
        end;
      end;
    end;
    if not found then
    begin
      trSetNewResult(ev_alarm_prefix + trEvent.event_name, Res);
    end;
  end;
end;

procedure TThreadSchedulerExecuter.AddAlarmForIA;
var
  x:integer;
  arr_tmp: array of TAlarmForIA;
begin
  cs16.Enter;

  // clear old records in arrAlarmForIA
  setlength(arr_tmp,Length(arrAlarmForIA));
  for x:=1 to Length(arrAlarmForIA) do
  begin
    arr_tmp[x-1]:=arrAlarmForIA[x-1];
  end;
  setlength(arrAlarmForIA,0);
  for x:=1 to Length(arr_tmp) do
  begin
    if (arr_tmp[x-1].alarm_dt<tdatetime(now-1)) then
      begin
        Continue;
      end;
    setlength(arrAlarmForIA,Length(arrAlarmForIA)+1);
    arrAlarmForIA[Length(arrAlarmForIA)-1]:=arr_tmp[x-1];
  end;

  // copy new records to arrAlarmForIA
  for x:=1 to Length(trarrAddAlarmForIA) do
  begin
    setlength(arrAlarmForIA,length(arrAlarmForIA)+1);
    arrAlarmForIA[length(arrAlarmForIA)-1].alarm_dt:=trarrAddAlarmForIA[x-1];
    arrAlarmForIA[length(arrAlarmForIA)-1].alarm_name:=trCurrThreadEvent.event_name;
  end;

  cs16.Leave;
end;

end.
