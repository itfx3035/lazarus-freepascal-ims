unit uStrUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,strutils, dateutils, uCustomTypes;

function GetFieldFromString(in_str,divider:string;field_num:integer):string;

function GetExecStrArgList(in_str:string):string;
function GetExecStrMainFileName(in_str:string):string;

function DT2STR(dt:tDateTime):string;
function D2STR(dt:tDate):string;
function STR2DT(is_str:String):tDateTime;

function ValidSymbols(in_str:string):boolean;
function ValidName(in_str:string):boolean;

function ValidFileNameSymbols:string;

implementation

function ValidFileNameSymbols:string;
begin
  result:='0123456789';
  result:=result+' ';
  result:=result+'qwertyuiopasdfghjklzxcvbnm';
  result:=result+'QWERTYUIOPASDFGHJKLZXCVBNM';
  result:=result+'.,:;-_+=`#@^&()[]''';
end;

function ValidName(in_str: string): boolean;
var
  x,len:integer;
  curr_char:string;
begin
  result:=true;
  len:=length(in_str);
  for x:=1 to len do
    begin
      curr_char:=in_str[x];
      if not AnsiContainsStr(ValidFileNameSymbols,curr_char) then
        begin
          result:=false;
          exit;
        end;
    end;
end;

function ValidSymbols(in_str:string):boolean;
begin
  Result:=true;
  if (strutils.AnsiContainsStr(in_str,ParamLimiter)) or (strutils.AnsiContainsStr(in_str,ParamLimiter2)) then
    begin
      Result:=false;
    end;
end;

function DT2STR(dt:tDateTime):string;
begin
  result:=FormatDateTime('yyyy.mm.dd hh:nn:ss',dt);
end;

function D2STR(dt:tDate):string;
begin
  result:=FormatDateTime('yyyy.mm.dd',dt);
end;

function STR2DT(is_str:String):tDateTime;
var
  y,m,d,h,n,s:Word;
begin
  result:=0;
  try
    y:=strtoint(MidStr(is_str,1,4));
    m:=strtoint(MidStr(is_str,6,2));
    d:=strtoint(MidStr(is_str,9,2));
    h:=strtoint(MidStr(is_str,12,2));
    n:=strtoint(MidStr(is_str,15,2));
    s:=strtoint(MidStr(is_str,18,2));
  except
    exit;
  end;
  try
    Result:=EncodeDateTime(y,m,d,h,n,s,0);
  except
  end;
end;

function GetFieldFromString(in_str,divider:string;field_num:integer):string;
var
  x,len:integer;
  curr_f_n:integer;
  res:string;
  curr_char:string;
begin
  res:='';
  curr_f_n:=1;
  len:=length(in_str);
  for x:=1 to len do
    begin
      curr_char:=in_str[x];
      if curr_char=divider then
        begin
          curr_f_n:=curr_f_n+1;
          Continue;
        end;
      if field_num=curr_f_n then
        begin
          res:=res+curr_char;
        end;
      if curr_f_n>field_num then
        begin
          break;
        end;
    end;
  result:=res;
end;


function GetExecStrMainFileName(in_str:string):string;
begin
  result:=trim(GetFieldFromString(in_str,' ',1));
end;

function GetExecStrArgList(in_str:string):string;
var
  x,len:integer;
  is_arg:boolean;
  res:string;
  curr_char:string;
begin
  res:='';
  is_arg:=false;
  len:=length(in_str);
  for x:=1 to len do
    begin
      curr_char:=in_str[x];
      if (curr_char=' ') and (not is_arg) then
        begin
          is_arg:=true;
          Continue;
        end;
      if is_arg then
        begin
          res:=res+curr_char;
        end;
    end;
  result:=trim(res);
end;

end.

