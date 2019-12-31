unit uCrypt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils;

const p='Press any button to continue...';

function EncodeString(in_str:string):string;
function DecodeString(in_str:string):string;

implementation

function EncodeString(in_str:string):string;
var
  tmp:string;
  tmp2:string;
begin
  try
    tmp2:=inttostr(length(in_str));
    while length(tmp2)<3 do
      begin
        tmp2:='0'+tmp2;
      end;
    tmp:=in_str+tmp2;

    tmp:=strutils.XorEncode(p,tmp);
    tmp:=ReverseString(tmp);
    tmp:=strutils.XorEncode(p,tmp);
  except
    tmp:='';
  end;
  result:=tmp;
end;

function DecodeString(in_str:string):string;
var
  tmp:string;
  tmp2:String;
begin
  try
    tmp:=strutils.XorDecode(p,in_str);
    tmp:=ReverseString(tmp);
    tmp:=strutils.XorDecode(p,tmp);

    tmp2:=rightstr(tmp,3);
    tmp:=leftstr(tmp,length(tmp)-3);
    if length(tmp)<>strtoint(tmp2) then
      begin
        tmp:='';
      end;
  except
    tmp:='';
  end;
  result:=tmp;
end;


end.

