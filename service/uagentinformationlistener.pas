unit uAgentInformationListener;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synsock, uLog, uNetwork, blcksock,
  uAgentInformationConnection;


type
  TThreadAgentInformationListener = class(TThread)
  private
    { Private declarations }
    trLocalIp:string;
    trPort:integer;
    trLogMsg:string;
    S:TTCPBlockSocket;

    procedure ReadParams;
    //procedure toLog;
    procedure trWriteLog(msg_str:string);
    //procedure UpdateCurrSocketID;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(local_ip: string);
  end;

implementation
uses uMain;


constructor TThreadAgentInformationListener.Create(local_ip: string);
begin
  inherited create(false);
  FreeOnTerminate := true;
  trLocalIp := local_ip;
end;


procedure TThreadAgentInformationListener.Execute;
var
  S_res:TSocketResult;
  ss:tSocket;
  le:integer;
begin
 FreeOnTerminate:=true;
 //Synchronize(@ReadParams);
 ReadParams;
 S_res:=PrepereSocketToListen(trLocalIp,trPort);
 While S_res.res<>1 do
   begin
     if Terminated then
       begin
         exit;
       end;
     trWriteLog('Error: cannot bind socket to local ip '+trLocalIp+' port '+inttostr(trPort)+'; err '+inttostr(-1*S_res.res));
     trWriteLog('Waiting 5 seconds and try again..');
     Sleep(5000);
     S_res:=PrepereSocketToListen(trLocalIp,trPort);
   end;
 S:=S_res.S;

 while not Terminated do
   begin
     if s.CanRead(500) then
       begin
         S.ResetLastError;
         ss:=S.Accept;
         le:=s.LastError;
         if le<>0 Then
           begin
             trWriteLog('Error while accepting connection. Err '+inttostr(-1*le));
             Continue;
           end;
         // start new thread to proceed connection
         uAgentInformationConnection.TThreadAgentInformationConnection.Create(ss);
       end;
   end;
  s.CloseSocket;
end;

procedure TThreadAgentInformationListener.ReadParams;
begin
 //trPort:=uMain.sAgentInformationListeningPort;
 cs1.Enter;
 trPort:=sAgentInformationListeningPort;
 cs1.Leave;
end;

//procedure TThreadAgentInformationListener.toLog;
//begin
// uLog.WriteLogMsg(trLogMsg);
//end;

procedure TThreadAgentInformationListener.trWriteLog(msg_str:string);
begin
 //trLogMsg:=msg_str;
 //Synchronize(@toLog);
 uLog.WriteLogMsg(msg_str);
end;

end.

