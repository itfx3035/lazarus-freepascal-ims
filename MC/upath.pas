unit uPath;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows;

function GetWorkDirPath:string;

implementation

function GetWorkDirPath:string;
var
  SysDirPath:array [0..256] of char;
  SysDir,SysDrive:string;
  WorkDir:string;
begin
  GetSystemDirectory(SysDirPath,256);
  SysDir:=string(SysDirPath);
  SysDrive:=ExtractFileDrive(SysDir);
  WorkDir:=SysDrive+'\itfx';
  if not DirectoryExists(WorkDir) then
    begin
      CreateDir(WorkDir);
    end;
  WorkDir:=WorkDir+'\IMS';
  if not DirectoryExists(WorkDir) then
    begin
      CreateDir(WorkDir);
    end;
  WorkDir:=WorkDir+'\MC';
  if not DirectoryExists(WorkDir) then
    begin
      CreateDir(WorkDir);
    end;
  result:=WorkDir;
end;



end.

