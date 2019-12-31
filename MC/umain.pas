unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, Grids, StdCtrls, ComCtrls, Buttons, uLogin, uNetwork, blcksock,
  uCrypt, uServerSettings, uSchEditor, uStrUtils, uCustomTypes, uBchEditor,
  uAlarmTemplateEditor, uReportSettings, Windows, uRTM, uSaveRestorePositionAndSize;

type
  TThreadMsgReader = class(TThread)
  private
    { Private declarations }
    trS:TTCPBlockSocket;
    trMsg:string;
    trUptimeStr:string;
    trExitParam:integer;
    trSocketBusy:boolean;

    procedure trAddMsg;
    procedure trThreadExit;
    procedure trGetBusy;
    procedure trSetBusy;
    procedure trSetUptime;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(S: TTCPBlockSocket);
  end;

  TThreadRTMReader = class(TThread)
  private
    { Private declarations }
    trS:TTCPBlockSocket;
    trMsg:string;
    trType:string;
    trRTMStatus:string;
    trCurrStateActiv:boolean;
    trExitParam:integer;
    trSocketBusy:boolean;

    procedure trAddMsg;
    procedure trSetStatus;
    procedure trThreadExit;
    procedure trGetBusy;
    procedure trSetBusy;
    procedure trGetCurrStateActive;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(S: TTCPBlockSocket);
  end;

  { TfMain }
  TfMain = class(TForm)
    MenuItem3: TMenuItem;
    sbRTM: TSpeedButton;
    sbTasks: TSpeedButton;
    sbBatches: TSpeedButton;
    sbAlarmTemplates: TSpeedButton;
    sbReport: TSpeedButton;
    syslabel5: TLabel;
    syslabel4: TLabel;
    syslabel3: TLabel;
    syslabel2: TLabel;
    syslabel1: TLabel;
    lbMessages: TListBox;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    miAlarmTemplatesEditor: TMenuItem;
    miBatchEdit: TMenuItem;
    miSchEdit: TMenuItem;
    miServerSettings: TMenuItem;
    migOptions: TMenuItem;
    miExit: TMenuItem;
    mmMain: TMainMenu;
    sbMain: TStatusBar;
    tClose: TTimer;
    tThreadWatcher: TTimer;
    tSocketWait: TTimer;
    tStart: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure miAlarmTemplatesEditorClick(Sender: TObject);
    procedure miBatchEditClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miSchEditClick(Sender: TObject);
    procedure miServerSettingsClick(Sender: TObject);
    procedure sbAlarmTemplatesClick(Sender: TObject);
    procedure sbBatchesClick(Sender: TObject);
    procedure sbReportClick(Sender: TObject);
    procedure sbRTMClick(Sender: TObject);
    procedure sbTasksClick(Sender: TObject);
    procedure tCloseTimer(Sender: TObject);
    procedure tSocketWaitTimer(Sender: TObject);
    procedure tStartTimer(Sender: TObject);
    procedure tThreadWatcherTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMain: TfMain;
  lp:TLoginParams;
  S:TTCPBlockSocket;
  vSocketBusy:boolean;
  vOpWaiting:integer;
  ThreadMsgReader:TThreadMsgReader;
  ThreadRTMReader:TThreadRTMReader;
  ThreadFinished:integer;
  ThreadRTMFinished:integer;

  // settings
  ssManagerConsoleListeningPort:integer;
  ssAgentCollectorListeningPort:integer;
  ssAgentInformationListeningPort:integer;
  ssReservServiceListeningPort:integer;
  ssSudoPwd:string;
  ssMCLogonPwd:string;
  ssAILogonPwd:string;

  sServerOSVer:string;

  arrServerSch:array of TSchedulerEvent;
  arrServerBatchList:array of TBatch;
  arrServerAlarmList:array of TAlarmTemplate;

  report_set:string;
  report_dt_begin:TDateTime;
  report_dt_end:TDateTime;
  report_res_file:String;


function LoginToServer(server,password:string;port:integer):TLoginResult;
function GetAppVer:string;

procedure GetServerSettings;
procedure SetServerSettings;

procedure GetServerSch;
procedure SetServerSch;
procedure GetServerBatches;
procedure SetServerBatches;
procedure GetServerAlarmList;
procedure SetServerAlarmList;

// network procedures
function CheckEcho:boolean;
function CheckServerConnection:boolean;
procedure DisconnectSeq;
procedure OpDisconnectSeq;

function ServerGetPrm(prm:string):String;
procedure ServerSetParam(prm,vl:string);

procedure ReportRequest;
procedure GenerateReport();


// interface
procedure AddMsg(m:string);

procedure SetStatus(m:string);
procedure WaitSocketForOp(OpIndex:integer);
procedure RunOp(OpIndex:integer);


implementation

{$R *.lfm}

{ TfMain }

procedure TThreadMsgReader.trSetUptime;
begin
  fMain.syslabel4.Caption:='IMS server uptime: '+trUptimeStr+' day(s)';
end;

constructor TThreadMsgReader.Create(S: TTCPBlockSocket);
begin
  inherited create(false);
  FreeOnTerminate := true;
  trS := S;
end;

constructor TThreadRTMReader.Create(S: TTCPBlockSocket);
begin
  inherited create(false);
  FreeOnTerminate := true;
  trS := S;
end;

procedure TThreadMsgReader.trAddMsg;
begin
  AddMsg(trMsg);
end;

procedure TThreadRTMReader.trAddMsg;
begin
  uRTM.AddRTMMsg(trMsg,trType);
end;

procedure TThreadRTMReader.trSetStatus;
begin
  uRTM.SetRTMStatus(trRTMStatus);
end;

procedure TThreadMsgReader.trThreadExit;
begin
  ThreadFinished:=trExitParam;
end;

procedure TThreadRTMReader.trThreadExit;
begin
  ThreadRTMFinished:=trExitParam;
end;

procedure TThreadMsgReader.trSetBusy;
begin
  vSocketBusy:=trSocketBusy;
end;

procedure TThreadRTMReader.trSetBusy;
begin
  vSocketBusy:=trSocketBusy;
end;

procedure TThreadMsgReader.trGetBusy;
begin
  trSocketBusy:=vSocketBusy;
end;

procedure TThreadRTMReader.trGetBusy;
begin
  trSocketBusy:=vSocketBusy;
end;

procedure TThreadRTMReader.trGetCurrStateActive;
begin
  trCurrStateActiv:=uRTM.fRTM.Visible;
end;

procedure TThreadMsgReader.Execute;
var
  r:integer;
  r_str:string;
  cnt:integer;
  x:integer;
  uptime_sec_str:string;
begin
  while not Terminated do
  begin
    Synchronize(@trGetBusy);
    if trSocketBusy then
      begin
        for x:=1 to 50 do
        begin
          if Terminated then
            begin
              trExitParam:=1;
              Synchronize(@trThreadExit);
              exit;
            end;
          Sleep(100);
        end;
        Continue;
      end;
    trSocketBusy:=true;
    Synchronize(@trSetBusy);


    // reading messages ====================================
    r:=SendStringViaSocket(trS,'read_msg',5000);
    if r<>1 then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    r_str:=GetStringViaSocket(trS,5000);
    if leftstr(r_str,7)<>'msg_cnt' then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    cnt:=strtoint(rightstr(r_str,length(r_str)-7));
    for x:=1 to cnt do
      begin
        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,7)<>'msg_str' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
         trMsg:=rightstr(r_str,length(r_str)-7);
         Synchronize(@trAddMsg);
      end;
    // ================================================


    // reading uptime =================================
    r:=SendStringViaSocket(trS,'get_uptime',5000);
    if r<>1 then
      begin
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    r_str:=GetStringViaSocket(trS,5000);
    if leftstr(r_str,6)<>'uptime' then
      begin
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    uptime_sec_str:=rightstr(r_str,length(r_str)-6);
    trUptimeStr:=inttostr(trunc(strtoint(uptime_sec_str)/(3600*24)));
    Synchronize(@trSetUptime);
    // ================================================

    trSocketBusy:=false;
    Synchronize(@trSetBusy);

    for x:=1 to 50 do
      begin
        if Terminated then
          begin
            trExitParam:=1;
            Synchronize(@trThreadExit);
            exit;
          end;
        Sleep(100);
      end;
  end;
  trExitParam:=1;
  Synchronize(@trThreadExit);
end;


procedure TThreadRTMReader.Execute;
var
  r:integer;
  r_str:string;
  cnt:integer;
  x:integer;
  prev_state_activ:boolean;
begin
  prev_state_activ:=false;
  while not Terminated do
  begin
    Synchronize(@trGetBusy);
    if trSocketBusy then
      begin
        for x:=1 to 50 do
        begin
          if Terminated then
            begin
              trExitParam:=1;
              Synchronize(@trThreadExit);
              exit;
            end;
          Sleep(100);
        end;
        Continue;
      end;
    trSocketBusy:=true;
    Synchronize(@trSetBusy);

    // check if prev_state_activ changed
    Synchronize(@trGetCurrStateActive);
    if not trCurrStateActiv then
      begin
        prev_state_activ:=false;
        trSocketBusy:=false;
        Synchronize(@trSetBusy);
        for x:=1 to 50 do
        begin
          if Terminated then
            begin
              trExitParam:=1;
              Synchronize(@trThreadExit);
              exit;
            end;
          Sleep(100);
        end;
        Continue;
      end;

    // sending init command if state changed
    if prev_state_activ<>trCurrStateActiv then
      begin
        r:=SendStringViaSocket(trS,'set_rtm_time',5000);
        if r<>1 then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,11)<>'rtm_time_ok' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
      end;
    prev_state_activ:=true;

    // reading messages ====================================
    r:=SendStringViaSocket(trS,'read_rtm',5000);
    if r<>1 then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    r_str:=GetStringViaSocket(trS,5000);
    if leftstr(r_str,7)<>'rtm_cnt' then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    cnt:=strtoint(rightstr(r_str,length(r_str)-7));
    for x:=1 to cnt do
      begin
        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,7)<>'rtm_str' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
        trMsg:=rightstr(r_str,length(r_str)-7);

        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,7)<>'rtm_typ' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
         trType:=rightstr(r_str,length(r_str)-7);
         Synchronize(@trAddMsg);
      end;
    trRTMStatus:='Last update: '+DateTimeToStr(Now);
    Synchronize(@trSetStatus);
    // ================================================

    trSocketBusy:=false;
    Synchronize(@trSetBusy);

    for x:=1 to 50 do
      begin
        if Terminated then
          begin
            trExitParam:=1;
            Synchronize(@trThreadExit);
            exit;
          end;
        Sleep(100);
      end;
  end;
  trExitParam:=1;
  Synchronize(@trThreadExit);
end;

procedure WaitSocketForOp(OpIndex:integer);
begin
 if not vSocketBusy then
   begin
     RunOp(OpIndex);
   end
   else
   begin
     vOpWaiting:=OpIndex;
     fMain.tSocketWait.Enabled:=true;
   end;
end;

procedure AddMsg(m:string);
begin
  fMain.lbMessages.Items.Add(m);
  fMain.lbMessages.ItemIndex:=fMain.lbMessages.Items.Count-1;
  Application.ProcessMessages;
end;

procedure SetStatus(m:string);
begin
  fMain.sbMain.SimpleText:=m;
  Application.ProcessMessages;
end;

function GetAppVer:string;
begin
  result:='1.0.0.0 beta';
end;

procedure TfMain.miExitClick(Sender: TObject);
begin
  fMain.Close;
end;

procedure TfMain.miSchEditClick(Sender: TObject);
begin
  WaitSocketForOp(3);
end;

procedure TfMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if tClose.Tag=0 then
    begin
      CloseAction:=caNone;
      SetStatus('Disconnecting...');
      ThreadMsgReader.Terminate;
      ThreadRTMReader.Terminate;
      tClose.Enabled:=true;
    end
    else
    begin
      CloseAction:=caFree;
    end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin

end;

procedure TfMain.MenuItem2Click(Sender: TObject);
begin
  ReportRequest;
end;

procedure TfMain.MenuItem3Click(Sender: TObject);
begin
  sbRTM.Click;
end;

procedure TfMain.miAlarmTemplatesEditorClick(Sender: TObject);
begin
  WaitSocketForOp(8);
end;

procedure TfMain.miBatchEditClick(Sender: TObject);
begin
  WaitSocketForOp(4);
end;

procedure TfMain.miServerSettingsClick(Sender: TObject);
begin
  WaitSocketForOp(1);
end;

procedure TfMain.sbAlarmTemplatesClick(Sender: TObject);
begin
  WaitSocketForOp(8);
end;

procedure TfMain.sbBatchesClick(Sender: TObject);
begin
  WaitSocketForOp(4);
end;


procedure TfMain.sbReportClick(Sender: TObject);
begin
  ReportRequest;
end;

procedure TfMain.sbRTMClick(Sender: TObject);
begin
 if uRTM.fRTM.Visible then
   begin
     uRTM.fRTM.SetFocus;
   end
   else
   begin
     uRTM.fRTM.Visible:=true;
   end;
end;

procedure TfMain.sbTasksClick(Sender: TObject);
begin
  WaitSocketForOp(3);
end;

procedure TfMain.tCloseTimer(Sender: TObject);
begin
  if lp.lp_valid then
    begin
      if ThreadFinished=0 then
        begin
          exit;
        end;
      if ThreadRTMFinished=0 then
        begin
          exit;
        end;
    end;

  tClose.Enabled:=false;

  try
    if lp.lp_valid then
      begin
        SendStringViaSocket(S,'log_out',2000);
      end;
  except
  end;
  try
    if lp.lp_valid then
      begin
        S.CloseSocket;
      end;
  except
  end;
  try
    if lp.lp_valid then
      begin
        S.Free;
      end;
  except
  end;

  uSaveRestorePositionAndSize.SavePositionAndSize('main',fMain);
  tClose.Tag:=1;
  fMain.Close;
end;


procedure TfMain.tSocketWaitTimer(Sender: TObject);
begin
  if vSocketBusy then
    begin
      exit;
    end;
  tSocketWait.Enabled:=false;
  RunOp(vOpWaiting);
end;


procedure RunOp(OpIndex:integer);
begin
 if OpIndex=1 then // read server settings and start dialog
   begin
     GetServerSettings;
     uServerSettings.RunServerSettings;
     exit;
   end;
 if OpIndex=2 then // write server settings
   begin
     uMain.SetServerSettings;
     exit;
   end;

 if OpIndex=3 then // read server shedule
   begin
     uMain.GetServerSch;
     uMain.GetServerBatches;
     uMain.GetServerAlarmList;
     uSchEditor.StartSchEdit;
     exit;
   end;
 if OpIndex=4 then // read server batches
   begin
     uMain.GetServerSch;
     uMain.GetServerBatches;
     uBchEditor.StartBchEdit;
     exit;
   end;

 if OpIndex=5 then // write server batches
   begin
     SetServerBatches;
     exit;
   end;
 if OpIndex=6 then // write server schedule (batches and alarm list also)
   begin
     SetServerBatches;
     SetServerAlarmList;
     SetServerSch;
     exit;
   end;

 if OpIndex=7 then // write server alarm list
   begin
     SetServerAlarmList;
     exit;
   end;

 if OpIndex=8 then // read server alarm list
   begin
     uMain.GetServerSch;
     uMain.GetServerAlarmList;
     uAlarmTemplateEditor.StartAlarmTemplateEdit;
     exit;
   end;

 if OpIndex=9 then // request report
   begin
     uMain.GenerateReport;
     exit;
   end;
end;

procedure TfMain.tStartTimer(Sender: TObject);
var
  LR:TLoginResult;
  valid:boolean;
begin
  tStart.Enabled:=false;
  uSaveRestorePositionAndSize.RestorePositionAndSize('main',fMain);

  fMain.syslabel1.Caption:='IMS management console v.'+GetAppVer;

  lp.lp_port:=8100;
  lp.lp_server:='';
  lp.lp_password:='';
  lp.lp_remember:=false;
  lp.lp_valid:=false;
  valid:=false;
  while not valid do
    begin
      lp:=uLogin.GetLoginParams(lp);
      if not lp.lp_valid then
        begin
          fMain.Close;
          exit;
        end;
      LR:=LoginToServer(lp.lp_server,lp.lp_password,lp.lp_port);
      if LR.res=1 then
        begin
          valid:=true;
          S:=LR.S;
        end
        else
        begin
          SetStatus('Not connected. Retrying...');
          showmessage(LR.res_msg);
          valid:=false;
        end;
    end;



  // on connection seq
  tClose.Tag:=0;
  ThreadFinished:=0;
  ThreadMsgReader:=TThreadMsgReader.Create(S);
  ThreadRTMFinished:=0;
  ThreadRTMReader:=TThreadRTMReader.Create(S);
  tThreadWatcher.Enabled:=true;

  uSchEditor.IsSchEditorRuning:=false;

  AddMsg('Connected to itfx IMS server!');
  fMain.syslabel2.Caption:='Connected to IMS server at '+lp.lp_server+':'+inttostr(lp.lp_port);
  if sServerOSVer='LIN' then
    begin
      fMain.syslabel3.Caption:='Server host OS type: Linux\UNIX';
    end
    else
    begin
      fMain.syslabel3.Caption:='Server host OS type: MS Windows';
    end;
  SetStatus('Ready.');
end;

procedure TfMain.tThreadWatcherTimer(Sender: TObject);
begin
  if ThreadFinished=1 then
    begin
      DisconnectSeq;
      fMain.tThreadWatcher.Enabled:=false;
    end;
  if ThreadFinished=2 then
    begin
      fMain.tThreadWatcher.Enabled:=false;
      OpDisconnectSeq;
    end;
  if ThreadRTMFinished=1 then
    begin
      DisconnectSeq;
      fMain.tThreadWatcher.Enabled:=false;
    end;
  if ThreadRTMFinished=2 then
    begin
      fMain.tThreadWatcher.Enabled:=false;
      OpDisconnectSeq;
    end;
end;



procedure GetServerSettings;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      try
        SetStatus('Reading server settings...');
        ssManagerConsoleListeningPort:=strtoint(ServerGetPrm('ManagerConsoleListeningPort'));
        ssAgentCollectorListeningPort:=strtoint(ServerGetPrm('AgentCollectorListeningPort'));
        ssAgentInformationListeningPort:=strtoint(ServerGetPrm('AgentInformationListeningPort'));
        ssReservServiceListeningPort:=strtoint(ServerGetPrm('ReservServiceListeningPort'));
        ssSudoPwd:=uCrypt.DecodeString(ServerGetPrm('SudoPwd'));
        ssMCLogonPwd:=uCrypt.DecodeString(ServerGetPrm('MCLogonPwd'));
        ssAILogonPwd:=uCrypt.DecodeString(ServerGetPrm('AILogonPwd'));
        SetStatus('Ready.');
      except
        AddMsg('Error reading server settings!');
        SetStatus('Ready.');
      end;
    end;
  vSocketBusy:=false;
end;

procedure SetServerSettings;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      //try
        SetStatus('Saving server settings...');
        ServerSetParam('ManagerConsoleListeningPort',inttostr(ssManagerConsoleListeningPort));
        ServerSetParam('AgentCollectorListeningPort',inttostr(ssAgentCollectorListeningPort));
        ServerSetParam('AgentInformationListeningPort',inttostr(ssAgentInformationListeningPort));
        ServerSetParam('ReservServiceListeningPort',inttostr(ssReservServiceListeningPort));
        ServerSetParam('SudoPwd',uCrypt.EncodeString(ssSudoPwd));
        ServerSetParam('MCLogonPwd',uCrypt.EncodeString(ssMCLogonPwd));
        ServerSetParam('AILogonPwd',uCrypt.EncodeString(ssAILogonPwd));
        SetStatus('Ready.');
      //except

      //end;
    end;
  vSocketBusy:=false;
end;

function ServerGetPrm(prm:string):String;
var
  r:integer;
  r_str:string;
begin
  r:=SendStringViaSocket(S,'get_prm'+prm,5000);
  if r<>1 then
    begin
      OpDisconnectSeq;
      exit;
    end;
  r_str:=GetStringViaSocket(S,5000);
  if leftstr(r_str,7)<>'res_prm' then
    begin
      OpDisconnectSeq;
      exit;
    end;
  result:=rightstr(r_str,length(r_str)-7);
end;

procedure ServerSetParam(prm,vl:string);
var
  r:integer;
  r_str:string;
begin
  r:=SendStringViaSocket(S,'set_prm'+prm+ParamLimiter+vl,5000);
  if r<>1 then
    begin
      OpDisconnectSeq;
      exit;
    end;
  r_str:=GetStringViaSocket(S,5000);
  if leftstr(r_str,7)<>'res_suc' then
    begin
      OpDisconnectSeq;
      exit;
    end;
end;

function CheckServerConnection:boolean;
begin
  result:=true;
  if not CheckEcho then
    begin
      Result:=false;
    end;
  if not Result then
    begin
      OpDisconnectSeq;
    end;
end;

function CheckEcho:boolean;
var
  r:integer;
  r_str:string;
begin
  result:=true;
  r:=SendStringViaSocket(S,'echo',5000);
  if r<>1 then
    begin
      result:=false;
      exit;
    end;
  r_str:=GetStringViaSocket(S,5000);
  if r_str<>'echo_answer' then
    begin
      result:=false;
      exit;
    end;
end;

function LoginToServer(server,password:string;port:integer):TLoginResult;
var
  SR:TSocketResult;
  r:integer;
  r_str:string;
begin
  vSocketBusy:=true;
  SR:=uNetwork.PrepereSocketToConnect(server,port);
  if SR.res<>1 then
    begin
      result.res_msg:='Connection to host '+server+' port '+inttostr(port)+' failed!';
      result.res:=-1;
      SR.S.Free;
      exit;
    end;
  // test app version (must be identical)
  SetStatus('Reading server version...');
  r:=SendStringViaSocket(SR.S,'app_ver'+GetAppVer(),5000);
  if r<>1 then
    begin
      result.res_msg:='Connection error!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;
  r_str:=GetStringViaSocket(SR.S,5000);
  if r_str<>'APP VERSION VALID' then
    begin
      result.res_msg:='IMS server and console version must be identical!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;

  // check password
  SetStatus('Sending password...');
  r:=SendStringViaSocket(SR.S,'log_in_mc'+uCrypt.EncodeString(password),5000);
  if r<>1 then
    begin
      result.res_msg:='Connection error!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;
  r_str:=GetStringViaSocket(SR.S,5000);
  if r_str<>'LOGON SUCCESS' then
    begin
      result.res_msg:='Invalid password!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;

  SetStatus('Reading server os type...');
  r:=SendStringViaSocket(SR.S,'os_ver',5000);
  if r<>1 then
    begin
      result.res_msg:='Connection error!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;
  r_str:=GetStringViaSocket(SR.S,5000);
  if r_str='' then
    begin
      result.res_msg:='Communication error!';
      result.res:=-1;
      SR.S.CloseSocket;
      SR.S.Free;
      exit;
    end;
  sServerOSVer:=r_str;

  result.res_msg:='LOGIN SUCCESS';
  result.res:=1;
  result.S:=SR.S;

  vSocketBusy:=false;
  SetStatus('Ready.');
end;


procedure GetServerSch;
var
  r:integer;
  r_str:string;
  x,sch_cnt:integer;
  tmp_str:string;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Reading server schedule list...');
      r:=SendStringViaSocket(S,'read_sch',5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'sch_cnt' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      try
        sch_cnt:=strtoint(rightstr(r_str,length(r_str)-7));
      except
        OpDisconnectSeq;
        exit;
      end;
      setlength(arrServerSch,sch_cnt);
      try
        for x:=1 to sch_cnt do
          begin
            SetStatus('Reading server schedule event '+inttostr(x)+'...');

            //ev_days_of_month: string; // 1,2,5,10,24,31
            //ev_days_of_week: string;  // 1,2,5
            //ev_repeat_type: integer; // 1-once per day, 2-every X seconds
            //ev_repeat_interval: integer; // X seconds
            //ev_time_h: word;
            //ev_time_m: word;
            //ev_time_s: word;
            //ev_end_time_h: word;
            //ev_end_time_m: word;
            //ev_end_time_s: word; - all in one string with delimiter
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm1' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerSch[x-1].ev_days_of_month:=uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,1);
            arrServerSch[x-1].ev_days_of_week:=uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,2);
            arrServerSch[x-1].ev_repeat_type:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,3));
            arrServerSch[x-1].ev_repeat_interval:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,4));
            arrServerSch[x-1].ev_time_h:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,5));
            arrServerSch[x-1].ev_time_m:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,6));
            arrServerSch[x-1].ev_time_s:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,7));
            arrServerSch[x-1].ev_end_time_h:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,8));
            arrServerSch[x-1].ev_end_time_m:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,9));
            arrServerSch[x-1].ev_end_time_s:=strtoint(uStrUtils.GetFieldFromString(tmp_str,ParamLimiter,10));

            //event_name: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm2' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            arrServerSch[x-1].event_name:=rightstr(r_str,length(r_str)-8);

            //event_str: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm3' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            arrServerSch[x-1].event_str:=rightstr(r_str,length(r_str)-8);

            //event_main_param: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm4' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            arrServerSch[x-1].event_main_param:=rightstr(r_str,length(r_str)-8);

            //event_alarm_str: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm5' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            arrServerSch[x-1].event_alarm_str:=rightstr(r_str,length(r_str)-8);

            //event_execution_str: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'sch_prm6' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            arrServerSch[x-1].event_execution_str:=rightstr(r_str,length(r_str)-8);
          end;
        SetStatus('Ready.');
      except
        SetLength(arrServerSch,0);
        AddMsg('Error reading server schedule!');
        SetStatus('Ready.');
      end;
    end;
  vSocketBusy:=false;
end;

procedure SetServerSch;
var
  r:integer;
  r_str:string;
  x:integer;
  tmp_str:string;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Writing server schedule list...');
      r:=SendStringViaSocket(S,'set_sch_cnt'+inttostr(length(arrServerSch)),5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      {r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end; }
      for x:=1 to length(arrServerSch) do
        begin
          SetStatus('Writing server schedule event '+inttostr(x)+'...');

          //ev_days_of_month: string; // 1,2,5,10,24,31
          //ev_days_of_week: string;  // 1,2,5
          //ev_repeat_type: integer; // 1-once per day, 2-every X seconds
          //ev_repeat_interval: integer; // X seconds
          //ev_time_h: word;
          //ev_time_m: word;
          //ev_time_s: word;
          //ev_end_time_h: word;
          //ev_end_time_m: word;
          //ev_end_time_s: word; - all in one string with delimiter

          tmp_str:='';
          tmp_str:=tmp_str+arrServerSch[x-1].ev_days_of_month+ParamLimiter;
          tmp_str:=tmp_str+arrServerSch[x-1].ev_days_of_week+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_repeat_type)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_repeat_interval)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_time_h)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_time_m)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_time_s)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_end_time_h)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_end_time_m)+ParamLimiter;
          tmp_str:=tmp_str+inttostr(arrServerSch[x-1].ev_end_time_s)+ParamLimiter;
          r:=SendStringViaSocket(S,'set_sch_prm1'+tmp_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //event_name: string;
          r:=SendStringViaSocket(S,'set_sch_prm2'+arrServerSch[x-1].event_name,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //event_str: string;
          r:=SendStringViaSocket(S,'set_sch_prm3'+arrServerSch[x-1].event_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //event_main_param: string;
          r:=SendStringViaSocket(S,'set_sch_prm4'+arrServerSch[x-1].event_main_param,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //event_alarm_str: string;
          r:=SendStringViaSocket(S,'set_sch_prm5'+arrServerSch[x-1].event_alarm_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //event_execution_str: string;
          r:=SendStringViaSocket(S,'set_sch_prm6'+arrServerSch[x-1].event_execution_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }
        end;
      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      SetStatus('Ready.');
    end;
  vSocketBusy:=false;
end;

procedure GetServerBatches;
var
  r:integer;
  r_str:string;
  x,bch_cnt:integer;
  tmp_str:string;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Reading server batch list...');
      r:=SendStringViaSocket(S,'read_bch',5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'bch_cnt' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      try
        bch_cnt:=strtoint(rightstr(r_str,length(r_str)-7));
      except
        OpDisconnectSeq;
        exit;
      end;
      setlength(arrServerBatchList,bch_cnt);
      try
        for x:=1 to bch_cnt do
          begin
            SetStatus('Reading server batch '+inttostr(x)+'...');

            //batch_name: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'bch_prm1' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerBatchList[x-1].batch_name:=tmp_str;

            //batch_str: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'bch_prm2' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerBatchList[x-1].batch_str:=tmp_str;

            //batch_params: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'bch_prm3' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerBatchList[x-1].batch_params:=tmp_str;
          end;
        SetStatus('Ready.');
      except


        SetLength(arrServerBatchList,0);
        AddMsg('Error reading server batch list!');
        SetStatus('Ready.');
      end;
    end;
  vSocketBusy:=false;
end;

procedure GetServerAlarmList;
var
  r:integer;
  r_str:string;
  x,alr_cnt:integer;
  tmp_str:string;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Reading server alarm templates list...');
      r:=SendStringViaSocket(S,'read_alr',5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'alr_cnt' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      try
        alr_cnt:=strtoint(rightstr(r_str,length(r_str)-7));
      except
        OpDisconnectSeq;
        exit;
      end;
      setlength(arrServerAlarmList,alr_cnt);
      try
        for x:=1 to alr_cnt do
          begin
            SetStatus('Reading server alarm template '+inttostr(x)+'...');

            //batch_name: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'alr_prm1' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerAlarmList[x-1].alarm_template_name:=tmp_str;

            //batch_str: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'alr_prm2' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerAlarmList[x-1].alarm_template_str:=tmp_str;

            //batch_params: string;
            r_str:=GetStringViaSocket(S,5000);
            if leftstr(r_str,8)<>'alr_prm3' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            tmp_str:=rightstr(r_str,length(r_str)-8);
            arrServerAlarmList[x-1].alarm_template_params:=tmp_str;
          end;
        SetStatus('Ready.');
      except


        SetLength(arrServerBatchList,0);
        AddMsg('Error reading server alarm templates list!');
        SetStatus('Ready.');
      end;
    end;
  vSocketBusy:=false;
end;

procedure SetServerBatches;
var
  r:integer;
  r_str:string;
  x:integer;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Writing server batch list...');
      r:=SendStringViaSocket(S,'set_bch_cnt'+inttostr(length(arrServerBatchList)),5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      {r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end;}

      for x:=1 to length(arrServerBatchList) do
        begin
          SetStatus('Writing server batch '+inttostr(x)+'...');

          //batch_name: string;
          r:=SendStringViaSocket(S,'set_bch_prm1'+arrServerBatchList[x-1].batch_name,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //batch_str: string;
          r:=SendStringViaSocket(S,'set_bch_prm2'+arrServerBatchList[x-1].batch_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //batch_params: string;
          r:=SendStringViaSocket(S,'set_bch_prm3'+arrServerBatchList[x-1].batch_params,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }
        end;

      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      SetStatus('Ready.');
    end;
  vSocketBusy:=false;
end;

procedure SetServerAlarmList;
var
  r:integer;
  r_str:string;
  x:integer;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Writing server alarm templates list...');
      r:=SendStringViaSocket(S,'set_alr_cnt'+inttostr(length(arrServerAlarmList)),5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      {r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end;}

      for x:=1 to length(arrServerAlarmList) do
        begin
          SetStatus('Writing server alarm template '+inttostr(x)+'...');

          //batch_name: string;
          r:=SendStringViaSocket(S,'set_alr_prm1'+arrServerAlarmList[x-1].alarm_template_name,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //batch_str: string;
          r:=SendStringViaSocket(S,'set_alr_prm2'+arrServerAlarmList[x-1].alarm_template_str,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }

          //batch_params: string;
          r:=SendStringViaSocket(S,'set_alr_prm3'+arrServerAlarmList[x-1].alarm_template_params,5000);
          if r<>1 then
            begin
              OpDisconnectSeq;
              exit;
            end;
          {r_str:=GetStringViaSocket(S,5000);
          if leftstr(r_str,7)<>'res_suc' then
            begin
              OpDisconnectSeq;
              exit;
            end; }
        end;

      r_str:=GetStringViaSocket(S,5000);
      if leftstr(r_str,7)<>'res_suc' then
        begin
          OpDisconnectSeq;
          exit;
        end;
      SetStatus('Ready.');
    end;
  vSocketBusy:=false;
end;

procedure OpDisconnectSeq;
begin
  showmessage('Connection to IMS server is lost!');
  DisconnectSeq;
end;

procedure DisconnectSeq;
begin
 try
   fmain.Close;
 except
 end;
end;

procedure ReportRequest;
begin
  report_set:=uReportSettings.GetReportSettings();
  if report_set='' then
    begin
      Exit;
    end;
  report_dt_begin:=strtofloat(GetFieldFromString(report_set,ParamLimiter,1));
  report_dt_end:=strtofloat(GetFieldFromString(report_set,ParamLimiter,2));
  report_res_file:=GetFieldFromString(report_set,ParamLimiter,4);
  report_set:=GetFieldFromString(report_set,ParamLimiter,3);

  WaitSocketForOp(9);
end;


procedure GenerateReport();
var
  rep_str: string;
  loop_pend: boolean;
  r_str:String;
  tf:textfile;
  r:integer;
begin
  vSocketBusy:=true;
  if CheckServerConnection then
    begin
      SetStatus('Report request...');
      rep_str:=floattostr(report_dt_begin)+ParamLimiter;
      rep_str:=rep_str+floattostr(report_dt_end)+ParamLimiter;
      rep_str:=rep_str+report_set;
      r:=SendStringViaSocket(S,'get_rep'+rep_str,5000);
      if r<>1 then
        begin
          OpDisconnectSeq;
          exit;
        end;
      try
        loop_pend:=true;
        while loop_pend do
          begin
            r_str:=GetStringViaSocket(S,60000);
            if r_str='' then
              begin
                OpDisconnectSeq;
                exit;
              end;
            if leftstr(r_str,7)='res_err' then
              begin
                loop_pend:=false;
                report_res_file:='';
                Break;
              end;
            if leftstr(r_str,7)='rep_fin' then
              begin
                closefile(tf);
                loop_pend:=false;
                Break;
              end;
            if leftstr(r_str,7)='rep_rdy' then
              begin
                SetStatus(rightstr(r_str,length(r_str)-7));
              end;
            if leftstr(r_str,13)='rep_res_fname' then
              begin
                SetStatus('Downloading report...');
                AssignFile(tf,report_res_file);
                rewrite(tf);
              end;
            if leftstr(r_str,11)='rep_res_str' then
              begin
                writeln(tf,rightstr(r_str,length(r_str)-11));
              end;
          end;
        SetStatus('Ready.');
      except
        report_res_file:='';
        AddMsg('Error generating report!');
        SetStatus('Ready.');
      end;
    end;
  vSocketBusy:=false;

  if report_res_file='' then
    begin
      ShowMessage('Error generating report!');
      exit;
    end;
  ShellExecute(0,'open',pchar(report_res_file),'',pchar(ExtractFileDir(report_res_file)),SW_SHOW);
end;

end.

