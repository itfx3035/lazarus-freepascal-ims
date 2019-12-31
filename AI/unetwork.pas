unit uNetwork;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synSock, blcksock;

type
  TSocketResult = Record
    S:TTCPBlockSocket;
    res:integer;
  end;

function CheckPortOpened(net_ip: string; port: integer): integer;
//----------------
function PrepereSocketToListen(port: integer): TSocketResult;
function PrepereSocketToConnect(net_ip: string; port: integer): TSocketResult;
//----------------
function SendStringViaSocket(S: TTCPBlockSocket; s_str_in: string; RCVtimeout:integer): integer;
function SendStringViaSocket_ll(S: TTCPBlockSocket; s_str_in: string): integer;
function GetStringViaSocket(S: TTCPBlockSocket; timeout:integer): string;
function GetStringViaSocket_ll(S: TTCPBlockSocket; timeout:integer): string;


implementation


function CheckPortOpened(net_ip: string; port: integer): integer;
var
  s:TTCPBlockSocket;
begin
  s:=TTCPBlockSocket.Create;
  s.ResetLastError;
  s.Connect(net_ip,inttostr(port));
  if s.LastError=0 then
    begin
      result:=1;
    end
    else
    begin
      result:=-1*s.LastError;
    end;
  s.CloseSocket;
end;


function PrepereSocketToListen(port: integer): TSocketResult;
var
  s: TTCPBlockSocket;
begin
  s:=TTCPBlockSocket.Create;
  result.S:=s;
  result.res:=1;
  s.ResetLastError;
  s.Bind('127.0.0.1',inttostr(port));
  if s.LastError<>0 then
    begin
      s.CloseSocket;
      result.res:=-1*s.LastError;
      exit;
    end;
  s.Listen;
  if s.LastError<>0 then
    begin
      s.CloseSocket;
      result.res:=-1*s.LastError;
      exit;
    end;
end;


function PrepereSocketToConnect(net_ip: string; port: integer): TSocketResult;
var
  s: TTCPBlockSocket;
begin
  s:=TTCPBlockSocket.Create;
  result.S:=s;
  result.res:=1;
  s.ResetLastError;
  s.Connect(net_ip,inttostr(port));
  if s.LastError<>0 then
    begin
      s.CloseSocket;
      result.res:=-1*s.LastError;
      exit;
    end;
end;


function SendStringViaSocket_ll(S: TTCPBlockSocket; s_str_in: string): integer;
var
  s_str: string;
begin
  Result := 1;
  s_str := s_str_in + '/_EOL_/'+#13+#10;
  s.ResetLastError;
  S.SendString(s_str);
  if S.LastError<>0 then
    begin
      result:=-1*S.LastError;
      exit;
    end;
end;

function SendStringViaSocket(S: TTCPBlockSocket; s_str_in: string; RCVtimeout:integer): integer;
var
  ansv: string;
  r: integer;
begin
  r := SendStringViaSocket_ll(S, s_str_in);
  if r = 1 then
    begin
      ansv := GetStringViaSocket_ll(S,RCVtimeout);
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


function GetStringViaSocket_ll(s: TTCPBlockSocket; timeout:integer): string;
var
  res_str: string;
  le:integer;
begin
  s.ResetLastError;
  res_str:=s.RecvString(timeout);
  le:=S.LastError;
  if le=WSAETIMEDOUT then
    begin
      result:='';
      exit;
    end;
  if le<>0 then
    begin
      result:='';
      exit;
    end;
  if rightstr(res_str, 7) = '/_EOL_/' then
    begin
      Result := leftstr(res_str, length(res_str) - 7);
      exit;
    end;
  result:='';
end;

function GetStringViaSocket(s: TTCPBlockSocket; Timeout:integer): string;
var
  res_str: string;
begin
  res_str := GetStringViaSocket_ll(s,Timeout);
  if res_str<>'' then
    begin
      SendStringViaSocket_ll(s, 'RCV' + IntToStr(length(res_str)));
      result:=res_str;
      res_str:=GetStringViaSocket_ll(s,Timeout);
      if res_str<>'' then
        begin
          if res_str<>'ACPT' then
            begin
              Result:='';
            end;
        end
        else
        begin
          Result:='';
        end;
    end
    else
    begin
      result:='';
    end;
end;



end.


