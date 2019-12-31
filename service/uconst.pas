unit uConst;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uPath;

function ReadConst(c_name:string):string;
procedure WriteConst(c_name,c_val:string);

implementation

uses uMain;

procedure WriteConst(c_name,c_val:string);
var
  fp:string;
  tf:textfile;
begin
  cs11.Enter;

  fp:=GetConstDirPath+c_name+'.cnt';
  Assignfile(tf,fp);
  try
    Rewrite(tf);
    writeln(tf,c_val);
  except
  end;
  try
    closefile(tf);
  except
  end;

  cs11.Leave;
end;

function ReadConst(c_name:string):string;
var
  fp:string;
  tf:textfile;
  tmp:string;
begin
  cs11.Enter;

  fp:=GetConstDirPath()+c_name+'.cnt';
  if not FileExists(fp) then
    begin
      result:='';
    end;
  Assignfile(tf,fp);
  tmp:='';
  try
    Reset(tf);
    readln(tf,tmp);
  except
    tmp:='';
  end;
  try
    closefile(tf);
  except
    tmp:='';
  end;
  result:=tmp;

  cs11.Leave;
end;


end.

