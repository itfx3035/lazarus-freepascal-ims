unit uNetwork;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synSock, blcksock, synaip;

type
  TSocketResult = record
    S: TTCPBlockSocket;
    res: integer;
  end;
  TStrArr = array of string;

function CheckPortOpened(net_ip: string; port: string): integer;
//----------------
function PrepereSocketToListen(local_ip:string; port: integer): TSocketResult;
function PrepereSocketToConnect(net_ip: string; port: integer): TSocketResult;
//----------------
function SendStringViaSocket(S: TTCPBlockSocket; s_str_in: string;
  RCVtimeout: integer): integer;
function SendStringViaSocket_ll(S: TTCPBlockSocket; s_str_in: string): integer;
function GetStringViaSocket(S: TTCPBlockSocket; timeout: integer): string;
function GetStringViaSocket_ll(S: TTCPBlockSocket; timeout: integer): string;

function GetLocalIpList:TStrArr;

implementation

function GetLocalIpList:TStrArr;
var
  bs:TBlockSocket;
  ips:TStrings;
  x:integer;
  tmp_ip:string;
begin
  setlength(result,1);
  result[0]:='127.0.0.1';
  bs:=TBlockSocket.Create;
  ips:=TStringList.Create;
  bs.ResolveNameToIP(bs.LocalName,ips);
  for x:=1 to ips.Count do
    begin
      tmp_ip:=ips[x-1];
      if synaip.IsIP(tmp_ip) then
        begin
          setlength(Result,length(Result)+1);
          Result[length(Result)-1]:=tmp_ip;
        end;
    end;
end;

function CheckPortOpened(net_ip: string; port: string): integer;
var
  s: TTCPBlockSocket;
  su: TUDPBlockSocket;
  full_port_name,portnum:string;
  r:integer;
begin
  full_port_name:=trim(port);
  if UPPERCASE(leftstr(full_port_name,4))='TCP:' then
    begin
      portnum:=rightstr(full_port_name,length(full_port_name)-4);

      s := TTCPBlockSocket.Create;
      s.ResetLastError;
      s.Connect(net_ip, portnum);
      if s.LastError = 0 then
      begin
        Result := 1;
      end
      else
      begin
        Result := -1 * s.LastError;
      end;
      s.CloseSocket;
    end;
end;


function PrepereSocketToListen(local_ip:string; port: integer): TSocketResult;
var
  s: TTCPBlockSocket;
begin
  s := TTCPBlockSocket.Create;
  Result.S := s;
  Result.res := 1;
  s.ResetLastError;
  //s.Bind('127.0.0.1', IntToStr(port));
  s.Bind(local_ip, IntToStr(port));
  if s.LastError <> 0 then
  begin
    s.CloseSocket;
    Result.res := -1 * s.LastError;
    exit;
  end;
  s.Listen;
  if s.LastError <> 0 then
  begin
    s.CloseSocket;
    Result.res := -1 * s.LastError;
    exit;
  end;
end;


function PrepereSocketToConnect(net_ip: string; port: integer): TSocketResult;
var
  s: TTCPBlockSocket;
begin
  s := TTCPBlockSocket.Create;
  Result.S := s;
  Result.res := 1;
  s.ResetLastError;
  s.Connect(net_ip, IntToStr(port));
  if s.LastError <> 0 then
  begin
    s.CloseSocket;
    Result.res := -1 * s.LastError;
    exit;
  end;
end;


function SendStringViaSocket_ll(S: TTCPBlockSocket; s_str_in: string): integer;
var
  s_str: string;
begin
  Result := 1;
  s_str := s_str_in + '/_EOL_/' + #13 + #10;
  s.ResetLastError;
  S.SendString(s_str);
  if S.LastError <> 0 then
  begin
    Result := -1 * S.LastError;
    exit;
  end;
end;

function SendStringViaSocket(S: TTCPBlockSocket; s_str_in: string;
  RCVtimeout: integer): integer;
var
  ansv: string;
  r: integer;
begin
  r := SendStringViaSocket_ll(S, s_str_in);
  if r = 1 then
  begin
    ansv := GetStringViaSocket_ll(S, RCVtimeout);
    if leftstr(ansv, 3) = 'RCV' then
    begin
      if StrToInt(RightStr(ansv, length(ansv) - 3)) = length(s_str_in) then
      begin
        SendStringViaSocket_ll(S, 'ACPT');
        Result := 1;
      end
      else
      begin
        SendStringViaSocket_ll(S, 'CRC_ERR');
        Result := -1;
      end;
    end
    else
    begin
      Result := -1;
    end;
  end
  else
  begin
    Result := r;
  end;
end;


function GetStringViaSocket_ll(s: TTCPBlockSocket; timeout: integer): string;
var
  res_str: string;
  le: integer;
begin
  s.ResetLastError;
  res_str := s.RecvString(timeout);
  le := S.LastError;
  if le = WSAETIMEDOUT then
  begin
    Result := '';
    exit;
  end;
  if le <> 0 then
  begin
    Result := '';
    exit;
  end;
  if rightstr(res_str, 7) = '/_EOL_/' then
  begin
    Result := leftstr(res_str, length(res_str) - 7);
    exit;
  end;
  Result := '';
end;

function GetStringViaSocket(s: TTCPBlockSocket; Timeout: integer): string;
var
  res_str: string;
begin
  res_str := GetStringViaSocket_ll(s, Timeout);
  if res_str <> '' then
  begin
    SendStringViaSocket_ll(s, 'RCV' + IntToStr(length(res_str)));
    Result := res_str;
    res_str := GetStringViaSocket_ll(s, Timeout);
    if res_str <> '' then
    begin
      if res_str <> 'ACPT' then
      begin
        Result := '';
      end;
    end
    else
    begin
      Result := '';
    end;
  end
  else
  begin
    Result := '';
  end;
end;



end.
