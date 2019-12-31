unit uProcessExecute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, uStrUtils, uLog
  {$IFDEF WINDOWS}
  ,windows
  {$ENDIF};

type
  TBatchToExecute = record
    exec_param: string;
    exec_wait_finish: boolean;
    exec_timeout: string;
    exec_write_log: boolean;
  end;

  TThreadProcessExecuter = class(TThread)
  private
    { Private declarations }
    trParam: string;
    trSudoPwd: string;
    trTimeout: integer;
    trWriteResult: boolean;

    resSL: TStringList;
    trLogMsg: string;

    procedure WriteResToLog;
    procedure toReportMSG;
    procedure trWriteReportMSG(msg_str: string);
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(param, sudo_pwd: string; timeout: integer; write_result: boolean);
  end;


function ExecuteAndWaitOutput(param,sudo_pwd: string; timeout_sec: integer): TStringList;
procedure ExecuteAndNoWait(param,sudo_pwd: string; timeout_sec: integer; write_result: boolean);

function CheckAdminPrev(sudo_pwd:string):boolean;


implementation

function CheckAdminPrev(sudo_pwd:string):boolean;
var
  w_path:array[0..1024] of char;
  fp:string;
  tf:textfile;
begin
  {$IFDEF UNIX}
  fp:='/etc/tmp_adm_f_ch.tmp';
  try
    ExecuteAndWaitOutput('dd if=/dev/zero of='+fp+' bs=1k count=1', sudo_pwd, 10);
  except
  end;
  if fileexists(fp) then
    begin
      result:=true;
    end
    else
    begin
      Result:=false;
    end;
  try
    ExecuteAndWaitOutput('rm -f '+fp, sudo_pwd, 10);
  except
  end;
  {$ENDIF}

  {$IFDEF WINDOWS}
  windows.GetSystemDirectory(w_path,1024);
  fp:=string(w_path)+'\tmp_adm_f_ch.txt';
  try
    AssignFile(tf,fp);
    rewrite(tf);
    writeln(tf,fp);
  except
  end;
  try
    closefile(tf);
  except
  end;
  if FileExists(fp) then
    begin
      result:=true;
    end
    else
    begin
      Result:=false;
    end;
  try
    SysUtils.DeleteFile(fp);
  except
  end;
  {$ENDIF}
end;

constructor TThreadProcessExecuter.Create(param, sudo_pwd: string; timeout: integer;
  write_result: boolean);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  trParam := param;
  trSudoPwd:= sudo_pwd;
  trTimeout := timeout;
  trWriteResult := write_result;
end;

procedure TThreadProcessExecuter.Execute;
var
  iserr: boolean;
begin
  iserr := False;
  trWriteReportMSG('4 Thread ID: ' + IntToStr(Handle)+', executing ['+trParam+']');
  try
    resSL := ExecuteAndWaitOutput(trParam, trSudoPwd, trTimeout);
  except
    iserr := True;
  end;
  if iserr then
  begin
    trWriteReportMSG('0 Thread ID: ' + IntToStr(Handle)+', error executing ['+trParam+']');
    exit;
  end;
  if trWriteResult then
  begin
    //Synchronize(@WriteResToLog);
    WriteResToLog;
  end;
  trWriteReportMSG('4 Thread ID: ' + IntToStr(Handle) + ' execution finished.');
end;

procedure TThreadProcessExecuter.trWriteReportMSG(msg_str: string);
begin
  trLogMsg := msg_str;
  //Synchronize(@toReportMSG);
  toReportMSG;
end;

procedure TThreadProcessExecuter.toReportMSG;
begin
  uLog.WriteReportMsg(trLogMsg);
end;

procedure TThreadProcessExecuter.WriteResToLog;
var
  x: integer;
begin
  for x := 1 to resSL.Count do
  begin
    uLog.WriteReportMsg('4 Thread ID ' + IntToStr(Handle) + ' - ' + resSL[x - 1]);
  end;
end;

procedure ExecuteAndNoWait(param,sudo_pwd: string; timeout_sec: integer; write_result: boolean);
begin
  TThreadProcessExecuter.Create(param, sudo_pwd, timeout_sec, write_result);
end;



function ExecuteAndWaitOutput(param,sudo_pwd: string; timeout_sec: integer): TStringList;
var
  MemStream: TMemoryStream;
  NumBytes: longint;
  BytesRead: longint;
  OurProcess: TProcess;
  begin_time: tdatetime;
  timeout_double: double;
  timeout_verb:string;
  term: boolean;
  SudoPassword:string;
  something_readed:boolean;
  BytesToRead:integer;
begin

  MemStream := TMemoryStream.Create;
  BytesRead := 0;

  timeout_verb:='timeout '+inttostr(timeout_sec)+' ';
  if timeout_sec = 0 then
  begin
    timeout_sec := 999999999;
    timeout_verb:='';
  end;
  timeout_double := timeout_sec / (24 * 3600);

  OurProcess := TProcess.Create(nil);

  {$IFDEF WINDOWS}
  OurProcess.CommandLine := param;
  {$ENDIF}

  // on linux we need to execute 'sudo' to get root, and set timeout
  // on windows our service must be executed under admin, so we don't need this
  {$IFDEF UNIX}
  if LeftStr(sudo_pwd,1)='1' then
    begin
      OurProcess.CommandLine := timeout_verb+'sudo -S '+param;
    end
    else
    begin
      OurProcess.CommandLine := timeout_verb+param;
    end;
  {$ENDIF}
  OurProcess.Options := [poUsePipes];
  OurProcess.Execute;

  // input param sudo (pwd) writing after executing 'sudo'
  {$IFDEF UNIX}
  if LeftStr(sudo_pwd,1)='1' then
    begin
      SudoPassword:='';
      SudoPassword := rightstr(sudo_pwd,length(sudo_pwd)-1) + LineEnding;
      OurProcess.Input.Write(SudoPassword[1], Length(SudoPassword));
      SudoPassword:='';
    end;
  {$ENDIF}

  begin_time := now;
  term := False;
  BytesToRead := 2048;

  while (OurProcess.Running) do
  begin
    something_readed:=false;

    // read stdout
    BytesToRead:=OurProcess.Output.NumBytesAvailable;
    if BytesToRead>0 then
      begin
        MemStream.SetSize(BytesRead + BytesToRead);
        NumBytes := OurProcess.Output.Read((MemStream.Memory + BytesRead)^, BytesToRead);
        if NumBytes > 0 then
          begin
            Inc(BytesRead, NumBytes);
            something_readed:=true;
          end;
      end;

    // read stderr
    BytesToRead:=OurProcess.Stderr.NumBytesAvailable;
    if BytesToRead>0 then
      begin
        MemStream.SetSize(BytesRead + BytesToRead);
        NumBytes := OurProcess.Stderr.Read((MemStream.Memory + BytesRead)^, BytesToRead);
        if NumBytes > 0 then
          begin
            Inc(BytesRead, NumBytes);
            something_readed:=true;
          end;
      end;

    // check time on windows, terminate our process if exceeded
    {$IFDEF WINDOWS}
    if (now - begin_time) > timeout_double then
      begin
        OurProcess.Terminate(1);
      end;
    {$ENDIF}

    if not something_readed then
      begin
        Sleep(100); // no output, waiting...
      end;
  end;

  // execution finished
  repeat
    MemStream.SetSize(BytesRead + 2048);
    NumBytes := OurProcess.Output.Read((MemStream.Memory + BytesRead)^, 2048);
    if NumBytes > 0 then
    begin
      Inc(BytesRead, NumBytes);
    end;
  until NumBytes <= 0;
  repeat
    MemStream.SetSize(BytesRead + 2048);
    NumBytes := OurProcess.Stderr.Read((MemStream.Memory + BytesRead)^, 2048);
    if NumBytes > 0 then
    begin
      Inc(BytesRead, NumBytes);
    end;
  until NumBytes <= 0;

  MemStream.SetSize(BytesRead);
  Result := TStringList.Create;
  Result.LoadFromStream(MemStream);
  OurProcess.Free;
  MemStream.Free;
end;


end.
