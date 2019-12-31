unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, StdCtrls, uLogin, uCustomTypes, uNetwork, uCrypt, blcksock,
  uStrUtils, uAlarm, uSaveRestorePositionAndSize;

type
  tSTS = Record
    sts_name:string;
    sts_res:boolean;
    sts_dt:tDateTime;
  end;
  tAlarm = Record
    alrm_name:string;
    alrm_dt:tDateTime;
  end;
  TThreadMsgReader = class(TThread)
  private
    { Private declarations }
    trS:TTCPBlockSocket;
    trStsArr:array of tSTS;
    trAlrmArr:array of tAlarm;
    trExitParam:integer;
    trSocketBusy:boolean;
    trStatusToSet:string;

    procedure trSetSTS;
    procedure trSetAlrm;
    procedure trThreadExit;
    procedure trGetBusy;
    procedure trSetBusy;
    procedure trSetStatus;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(S: TTCPBlockSocket);
  end;

  { TfMain }

  TfMain = class(TForm)
    sbMain: TStatusBar;
    scbMain: TScrollBox;
    tClose: TTimer;
    tStart: TTimer;
    tThreadWatcher: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure tCloseTimer(Sender: TObject);
    procedure tStartTimer(Sender: TObject);
    procedure tThreadWatcherTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMain: TfMain;
  arrLabel1Elements:array of tLabel;
  arrLabel2Elements:array of tLabel;
  arrPanelElements:array of tPanel;
  ThreadFinished:integer;
  ThreadMsgReader:TThreadMsgReader;
  vSocketBusy:boolean;

  lp:TLoginParams;
  S:TTCPBlockSocket;

  sServerOSVer:string;

  arrClosedAlarms:array of tAlarm;

function LoginToServer(server,password:string;port:integer):TLoginResult;
procedure SetStatus(m:string);
function GetAppVer:string;

procedure DisconnectSeq;
procedure OpDisconnectSeq;

implementation
{$R *.lfm}

function LoginToServer(server,password:string;port:integer):TLoginResult;
var
  SR:TSocketResult;
  r:integer;
  r_str:string;
begin
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
  r:=SendStringViaSocket(SR.S,'log_in_ai'+uCrypt.EncodeString(password),5000);
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

  SetStatus('Ready.');
end;


procedure TfMain.tStartTimer(Sender: TObject);
var
  LR:TLoginResult;
  valid:boolean;
begin
  tStart.Enabled:=false;

  uSaveRestorePositionAndSize.RestorePositionAndSize('main',fMain);

  setlength(arrLabel1Elements,0);

  lp.lp_port:=8104;
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
  tThreadWatcher.Enabled:=true;

  SetLength(arrClosedAlarms,0);

  vSocketBusy:=false;

  SetStatus('Ready.');
end;

procedure TfMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  {try
    if lp.lp_valid then
      begin
        if ThreadFinished=0 then
          begin
            ThreadMsgReader.Terminate;
            ThreadMsgReader.WaitFor;
          end;
      end;
  except
  end;
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
  end;}
  if tClose.Tag=0 then
    begin
      CloseAction:=caNone;
      SetStatus('Disconnecting...');
      ThreadMsgReader.Terminate;
      tClose.Enabled:=true;
    end
    else
    begin
      CloseAction:=caFree;
    end;
end;


procedure TfMain.tCloseTimer(Sender: TObject);
begin
  if lp.lp_valid then
    begin
      if ThreadFinished=0 then
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


procedure TThreadMsgReader.trSetStatus;
begin
  SetStatus(trStatusToSet);
end;

procedure TThreadMsgReader.Execute;
var
  r:integer;
  r_str:string;
  cnt:integer;
  x:integer;
  tmp_str:string;
  tmp_ev_name,tmp_ev_dt_str,tmp_ev_res_str:string;
  tmp_ev_dt:tdatetime;
  tmp_ev_res:boolean;
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

    // reading status array ===============================
    r:=SendStringViaSocket(trS,'read_sts',5000);
    if r<>1 then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    r_str:=GetStringViaSocket(trS,5000);
    if leftstr(r_str,7)<>'sts_cnt' then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    cnt:=strtoint(rightstr(r_str,length(r_str)-7));
    setlength(trStsArr,cnt);
    for x:=1 to cnt do
      begin
        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,7)<>'sts_dta' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
         tmp_str:=rightstr(r_str,length(r_str)-7);
         tmp_ev_name:=GetFieldFromString(tmp_str,ParamLimiter,1);
         tmp_ev_res_str:=GetFieldFromString(tmp_str,ParamLimiter,2);
         if tmp_ev_res_str='1' then
           begin
             tmp_ev_res:=true;
           end
           else
           begin
             tmp_ev_res:=false;
           end;
         tmp_ev_dt_str:=GetFieldFromString(tmp_str,ParamLimiter,3);
         tmp_ev_dt:=tDateTime(strtofloat(tmp_ev_dt_str));
         trStsArr[x-1].sts_name:=tmp_ev_name;
         trStsArr[x-1].sts_dt:=tmp_ev_dt;
         trStsArr[x-1].sts_res:=tmp_ev_res;
      end;

    //SetLength(trStsArr,Length(trStsArr)+1);
    //trStsArr[Length(trStsArr)-1].sts_name:='test';
    //trStsArr[Length(trStsArr)-1].sts_dt:=now;
    //trStsArr[Length(trStsArr)-1].sts_res:=true;

    //SetLength(trStsArr,Length(trStsArr)+1);
    //trStsArr[Length(trStsArr)-1].sts_name:='test2';
    //trStsArr[Length(trStsArr)-1].sts_dt:=now;
    //trStsArr[Length(trStsArr)-1].sts_res:=false;

    Synchronize(@trSetSTS);
    // ================================================


    // reading alarm array ===============================
    r:=SendStringViaSocket(trS,'read_alrm',5000);
    if r<>1 then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    r_str:=GetStringViaSocket(trS,5000);
    if leftstr(r_str,8)<>'alrm_cnt' then
      begin
        //OpDisconnectSeq;
        trExitParam:=2;
        Synchronize(@trThreadExit);
        exit;
      end;
    cnt:=strtoint(rightstr(r_str,length(r_str)-8));
    setlength(trAlrmArr,cnt);
    for x:=1 to cnt do
      begin
        r_str:=GetStringViaSocket(trS,5000);
        if leftstr(r_str,8)<>'alrm_dta' then
          begin
            //OpDisconnectSeq;
            trExitParam:=2;
            Synchronize(@trThreadExit);
            exit;
          end;
         tmp_str:=rightstr(r_str,length(r_str)-8);
         tmp_ev_name:=GetFieldFromString(tmp_str,ParamLimiter,1);
         tmp_ev_dt_str:=GetFieldFromString(tmp_str,ParamLimiter,2);
         tmp_ev_dt:=tDateTime(strtofloat(tmp_ev_dt_str));
         trAlrmArr[x-1].alrm_name:=tmp_ev_name;
         trAlrmArr[x-1].alrm_dt:=tmp_ev_dt;
      end;

    //SetLength(trAlrmArr,Length(trAlrmArr)+1);
    //trAlrmArr[Length(trAlrmArr)-1].alrm_name:='test alarm';
    //trAlrmArr[Length(trAlrmArr)-1].alrm_dt:=now;

    //SetLength(trAlrmArr,Length(trAlrmArr)+1);
    //trAlrmArr[Length(trAlrmArr)-1].alrm_name:='test alarm 2';
    //trAlrmArr[Length(trAlrmArr)-1].alrm_dt:=now;

    Synchronize(@trSetAlrm);
    // ================================================

    trStatusToSet:='Last update '+datetimetostr(now);
    Synchronize(@trSetStatus);

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
end;

procedure TThreadMsgReader.trThreadExit;
begin
  ThreadFinished:=trExitParam;
end;

procedure TThreadMsgReader.trSetSTS;
var
  x:integer;
  pos_y:integer;
begin
  for x:=1 to length(arrLabel1Elements) do
    begin
      arrLabel1Elements[x-1].Destroy;
      arrLabel2Elements[x-1].Destroy;
      arrPanelElements[x-1].Destroy;
    end;
  SetLength(arrLabel1Elements,0);
  SetLength(arrLabel2Elements,0);
  SetLength(arrPanelElements,0);

  SetLength(arrLabel1Elements,length(trStsArr));
  SetLength(arrLabel2Elements,length(trStsArr));
  SetLength(arrPanelElements,length(trStsArr));

  for x:=1 to length(trStsArr) do
    begin
      pos_y:=5+(x-1)*28;

      arrPanelElements[x-1]:=TPanel.Create(nil);
      arrPanelElements[x-1].Parent:=fMain.scbMain;
      arrPanelElements[x-1].Caption:='';
      arrPanelElements[x-1].Align:=alCustom;
      arrPanelElements[x-1].Left:=5;
      arrPanelElements[x-1].Top:=pos_y;
      arrPanelElements[x-1].Width:=24;
      arrPanelElements[x-1].Height:=24;
      if trStsArr[x-1].sts_res then
        begin
          arrPanelElements[x-1].Color:=clGreen;
        end
        else
        begin
          arrPanelElements[x-1].Color:=clRed;
        end;
      arrPanelElements[x-1].Visible:=true;

      arrLabel1Elements[x-1]:=TLabel.Create(nil);
      arrLabel1Elements[x-1].Parent:=fMain.scbMain;
      arrLabel1Elements[x-1].Caption:=trStsArr[x-1].sts_name;
      arrLabel1Elements[x-1].Align:=alCustom;
      arrLabel1Elements[x-1].Left:=34;
      arrLabel1Elements[x-1].Top:=pos_y-3;
      arrLabel1Elements[x-1].AutoSize:=true;
      arrLabel1Elements[x-1].Visible:=true;

      arrLabel2Elements[x-1]:=TLabel.Create(nil);
      arrLabel2Elements[x-1].Parent:=fMain.scbMain;
      arrLabel2Elements[x-1].Caption:=datetimetostr(trStsArr[x-1].sts_dt);
      arrLabel2Elements[x-1].Align:=alCustom;
      arrLabel2Elements[x-1].Left:=34;
      arrLabel2Elements[x-1].Top:=pos_y+14-3;
      arrLabel2Elements[x-1].AutoSize:=true;
      arrLabel2Elements[x-1].Font.Color:=clGray;
      arrLabel2Elements[x-1].Visible:=true;
    end;
end;

procedure TThreadMsgReader.trSetAlrm;
var
  x,y:integer;
  found:boolean;
begin
  for x:=1 to Length(trAlrmArr) do
    begin
      // check if this alarm was showed
      found:=false;
      for y:=1 to Length(arrClosedAlarms) do
        begin
          if (trAlrmArr[x-1].alrm_name=arrClosedAlarms[y-1].alrm_name) and
             (trAlrmArr[x-1].alrm_dt=arrClosedAlarms[y-1].alrm_dt) then
            begin
              found:=true;
            end;
        end;
      if found then
        begin
          Continue;
        end;

      // show
      uAlarm.ShowAlarm(trAlrmArr[x-1].alrm_name,trAlrmArr[x-1].alrm_dt);
      //register
      setlength(arrClosedAlarms,Length(arrClosedAlarms)+1);
      arrClosedAlarms[Length(arrClosedAlarms)-1]:=trAlrmArr[x-1];
    end;
  setlength(trAlrmArr,0);
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

procedure TThreadMsgReader.trSetBusy;
begin
  vSocketBusy:=trSocketBusy;
end;

procedure TThreadMsgReader.trGetBusy;
begin
  trSocketBusy:=vSocketBusy;
end;

constructor TThreadMsgReader.Create(S: TTCPBlockSocket);
begin
  inherited create(false);
  FreeOnTerminate := true;
  trS := S;
end;

end.

