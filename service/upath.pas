unit uPath;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WINDOWS}
  shfolder,
  {$ENDIF}
  Classes, SysUtils;


function GetDailyLogFilePath(d:tDateTime):string;
function GetSettingsFilePath:string;
function GetSchedulerListFilePath:string;
function GetBatchDataFilePath:string;
function GetAlarmDataFilePath:string;
function GetReportLogsFilePath(d:tDateTime):string;
function GetReportDataFilePath(d:tDateTime):string;
function GetConstDirPath:string;
function GetOfflineLogFilePath(d:tDateTime):string;

function GetReportTmpFilePath(d:tDateTime):string;

function GetAppDataPath:string;



implementation

function GetAppDataPath:string;
var
 AppDataDirPath:string;
 tmpstr:array [0..2048] of char;
begin
  {$IFDEF WINDOWS}
  SHGetFolderPath(0,CSIDL_WINDOWS,0,0,tmpstr);
  AppDataDirPath:=ExtractFileDrive(strpas(tmpstr))+'\itfx';
  if not DirectoryExists(AppDataDirPath) then
    begin
      CreateDir(AppDataDirPath);
    end;
  AppDataDirPath:=AppDataDirPath+'\ims';
  if not DirectoryExists(AppDataDirPath) then
    begin
      CreateDir(AppDataDirPath);
    end;
  {$ENDIF}
  {$IFDEF UNIX}
  AppDataDirPath:='/opt/itfx/ims';
  {$ENDIF}
  result:=AppDataDirPath;
end;


function GetDailyLogFilePath(d:tDateTime):string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
end;

function GetSettingsFilePath:string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/settins.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\settins.txt';
  {$ENDIF}
end;

function GetSchedulerListFilePath:string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/sh_list.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\sh_list.txt';
  {$ENDIF}
end;

function GetBatchDataFilePath:string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/batch_data.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\batch_data.txt';
  {$ENDIF}
end;

function GetAlarmDataFilePath:string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/alarm_data.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\alarm_data.txt';
  {$ENDIF}
end;

function GetReportLogsFilePath(d:tDateTime):string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/report_logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\report_logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
end;

function GetReportDataFilePath(d:tDateTime):string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/report_data';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\report_data';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
end;


function GetConstDirPath:string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/const';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\const';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\';
  {$ENDIF}
end;

function GetOfflineLogFilePath(d:tDateTime):string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/offline_logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\offline_logs';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\'+FormatDateTime('yyyy_mm_dd',d)+'.txt';
  {$ENDIF}
end;

function GetReportTmpFilePath(d:tDateTime):string;
begin
  {$IFDEF UNIX}
  result:=GetAppDataPath+'/tmp_reports';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'/'+FormatDateTime('yyyy_mm_dd_hh_nn_ss',d)+'.html';
  {$ENDIF}
  {$IFDEF WINDOWS}
  result:=GetAppDataPath+'\tmp_reports';
  if not DirectoryExists(result) then
    begin
      CreateDir(result);
    end;
  result:=result+'\'+FormatDateTime('yyyy_mm_dd_hh_nn_ss',d)+'.html';
  {$ENDIF}
end;


end.

