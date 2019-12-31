unit uEventClassifier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uStrUtils, uCustomTypes;

function GetEventTypePart(in_str:string):string;
function GetEventNameFromID(id:string):string;
function GetIDFromEventName(ev_name:string):string;

function GetAlarmTypeStr(in_type:integer;in_params:string):string;

implementation

function GetEventTypePart(in_str:string):string;
var
  ev:string;
  tmp_str1,tmp_str2,tmp_str3:string;
begin
  tmp_str1:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,1);
  if tmp_str1='1' then
  begin
    tmp_str2:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,2);
    result:=tmp_str1+ParamLimiter+tmp_str2;
  end;
  if tmp_str1='2' then
  begin
    result:=tmp_str1;
  end;
  if tmp_str1='3' then
  begin
    tmp_str2:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,2);
    tmp_str3:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,3);
    result:=tmp_str1+ParamLimiter+tmp_str2+ParamLimiter+tmp_str3;
  end;
  if tmp_str1='4' then
  begin
    tmp_str2:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,2);
    tmp_str3:=uStrUtils.GetFieldFromString(in_str,ParamLimiter,3);
    result:=tmp_str1+ParamLimiter+tmp_str2+ParamLimiter+tmp_str3;
  end;
end;

function GetEventNameFromID(id:string):string;
begin
  result:='Error: event type not recognized!';
  // ========= 1 ============================
  if id='1' then
    begin
      result:='Network skanning';
    end;
  if id='1'+ParamLimiter+'1' then
    begin
      result:='Get subnet hosts list';
    end;
  // ========================================
  // ========= 2 ============================
  if id='2' then
    begin
      result:='Execute batch';
    end;
  // ========================================
  // ========= 3 ============================
  if id='3' then
    begin
      result:='Send data';
    end;
  if id='3'+ParamLimiter+'1' then
    begin
      result:='Generate and sand report';
    end;
  if id='3'+ParamLimiter+'1'+ParamLimiter+'1' then
    begin
      result:='Send report via e-mail';
    end;
  // ========================================
  // ========= 4 ============================
  if id='4' then
    begin
      result:='Monitoring';
    end;
  if id='4'+ParamLimiter+'1' then
    begin
      result:='Passive monitoring';
    end;
  if id='4'+ParamLimiter+'1'+ParamLimiter+'1' then
    begin
      result:='Ping network host';
    end;
  if id='4'+ParamLimiter+'1'+ParamLimiter+'2' then
    begin
      result:='Is TCP port opened on network host';
    end;
  if id='4'+ParamLimiter+'1'+ParamLimiter+'5' then
    begin
      result:='Is web page available';
    end;
  if id='4'+ParamLimiter+'1'+ParamLimiter+'8' then
    begin
      result:='Is itfx IMS server running';
    end;
  // ===========================================
end;

function GetIDFromEventName(ev_name:string):string;
begin
  // ========= 1 ============================
  if ev_name='Network skanning' then
    begin
      result:='1';
    end;
  if ev_name='Get subnet hosts list' then
    begin
      result:='1'+ParamLimiter+'1';
    end;
  // ========================================
  // ========= 2 ============================
  if ev_name='Execute batch' then
    begin
      result:='2';
    end;
  // ========================================
  // ========= 3 ============================
  if ev_name='Send data' then
    begin
      result:='3';
    end;
  if ev_name='Generate and sand report' then
    begin
      result:='3'+ParamLimiter+'1';
    end;
  if ev_name='Send report via e-mail' then
    begin
      result:='3'+ParamLimiter+'1'+ParamLimiter+'1';
    end;
  // ========================================
  // ========= 4 ============================
  if ev_name='Monitoring' then
    begin
      result:='4';
    end;
  if ev_name='Passive monitoring' then
    begin
      result:='4'+ParamLimiter+'1';
    end;
  if ev_name='Ping network host' then
    begin
      result:='4'+ParamLimiter+'1'+ParamLimiter+'1';
    end;
  if ev_name='Is TCP port opened on network host' then
    begin
      result:='4'+ParamLimiter+'1'+ParamLimiter+'2';
    end;
  if ev_name='Is web page available' then
    begin
      result:='4'+ParamLimiter+'1'+ParamLimiter+'5';
    end;
  if ev_name='Is itfx IMS server running' then
    begin
      result:='4'+ParamLimiter+'1'+ParamLimiter+'8';
    end;
  // ===========================================
end;

// =====================================================================
// alarm classifier
// =====================================================================
function GetAlarmTypeStr(in_type:integer;in_params:string):string;
begin
  if in_type=1 then
    begin
      result:='Active alarm in information agent';
    end;
  if in_type=2 then
    begin
      result:='Send e-mail to '+uStrUtils.GetFieldFromString(in_params,ParamLimiter2,2);
    end;
end;

end.

