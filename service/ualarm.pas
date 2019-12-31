unit uAlarm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uStrUtils, uMail;

type
  TAlarmTemplate = record
    alarm_template_name: string;
    alarm_template_str: string;
    alarm_template_params: string;
  end;
  TAlarmTemplateArray = array of TAlarmTemplate;
  TDecodedAlarmTemplateElement = record
    ate_type:integer;
    ate_param:string;
  end;
  TDecodedAlarmTemplate = array of TDecodedAlarmTemplateElement;
  //TAlarmTemplateResult = record
  //  atr_alarm_template:TAlarmTemplate;
  //  res:boolean;
  //end;
  TAlarmForIA = record
    alarm_name: string;
    alarm_dt:tDateTime;
  end;
  TExecuteAlarmTemplateResult = record
    arrAddAlarmForIA :array of TDateTime;
    arrRes: TStringList;
  end;


function FindAlarm(arr_alarm:TAlarmTemplateArray; alarm_template_name:string):TAlarmTemplate;
function ExecuteAlarmTemplate(alarm_template:TAlarmTemplate; event_name,sudo_pwd:string):TExecuteAlarmTemplateResult;
function DecodeAlarmTemplate(alarm_template:TAlarmTemplate):TDecodedAlarmTemplate;


implementation

uses uMain;


function FindAlarm(arr_alarm:TAlarmTemplateArray; alarm_template_name:string):TAlarmTemplate;
var
  x:integer;
begin
  result.alarm_template_name:='';
  result.alarm_template_params:='';
  result.alarm_template_str:='';
  for x:=1 to length(arr_alarm) do
    begin
      if UpperCase(arr_alarm[x-1].alarm_template_name)=UpperCase(alarm_template_name) then
        begin
          result.alarm_template_name:=arr_alarm[x-1].alarm_template_name;
          result.alarm_template_params:=arr_alarm[x-1].alarm_template_params;
          result.alarm_template_str:=arr_alarm[x-1].alarm_template_str;
        end;
    end;
end;


function ExecuteAlarmTemplate(alarm_template:TAlarmTemplate; event_name,sudo_pwd:string):TExecuteAlarmTemplateResult;
var
  dalarmarr:TDecodedAlarmTemplate;
  dalarmel:TDecodedAlarmTemplateElement;
  x:integer;
  tmp_str2:string;
  tmp_res:integer;
begin
  Result.arrRes := TStringList.Create;
  SetLength(Result.arrAddAlarmForIA,0);
  dalarmarr:=DecodeAlarmTemplate(alarm_template);
  if dalarmarr[0].ate_param='err' then
    begin
      Result.arrRes.Add('err');
      exit;
    end;
  Result.arrRes.Add('Alarm template ['+alarm_template.alarm_template_name+'] begin execution...');
  for x:=1 to length(dalarmarr) do
    begin
      dalarmel:=dalarmarr[x-1];
      if dalarmel.ate_type=1 then // show in information agent
        begin
          SetLength(Result.arrAddAlarmForIA,Length(Result.arrAddAlarmForIA)+1);
          Result.arrAddAlarmForIA[Length(Result.arrAddAlarmForIA)-1]:=Now;
        end;
      if dalarmel.ate_type=2 then // send e-mail
        begin
          tmp_str2 := uStrUtils.GetFieldFromString(dalarmel.ate_param,
                      ParamLimiter2, 3);
          if uStrUtils.GetFieldFromString(dalarmel.ate_param,
                ParamLimiter2, 4) <> '' then
            begin
              tmp_str2 := tmp_str2 + ':' +
                  uStrUtils.GetFieldFromString(dalarmel.ate_param, ParamLimiter2, 4);
            end;

          tmp_res := SendMailText(uStrUtils.GetFieldFromString(
                dalarmel.ate_param, ParamLimiter2, 1), // send from email
                uStrUtils.GetFieldFromString(dalarmel.ate_param,
                ParamLimiter2, 2), // send to email
                uStrUtils.GetFieldFromString(dalarmel.ate_param,
                ParamLimiter2, 7), // subject
                tmp_str2, // smtp host[:port]
                uStrUtils.GetFieldFromString(dalarmel.ate_param,
                ParamLimiter2, 5), // login
                uStrUtils.GetFieldFromString(dalarmel.ate_param,
                ParamLimiter2, 6), // password
                'Event ['+event_name+']: alarm!'  // alarm text to send
                );
          if tmp_res<>1 then
            begin
              Result.arrRes.Add('Error sending alarm e-mail! Check e-mail settings, please.');
            end;
        end;
    end;
  Result.arrRes.Add('Alarm template ['+alarm_template.alarm_template_name+'] execution finished.');
end;


function DecodeAlarmTemplate(alarm_template:TAlarmTemplate):TDecodedAlarmTemplate;
var
  count:integer;
  x:integer;
  tmp:string;
begin
  setlength(result,0);
  try
    count:=strtoint(uStrUtils.GetFieldFromString(alarm_template.alarm_template_str, ParamLimiter, 1));
    setlength(result,count);
    for x:=1 to count do
      begin
        result[x-1].ate_param:=uStrUtils.GetFieldFromString(alarm_template.alarm_template_params, ParamLimiter, x);
        // alarm type
        tmp:=uStrUtils.GetFieldFromString(alarm_template.alarm_template_str, ParamLimiter, x+1);
        result[x-1].ate_type:=strtoint(tmp);
      end;
  except
    setlength(result,1);
    Result[0].ate_param:='err';
  end;
end;

end.

