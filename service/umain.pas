unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, unetwork, pingsend, uMCListener, uScheduler,
  uSchedulerExecuter, uPath, uOfflineInspector, uBatchExecute,
  uCrypt, uAgentInformationListener, uAlarm, uReserveServiceListener,
  uLog, syncobjs;

const
  ParamLimiter = #176;
  ParamLimiter2 = #177;
  SNDRCVTimeout = 2000;

var
  // settings
  sManagerConsoleListeningPort: integer;
  sAgentCollectorListeningPort: integer;
  sAgentInformationListeningPort: integer;
  sReservServiceListeningPort: integer;
  //sSNDRCVTimeout:integer;
  sSudoPwd: string;
  sMCLogonPwd: string;
  sAgentInformationLogonPwd: string;

  // settings arrays
  arrSchedulerEventsArr: uScheduler.TSchedulerEventArr;
  arrExecuteEventArr: uScheduler.TSchedulerEventArr;
  arrBatchData: uBatchExecute.TBatchArray;
  arrAlarmTemplates: TAlarmTemplateArray;

  // settings update flags
  NeedSchedulerUpdate: boolean;
  NeedExecuterUpdate: boolean;

  // main threads
  arrThreadMCListener: array of TThreadMCListener;
  arrThreadAgentInformationListener: array of TThreadAgentInformationListener;
  arrReserveServiceListener: array of TReserveServiceListener;
  ThreadScheduler: TThreadScheduler;
  ThreadSchedulerExecuter: TThreadSchedulerExecuter;
  ThreadOfflineInspector: TThreadOfflineInspector;

  // event result array
  arrEventResultArray: array of uSchedulerExecuter.TEventResult;

  // alarm array for information agent
  arrAlarmForIA: array of TAlarmForIA;

  // system
  ServerStartTime: tdatetime;

  // server on-line monitoring
  arrOnLineMonitoring: array of uLog.TOnLineMonitoringElement;

  // critical sections
  cs1: TCriticalSection; // main settings
  cs2: TCriticalSection; // logs and report messages
  cs3: TCriticalSection; // report data
  cs4: TCriticalSection; // offline data
  cs5: TCriticalSection; // arrExecuteEventArr
  cs6: TCriticalSection; // NeedExecuterUpdate
  cs7: TCriticalSection; // BuildReport
  cs8: TCriticalSection; // arrEventResultArray
  cs9: TCriticalSection; // arrBatchData
  cs10: TCriticalSection; // arrAlarmTemplates
  cs11: TCriticalSection; // const
  cs12: TCriticalSection; // arrSchedulerEventsArr
  cs13: TCriticalSection; // NeedSchedulerUpdate
  cs14: TCriticalSection; // ServerStartTime
  cs15: TCriticalSection; // arrOnLineMonitoring
  cs16: TCriticalSection; // arrAlarmForIA


procedure StartSequence;
procedure StopSequence;

procedure StartManagerConsoleListener;
procedure StopManagerConsoleListener;

procedure StartAgentInformationListener;
procedure StopAgentInformationListener;

procedure StopReserveServiceListener;
procedure StartReserveServiceListener;

procedure StartScheduler;
procedure StopScheduler;

procedure LoadSettings;
procedure SaveSettings;
procedure LoadSchedulerEvents;
procedure SaveSchedulerEvents;
procedure LoadBatchData;
procedure SaveBatchData;
procedure LoadAlarmTemplates;
procedure SaveAlarmTemplates;

procedure StartOfflineInspector;
procedure StopOfflineInspector;

function GetAppVer: string;

procedure CreateAllCS;
{function GetSetSettings(bSet:boolean;param_name,param:string):string;
function GetSetExecuteEventArr(bSet:boolean;arrSet:TSchedulerEventArr):TSchedulerEventArr;
function GetSetNeedExecuterUpdate(bSet:boolean;param:boolean):boolean; }


implementation

function GetAppVer: string;
begin
  Result := '1.0.0.0 beta';
end;

procedure CreateAllCS;
begin
  cs1 := TCriticalSection.Create;
  cs2 := TCriticalSection.Create;
  cs3 := TCriticalSection.Create;
  cs4 := TCriticalSection.Create;
  cs5 := TCriticalSection.Create;
  cs6 := TCriticalSection.Create;
  cs7 := TCriticalSection.Create;
  cs8 := TCriticalSection.Create;
  cs9 := TCriticalSection.Create;
  cs10 := TCriticalSection.Create;
  cs11 := TCriticalSection.Create;
  cs12 := TCriticalSection.Create;
  cs13 := TCriticalSection.Create;
  cs14 := TCriticalSection.Create;
  cs15 := TCriticalSection.Create;
  cs16 := TCriticalSection.Create;
end;

procedure StartSequence;
begin
  CreateAllCS;

  ServerStartTime := now;
  setlength(arrOnLineMonitoring, 0);

  LoadSettings;
  LoadBatchData;
  LoadAlarmTemplates;
  LoadSchedulerEvents;
  StartManagerConsoleListener;
  StartAgentInformationListener;
  StartReserveServiceListener;
  StartScheduler;
  StartOfflineInspector;
end;

procedure StopSequence;
begin
  StopOfflineInspector;

  StopScheduler;
  StopManagerConsoleListener;
  StopAgentInformationListener;
  StopReserveServiceListener;
  SaveSchedulerEvents;
  SaveBatchData;
  SaveAlarmTemplates;
  SaveSettings;
end;

// == offline inspector functions =============
procedure StartOfflineInspector;
begin
  ThreadOfflineInspector := uOfflineInspector.TThreadOfflineInspector.Create(False);
end;

procedure StopOfflineInspector;
begin
  ThreadOfflineInspector.Terminate;
end;
//=============================================

// === manager console functions ===================
procedure StartManagerConsoleListener;
var
  ip_list: array of string;
  x: integer;
begin
  StopManagerConsoleListener;
  ip_list := unetwork.GetLocalIpList;
  setlength(arrThreadMCListener, length(ip_list));
  for x := 1 to Length(ip_list) do
  begin
    arrThreadMCListener[x - 1] := uMCListener.TThreadMCListener.Create(ip_list[x - 1]);
  end;
end;

procedure StopManagerConsoleListener;
var
  x: integer;
begin
  for x := 1 to Length(arrThreadMCListener) do
  begin
    arrThreadMCListener[x - 1].Terminate;
    arrThreadMCListener[x - 1].WaitFor;
  end;
  SetLength(arrThreadMCListener, 0);
end;
//=============================================

//======== Agent Informaion functions =========
procedure StartAgentInformationListener;
var
  ip_list: array of string;
  x: integer;
begin
  StopAgentInformationListener;
  ip_list := unetwork.GetLocalIpList;
  setlength(arrThreadAgentInformationListener, length(ip_list));
  for x := 1 to Length(ip_list) do
  begin
    arrThreadAgentInformationListener[x - 1] :=
      uAgentInformationListener.TThreadAgentInformationListener.Create(ip_list[x - 1]);
  end;
end;

procedure StopAgentInformationListener;
var
  x: integer;
begin
  for x := 1 to Length(arrThreadAgentInformationListener) do
  begin
    arrThreadAgentInformationListener[x - 1].Terminate;
    arrThreadAgentInformationListener[x - 1].WaitFor;
  end;
  SetLength(arrThreadAgentInformationListener, 0);
end;
// ===========================================


//======== Reserve service functions =========
procedure StartReserveServiceListener;
var
  ip_list: array of string;
  x: integer;
begin
  StopReserveServiceListener;
  ip_list := unetwork.GetLocalIpList;
  setlength(arrReserveServiceListener, length(ip_list));
  for x := 1 to Length(ip_list) do
  begin
    arrReserveServiceListener[x - 1] :=
      uReserveServiceListener.TReserveServiceListener.Create(ip_list[x - 1]);
  end;
end;

procedure StopReserveServiceListener;
var
  x: integer;
begin
  for x := 1 to Length(arrReserveServiceListener) do
  begin
    arrReserveServiceListener[x - 1].Terminate;
    arrReserveServiceListener[x - 1].WaitFor;
  end;
  SetLength(arrReserveServiceListener, 0);
end;
// ===========================================


// == Scheduler functions =====================
procedure StartScheduler;
begin
  cs6.Enter;
  NeedExecuterUpdate := False;
  cs6.Leave;
  cs5.Enter;
  setlength(arrExecuteEventArr, 0);
  cs5.Leave;
  cs8.Enter;
  setlength(arrEventResultArray, 0);
  cs8.Leave;
  cs16.Enter;
  setlength(arrAlarmForIA, 0);
  cs16.Leave;
  ThreadScheduler := uScheduler.TThreadScheduler.Create(False);
  ThreadSchedulerExecuter := uSchedulerExecuter.TThreadSchedulerExecuter.Create(False);
end;

procedure StopScheduler;
begin
  ThreadScheduler.Terminate;
  ThreadSchedulerExecuter.Terminate;
end;
// =============================================



// settings ===================================
procedure LoadSettings;
var
  path: string;
  tf: textfile;
  tmp: string;
begin
  cs1.Enter;

  sManagerConsoleListeningPort := 8100;
  //GetSetSettings(true,'sManagerConsoleListeningPort','8100');
  sAgentCollectorListeningPort := 8102;
  //GetSetSettings(true,'sAgentCollectorListeningPort','8102');
  sAgentInformationListeningPort := 8104;
  //GetSetSettings(true,'sAgentInformationListeningPort','8104');
  sReservServiceListeningPort := 8105;
  //GetSetSettings(true,'sReservServiceListeningPort','8105');
  sSudoPwd := '';//GetSetSettings(true,'sSudoPwd','');
  sMCLogonPwd := '';//GetSetSettings(true,'sMCLogonPwd','');
  sAgentInformationLogonPwd := '';//GetSetSettings(true,'sAgentInformationLogonPwd','');

  path := uPath.GetSettingsFilePath;
  assignfile(tf, path);
  try
    reset(tf);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);

    ReadLn(tf, tmp);
    sManagerConsoleListeningPort := StrToInt(tmp);
    //GetSetSettings(true,'sManagerConsoleListeningPort',tmp);
    ReadLn(tf, tmp);
    sAgentCollectorListeningPort := StrToInt(tmp);
    //GetSetSettings(true,'sAgentCollectorListeningPort',tmp);
    ReadLn(tf, tmp);
    sAgentInformationListeningPort := StrToInt(tmp);
    //GetSetSettings(true,'sAgentInformationListeningPort',tmp);
    ReadLn(tf, tmp);
    sReservServiceListeningPort := StrToInt(tmp);
    //GetSetSettings(true,'sReservServiceListeningPort',tmp);
    ReadLn(tf, tmp);
    sSudoPwd := uCrypt.DecodeString(tmp);
    //GetSetSettings(true,'sSudoPwd',uCrypt.DecodeString(tmp));
    ReadLn(tf, tmp);
    sMCLogonPwd := uCrypt.DecodeString(tmp);
    //GetSetSettings(true,'sMCLogonPwd',uCrypt.DecodeString(tmp));
    ReadLn(tf, tmp);
    sAgentInformationLogonPwd := uCrypt.DecodeString(tmp);
    //GetSetSettings(true,'sAgentInformationLogonPwd',uCrypt.DecodeString(tmp));
  except
    SaveSettings;
  end;
  try
    CloseFile(tf);
  except
  end;

  cs1.Leave;
end;

procedure SaveSettings;
var
  path: string;
  tf: textfile;
begin
  cs1.Enter;

  path := uPath.GetSettingsFilePath;
  assignfile(tf, path);
  try
    rewrite(tf);
    writeln(tf, 'itfx IMS settings file');
    writeln(tf, 'DO NOT MODIFY THIS FILE MANUALLY');
    writeln(tf, 'Use management console instead');
    writeln(tf, '===============================');

    writeln(tf, sManagerConsoleListeningPort);
    writeln(tf, sAgentCollectorListeningPort);
    writeln(tf, sAgentInformationListeningPort);
    writeln(tf, sReservServiceListeningPort);
    writeln(tf, uCrypt.EncodeString(sSudoPwd));
    writeln(tf, uCrypt.EncodeString(sMCLogonPwd));
    writeln(tf, uCrypt.EncodeString(sAgentInformationLogonPwd));
  except
  end;
  try
    CloseFile(tf);
  except
  end;

  cs1.Leave;
end;
// ==============================================

procedure LoadSchedulerEvents;
var
  path: string;
  tf: textfile;
  tmp: string;
begin
  cs12.Enter;

  SetLength(arrSchedulerEventsArr, 0);
  path := uPath.GetSchedulerListFilePath;
  assignfile(tf, path);
  try
    reset(tf);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    while not EOF(tf) do
    begin
      SetLength(arrSchedulerEventsArr, length(arrSchedulerEventsArr) + 1);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].event_name := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].event_str := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].event_main_param := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_days_of_month := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_days_of_week := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_repeat_interval :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_repeat_type :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_time_h :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_time_m :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_time_s :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_end_time_h :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_end_time_m :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].ev_end_time_s :=
        StrToInt(tmp);
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) - 1].event_alarm_str := tmp;
      readln(tf, tmp);
      arrSchedulerEventsArr[length(arrSchedulerEventsArr) -
        1].event_execution_str := tmp;
    end;
  except
    SetLength(arrSchedulerEventsArr, 0);
    SaveSchedulerEvents;
  end;
  try
    CloseFile(tf);
  except
  end;
  cs12.Leave;

  cs13.Enter;
  NeedSchedulerUpdate := True;
  cs13.Leave;
end;

procedure SaveSchedulerEvents;
var
  x: integer;
  path: string;
  tf: textfile;
  tmp: string;
begin
  cs12.Enter;

  path := uPath.GetSchedulerListFilePath;
  assignfile(tf, path);
  try
    rewrite(tf);
    writeln(tf, 'itfx IMS scheduler data file');
    writeln(tf, 'DO NOT MODIFY THIS FILE MANUALLY');
    writeln(tf, 'Use management console instead');
    writeln(tf, '===============================');
    for x := 1 to Length(arrSchedulerEventsArr) do
    begin
      tmp := arrSchedulerEventsArr[x - 1].event_name;
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].event_str;
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].event_main_param;
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].ev_days_of_month;
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].ev_days_of_week;
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_repeat_interval);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_repeat_type);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_time_h);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_time_m);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_time_s);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_end_time_h);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_end_time_m);
      writeln(tf, tmp);
      tmp := IntToStr(arrSchedulerEventsArr[x - 1].ev_end_time_s);
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].event_alarm_str;
      writeln(tf, tmp);
      tmp := arrSchedulerEventsArr[x - 1].event_execution_str;
      writeln(tf, tmp);
    end;
  except
  end;
  try
    CloseFile(tf);
  except
  end;

  cs12.Leave;
end;
//==========================================

procedure SaveBatchData;
var
  path: string;
  tf: textfile;
  tmp: string;
  x: integer;
begin
  cs9.Enter;

  path := uPath.GetBatchDataFilePath;
  assignfile(tf, path);
  try
    rewrite(tf);
    writeln(tf, 'itfx IMS batch data file');
    writeln(tf, 'DO NOT MODIFY THIS FILE MANUALLY');
    writeln(tf, 'Use management console instead');
    writeln(tf, '===============================');
    for x := 1 to Length(arrBatchData) do
    begin
      tmp := arrBatchData[x - 1].batch_name;
      writeln(tf, tmp);
      tmp := arrBatchData[x - 1].batch_str;
      writeln(tf, tmp);
      tmp := arrBatchData[x - 1].batch_params;
      writeln(tf, tmp);
    end;
  except
  end;
  try
    CloseFile(tf);
  except
  end;

  cs9.Leave;
end;

procedure LoadBatchData;
var
  path: string;
  tf: textfile;
  tmp: string;
begin
  cs9.Enter;

  SetLength(arrBatchData, 0);
  path := uPath.GetBatchDataFilePath;
  assignfile(tf, path);
  try
    reset(tf);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    while not EOF(tf) do
    begin
      SetLength(arrBatchData, length(arrBatchData) + 1);
      readln(tf, tmp);
      arrBatchData[length(arrBatchData) - 1].batch_name := tmp;
      readln(tf, tmp);
      arrBatchData[length(arrBatchData) - 1].batch_str := tmp;
      readln(tf, tmp);
      arrBatchData[length(arrBatchData) - 1].batch_params := tmp;
    end;
  except
    SetLength(arrBatchData, 0);
    SaveBatchData;
  end;
  try
    CloseFile(tf);
  except
  end;

  cs9.Leave;
end;


// ============================================

procedure LoadAlarmTemplates;
var
  path: string;
  tf: textfile;
  tmp: string;
begin
  cs10.Enter;

  SetLength(arrAlarmTemplates, 0);
  path := uPath.GetAlarmDataFilePath;
  assignfile(tf, path);
  try
    reset(tf);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    readln(tf, tmp);
    while not EOF(tf) do
    begin
      SetLength(arrAlarmTemplates, length(arrAlarmTemplates) + 1);
      readln(tf, tmp);
      arrAlarmTemplates[length(arrAlarmTemplates) - 1].alarm_template_name := tmp;
      readln(tf, tmp);
      arrAlarmTemplates[length(arrAlarmTemplates) - 1].alarm_template_str := tmp;
      readln(tf, tmp);
      arrAlarmTemplates[length(arrAlarmTemplates) - 1].alarm_template_params := tmp;
    end;
  except
    SetLength(arrAlarmTemplates, 0);
    SaveBatchData;
  end;
  try
    CloseFile(tf);
  except
  end;

  cs10.Leave;
end;

procedure SaveAlarmTemplates;
var
  path: string;
  tf: textfile;
  tmp: string;
  x: integer;
begin
  cs10.Enter;

  path := uPath.GetAlarmDataFilePath;
  assignfile(tf, path);
  try
    rewrite(tf);
    writeln(tf, 'itfx IMS alarm data file');
    writeln(tf, 'DO NOT MODIFY THIS FILE MANUALLY');
    writeln(tf, 'Use management console instead');
    writeln(tf, '===============================');
    for x := 1 to Length(arrAlarmTemplates) do
    begin
      tmp := arrAlarmTemplates[x - 1].alarm_template_name;
      writeln(tf, tmp);
      tmp := arrAlarmTemplates[x - 1].alarm_template_str;
      writeln(tf, tmp);
      tmp := arrAlarmTemplates[x - 1].alarm_template_params;
      writeln(tf, tmp);
    end;
  except
  end;
  try
    CloseFile(tf);
  except
  end;

  cs10.Leave;
end;



end.
