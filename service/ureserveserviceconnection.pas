unit uReserveServiceConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, synsock, uNetwork;

type
  TThreadReserveServiceConnection = class(TThread)
  private
    ss:TSocket;
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    constructor Create(in_ss: TSocket);
  end;

implementation
uses uMain;

constructor TThreadReserveServiceConnection.Create(in_ss: TSocket);
begin
  inherited create(false);
  FreeOnTerminate := true;
  ss := in_ss;
end;

procedure TThreadReserveServiceConnection.Execute;
var
  S:TTCPBlockSocket;
  alive:boolean;
  res_str:string;
  tmp_str1:string;
  is_valid_version:boolean;
begin
  is_valid_version:=false;

  S := TTCPBlockSocket.Create;
  S.Socket:=ss;
  alive:=true;
  While alive do
    begin
      res_str:=uNetwork.GetStringViaSocket(S,10000); // 10 sec
      if res_str='' then
        begin
          alive:=false;
          break;
        end;

      // check app ver ==================================
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
              uNetwork.SendStringViaSocket(S,'MSGMain and reserve server version must be identical!',SNDRCVTimeout);
              alive:=false;
              break;
            end;
          Continue;
        end;

      // ============ logon must be finished at this time ======================

      if (not is_valid_version) then
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
      // ========================================
    end;
  s.CloseSocket;
end;

end.

