unit uSaveRestorePositionAndSize;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, forms, uPath;

procedure SavePositionAndSize(fName:string;form:TForm);
procedure RestorePositionAndSize(fName:string;form:TForm);

implementation


procedure SavePositionAndSize(fName:string;form:TForm);
var
  fn:string;
  f:textfile;
begin
  fn:=uPath.GetWorkDirPath+'\'+fname+'.pos';
  assignfile(f,fn);
  rewrite(f);
  writeln(f,form.Left);
  writeln(f,form.top);
  writeln(f,form.Width);
  writeln(f,form.Height);
  CloseFile(f);
end;

procedure RestorePositionAndSize(fName:string;form:TForm);
var
  fn:string;
  f:textfile;
  tmp:string;
begin
  fn:=uPath.GetWorkDirPath+'\'+fname+'.pos';
  if fileexists(fn) then
    begin
      Assignfile(f,fn);
      reset(f);
      readln(f,tmp);
      form.Left:=strtoint(tmp);
      readln(f,tmp);
      form.top:=strtoint(tmp);
      readln(f,tmp);
      form.Width:=strtoint(tmp);
      readln(f,tmp);
      form.Height:=strtoint(tmp);
      CloseFile(f);
    end;
end;

end.

