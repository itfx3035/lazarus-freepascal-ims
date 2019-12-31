unit uEditEvent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, uCustomTypes, uSelectEventType, uStrUtils, strutils, uSelectPortNumber,
  uSelectHTTPHeader, uEventClassifier, uBchEditor, uSelectSubnet,
  uAlarmTemplateEditor;

type

  { TfEditEvent }

  TfEditEvent = class(TForm)
    bSelectAlarmTemplate: TButton;
    bTargetIPSelect: TButton;
    bCancel: TButton;
    bDMAllOff: TButton;
    bDMInvert: TButton;
    bOK: TButton;
    bSetTo000000: TButton;
    bSetTo235959: TButton;
    bDMAllOn: TButton;
    bSelectTaskType: TButton;
    bAddParamSelect: TButton;
    bSelectBatch: TButton;
    cbDM1: TCheckBox;
    cbDM10: TCheckBox;
    cbDM11: TCheckBox;
    cbDM12: TCheckBox;
    cbDM13: TCheckBox;
    cbDM14: TCheckBox;
    cbDM15: TCheckBox;
    cbDM16: TCheckBox;
    cbDM17: TCheckBox;
    cbDM18: TCheckBox;
    cbDM19: TCheckBox;
    cbDM2: TCheckBox;
    cbDM20: TCheckBox;
    cbDM21: TCheckBox;
    cbDM22: TCheckBox;
    cbDM23: TCheckBox;
    cbDM24: TCheckBox;
    cbDM25: TCheckBox;
    cbDM26: TCheckBox;
    cbDM27: TCheckBox;
    cbDM28: TCheckBox;
    cbDM29: TCheckBox;
    cbDM3: TCheckBox;
    cbDM30: TCheckBox;
    cbDM31: TCheckBox;
    cbDM4: TCheckBox;
    cbDM5: TCheckBox;
    cbDM6: TCheckBox;
    cbDM7: TCheckBox;
    cbDM8: TCheckBox;
    cbDM9: TCheckBox;
    cbDW1: TCheckBox;
    cbDW2: TCheckBox;
    cbDW3: TCheckBox;
    cbDW4: TCheckBox;
    cbDW5: TCheckBox;
    cbDW6: TCheckBox;
    cbDW7: TCheckBox;
    cbRepeatType: TCheckBox;
    cbReportMode: TComboBox;
    cbExecutionCondition: TComboBox;
    cbAlarmMode: TComboBox;
    cbReportOptions12: TCheckBox;
    cbReportOptions211: TCheckBox;
    cbReportOptions212: TCheckBox;
    cbReportOptions22: TCheckBox;
    cbStatistics: TCheckBox;
    cbReportOptions11: TCheckBox;
    cbShowStatusInAI: TCheckBox;
    eAddParam: TEdit;
    eAlarmTemplate: TEdit;
    eResultRepeatCountForAlarm: TEdit;
    eTargetIP: TEdit;
    eBatch: TEdit;
    eEMailSubject: TEdit;
    eEMailLogin: TEdit;
    eEMailPassword: TEdit;
    eEMailSMTPServer: TEdit;
    eEMailSender: TEdit;
    eEMailSendTo: TEdit;
    eEMailSMTPPort: TEdit;
    eResultRepeatCountForExecution: TEdit;
    eStatName: TEdit;
    eResultRepeatCount: TEdit;
    eTaskType: TEdit;
    eTimeH: TEdit;
    eRepeatInterval: TEdit;
    eTaskName: TEdit;
    eEndTimeH: TEdit;
    eTimeM: TEdit;
    eEndTimeM: TEdit;
    eTimeS: TEdit;
    eEndTimeS: TEdit;
    gbTargetIP: TGroupBox;
    gbExecutionCase: TGroupBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    gbReportType: TGroupBox;
    gbStatistics: TGroupBox;
    gbAddidtionalParam: TGroupBox;
    gbBatchToExecute: TGroupBox;
    gbReportOptions: TGroupBox;
    gbReportEMailSettings: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    pcEditTask: TPageControl;
    Main: TTabSheet;
    Schedule: TTabSheet;
    Execution: TTabSheet;
    Alarm: TTabSheet;
    procedure bAddParamSelectClick(Sender: TObject);
    procedure bCancelClick(Sender: TObject);
    procedure bDMAllOffClick(Sender: TObject);
    procedure bDMAllOnClick(Sender: TObject);
    procedure bDMInvertClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bSelectAlarmTemplateClick(Sender: TObject);
    procedure bSelectBatchClick(Sender: TObject);
    procedure bSelectTaskTypeClick(Sender: TObject);
    procedure bSetTo000000Click(Sender: TObject);
    procedure bSetTo235959Click(Sender: TObject);
    procedure bTargetIPSelectClick(Sender: TObject);
    procedure cbAlarmModeChange(Sender: TObject);
    procedure cbExecutionConditionChange(Sender: TObject);
    procedure cbRepeatTypeChange(Sender: TObject);
    procedure cbReportModeChange(Sender: TObject);
    procedure cbStatisticsChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure GroupBox8Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;



var
  fEditEvent: TfEditEvent;
  res:TEventResult;
  initEventName:string;


function EditEvent(in_event:TSchedulerEvent):TEventResult;

procedure SetMDays(md_string:string);
procedure SetWDays(md_string:string);
procedure OnRepeatTypeEdit;
procedure OnTaskTypeEdit;
procedure OnReportModeChange;
procedure OnStatModeChange;

procedure OnExecutonConditionChange;
procedure OnAlarmConditionChange;

function CollectMonthDaysString:string;
function CollectWeekDaysString:string;

implementation
{$R *.lfm}

uses uSchEditor;

{ TfEditEvent }

function EditEvent(in_event:TSchedulerEvent):TEventResult;
var
  task_id,task_id3,tmp_param,tmp_param2:string;
begin
  Application.CreateForm(TfEditEvent, fEditEvent);

  initEventName:=in_event.event_name;

  // params fill (main)
  fEditEvent.eTaskType.Text:=uEventClassifier.GetEventNameFromID(uEventClassifier.GetEventTypePart(in_event.event_str));
  fEditEvent.eTaskName.Text:=in_event.event_name;
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  OnTaskTypeEdit;
  if leftstr(task_id,1)='1' then
    begin
      fEditEvent.eTargetIP.Text:=in_event.event_main_param;
      fEditEvent.eAddParam.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,3);
    end;
  if (leftstr(task_id,1)='2') then
    begin
      tmp_param:=GetFieldFromString(in_event.event_str,ParamLimiter,2);
      fEditEvent.cbReportMode.ItemIndex:=0;
      if tmp_param='1' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=1;
        end;
    end;
  if (leftstr(task_id,1)='3') then
    begin
      tmp_param:=GetFieldFromString(in_event.event_str,ParamLimiter,4);
      if GetFieldFromString(tmp_param,'/',1)='1' then
      begin
        fEditEvent.cbReportOptions11.Checked:=true;
      end;
      if GetFieldFromString(tmp_param,'/',2)='1' then
      begin
        fEditEvent.cbReportOptions12.Checked:=true;
      end;
      if GetFieldFromString(tmp_param,'/',3)='1' then
      begin
        fEditEvent.cbReportOptions22.Checked:=true;
      end;
      if GetFieldFromString(tmp_param,'/',4)='1' then
      begin
        fEditEvent.cbReportOptions211.Checked:=true;
      end;
      if GetFieldFromString(tmp_param,'/',5)='1' then
      begin
        fEditEvent.cbReportOptions212.Checked:=true;
      end;

      fEditEvent.eEMailSender.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,1);
      fEditEvent.eEMailSendTo.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,2);
      fEditEvent.eEMailSMTPServer.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,3);
      fEditEvent.eEMailSMTPPort.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,4);
      fEditEvent.eEMailLogin.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,5);
      fEditEvent.eEMailPassword.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,6);
      fEditEvent.eEMailSubject.Text:=GetFieldFromString(in_event.event_main_param,ParamLimiter,7);
    end;
  if (leftstr(task_id,1)='4') then
    begin
      // report settiings
      tmp_param:=GetFieldFromString(in_event.event_str,ParamLimiter,4);
      fEditEvent.cbReportMode.ItemIndex:=0;
      if tmp_param='1/1' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=1;
        end;
      if tmp_param='1/2' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=3;
          tmp_param2:=GetFieldFromString(in_event.event_str,ParamLimiter,5);
          fEditEvent.eResultRepeatCount.text:=tmp_param2;
        end;
      if tmp_param='1/3' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=2;
          tmp_param2:=GetFieldFromString(in_event.event_str,ParamLimiter,5);
          fEditEvent.eResultRepeatCount.text:=tmp_param2;
        end;
      if tmp_param='1/4' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=5;
          tmp_param2:=GetFieldFromString(in_event.event_str,ParamLimiter,5);
          fEditEvent.eResultRepeatCount.text:=tmp_param2;
        end;
      if tmp_param='1/5' then
        begin
          fEditEvent.cbReportMode.ItemIndex:=4;
          tmp_param2:=GetFieldFromString(in_event.event_str,ParamLimiter,5);
          fEditEvent.eResultRepeatCount.text:=tmp_param2;
        end;
      OnReportModeChange;
      // statistics
      tmp_param:=GetFieldFromString(in_event.event_str,ParamLimiter,6);
      if tmp_param='1' then
        begin
          fEditEvent.cbStatistics.Checked:=true;
          fEditEvent.eStatName.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,7);
        end
        else
        begin
          fEditEvent.cbStatistics.Checked:=false;
          fEditEvent.eStatName.Text:='';
        end;
      OnStatModeChange;
      fEditEvent.eTargetIP.Text:=in_event.event_main_param;

      task_id3:=GetFieldFromString(task_id,ParamLimiter,3);
      if task_id3='2' then
        begin
          fEditEvent.eAddParam.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,8);
        end;
      if task_id3='5' then
        begin
          fEditEvent.eAddParam.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,8);
        end;
      if task_id3='8' then
        begin
          fEditEvent.eAddParam.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,8);
        end;
    end;

  // params fill (schedule)
  SetMDays(in_event.ev_days_of_month);
  SetWDays(in_event.ev_days_of_week);
  fEditEvent.eTimeH.Text:=inttostr(in_event.ev_time_h);
  fEditEvent.eTimeM.Text:=inttostr(in_event.ev_time_m);
  fEditEvent.eTimeS.Text:=inttostr(in_event.ev_time_s);
  fEditEvent.eEndTimeH.Text:=inttostr(in_event.ev_end_time_h);
  fEditEvent.eEndTimeM.Text:=inttostr(in_event.ev_end_time_m);
  fEditEvent.eEndTimeS.Text:=inttostr(in_event.ev_end_time_s);
  if in_event.ev_repeat_type=2 then
    begin
      fEditEvent.cbRepeatType.Checked:=true;
    end
    else
    begin
      fEditEvent.cbRepeatType.Checked:=false;
    end;
  OnRepeatTypeEdit;
  fEditEvent.eRepeatInterval.Text:=inttostr(in_event.ev_repeat_interval);

  // param fill (execution)
  if (leftstr(task_id,1)='2') then
    begin
      fEditEvent.eBatch.Text:=GetFieldFromString(in_event.event_str,ParamLimiter,3);
    end;
  if (leftstr(task_id,1)='4') then
    begin
      fEditEvent.eBatch.Text:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,3);
      // execution condition
      tmp_param:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,1);
      if tmp_param='0' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=0;
        end;
      if tmp_param='1/1' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=1;
        end;
      if tmp_param='1/3' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=2;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,2);
          fEditEvent.eResultRepeatCountForExecution.Text:=tmp_param2;
        end;
      if tmp_param='1/2' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=3;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,2);
          fEditEvent.eResultRepeatCountForExecution.Text:=tmp_param2;
        end;
      if tmp_param='1/5' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=4;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,2);
          fEditEvent.eResultRepeatCountForExecution.Text:=tmp_param2;
        end;
      if tmp_param='1/4' then
        begin
          fEditEvent.cbExecutionCondition.ItemIndex:=5;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_execution_str,ParamLimiter,2);
          fEditEvent.eResultRepeatCountForExecution.Text:=tmp_param2;
        end;
      OnExecutonConditionChange;
    end;

  // param fill (alarm)
  if (leftstr(task_id,1)='4') then
    begin
      if GetFieldFromString(in_event.event_alarm_str,ParamLimiter,1)='1' then
        begin
          fEditEvent.cbShowStatusInAI.Checked:=true;
        end
        else
        begin
          fEditEvent.cbShowStatusInAI.Checked:=false;
        end;
      fEditEvent.eAlarmTemplate.Text:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,4);
      // alarm condition
      tmp_param:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,2);
      if tmp_param='0' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=0;
        end;
      if tmp_param='1/1' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=1;
        end;
      if tmp_param='1/3' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=2;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,3);
          fEditEvent.eResultRepeatCountForAlarm.Text:=tmp_param2;
        end;
      if tmp_param='1/2' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=3;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,3);
          fEditEvent.eResultRepeatCountForAlarm.Text:=tmp_param2;
        end;
      if tmp_param='1/5' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=4;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,3);
          fEditEvent.eResultRepeatCountForAlarm.Text:=tmp_param2;
        end;
      if tmp_param='1/4' then
        begin
          fEditEvent.cbAlarmMode.ItemIndex:=5;
          // condition repeat
          tmp_param2:=GetFieldFromString(in_event.event_alarm_str,ParamLimiter,3);
          fEditEvent.eResultRepeatCountForAlarm.Text:=tmp_param2;
        end;
      OnAlarmConditionChange;
    end;


  fEditEvent.pcEditTask.TabIndex:=0;

  res.res:=false;

  fEditEvent.ShowModal;
  Result:=res;
end;

procedure OnStatModeChange;
begin
  if fEditEvent.cbStatistics.Checked then
    begin
      fEditEvent.eStatName.Enabled:=true;
    end
    else
    begin
      fEditEvent.eStatName.Enabled:=false;
    end;
end;

procedure OnTaskTypeEdit;
var
  task_id, task_id3:string;
begin
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  if leftstr(task_id,1)='4' then
    begin
      fEditEvent.gbReportType.Visible:=true;
      fEditEvent.gbStatistics.Visible:=true;
      task_id3:=GetFieldFromString(task_id,ParamLimiter,3);
      if task_id3='2' then
        begin
          fEditEvent.gbAddidtionalParam.Visible:=true;
          fEditEvent.gbAddidtionalParam.Caption:='Port';
          fEditEvent.eAddParam.ReadOnly:=true;
          fEditEvent.eAddParam.Text:='';
          fEditEvent.bAddParamSelect.Enabled:=true;
        end;
      if task_id3='8' then
        begin
          fEditEvent.gbAddidtionalParam.Visible:=true;
          fEditEvent.gbAddidtionalParam.Caption:='Port';
          fEditEvent.eAddParam.ReadOnly:=false;
          fEditEvent.eAddParam.Text:='8105';
          fEditEvent.bAddParamSelect.Enabled:=false;
        end;
      if task_id3='5' then
        begin
          fEditEvent.gbAddidtionalParam.Visible:=true;
          fEditEvent.gbAddidtionalParam.Caption:='Expect HTTP header';
          fEditEvent.eAddParam.ReadOnly:=true;
          fEditEvent.eAddParam.Text:='';
          fEditEvent.bAddParamSelect.Enabled:=true;
        end;
      if task_id3='1' then
        begin
          fEditEvent.gbAddidtionalParam.Visible:=false;
        end;

      fEditEvent.cbReportMode.Items.Clear;
      fEditEvent.cbReportMode.Items.Add('Never');
      fEditEvent.cbReportMode.Items.Add('Always');
      fEditEvent.cbReportMode.Items.Add('Positive only');
      fEditEvent.cbReportMode.Items.Add('Negative only');
      fEditEvent.cbReportMode.Items.Add('First positive');
      fEditEvent.cbReportMode.Items.Add('First negative');
      fEditEvent.cbReportMode.ItemIndex:=0;

      fEditEvent.cbExecutionCondition.Items.Clear;
      fEditEvent.cbExecutionCondition.Items.Add('Never');
      fEditEvent.cbExecutionCondition.Items.Add('Always');
      fEditEvent.cbExecutionCondition.Items.Add('Positive only');
      fEditEvent.cbExecutionCondition.Items.Add('Negative only');
      fEditEvent.cbExecutionCondition.Items.Add('First positive');
      fEditEvent.cbExecutionCondition.Items.Add('First negative');
      fEditEvent.cbExecutionCondition.ItemIndex:=0;

      fEditEvent.gbReportOptions.Visible:=false;
      fEditEvent.gbReportEMailSettings.Visible:=false;

      fEditEvent.gbTargetIP.Visible:=true;
      fEditEvent.gbTargetIP.Caption:='Targer IP or host name';
      fEditEvent.bTargetIPSelect.Enabled:=false;
      fEditEvent.eTargetIP.Text:='';
      fEditEvent.eTargetIP.ReadOnly:=false;

      // execution
      fEditEvent.Execution.TabVisible:=true;
      fEditEvent.gbExecutionCase.Visible:=true;
      OnExecutonConditionChange;

      // alarm
      fEditEvent.Alarm.TabVisible:=true;
      fEditEvent.cbAlarmMode.Items.Clear;
      fEditEvent.cbAlarmMode.Items.Add('Never');
      fEditEvent.cbAlarmMode.Items.Add('Always');
      fEditEvent.cbAlarmMode.Items.Add('Positive only');
      fEditEvent.cbAlarmMode.Items.Add('Negative only');
      fEditEvent.cbAlarmMode.Items.Add('First positive');
      fEditEvent.cbAlarmMode.Items.Add('First negative');
      fEditEvent.cbAlarmMode.ItemIndex:=0;

    end;
  if leftstr(task_id,1)='3' then
    begin
      fEditEvent.gbReportType.Visible:=false;
      fEditEvent.gbStatistics.Visible:=false;
      fEditEvent.gbAddidtionalParam.Visible:=false;
      fEditEvent.gbReportOptions.Visible:=true;
      fEditEvent.gbReportEMailSettings.Visible:=true;

      fEditEvent.gbTargetIP.Visible:=false;

      // execution
      fEditEvent.Execution.TabVisible:=False;
      fEditEvent.gbExecutionCase.Visible:=false;

      // alarm
      fEditEvent.Alarm.TabVisible:=true;
    end;
  if leftstr(task_id,1)='2' then
    begin
      fEditEvent.gbReportType.Visible:=true;
      //only y/n
      fEditEvent.cbReportMode.Items.Clear;
      fEditEvent.cbReportMode.Items.Add('Never');
      fEditEvent.cbReportMode.Items.Add('Always');
      fEditEvent.cbReportMode.ItemIndex:=0;

      fEditEvent.gbStatistics.Visible:=false;
      fEditEvent.gbAddidtionalParam.Visible:=false;

      fEditEvent.gbReportOptions.Visible:=false;
      fEditEvent.gbReportEMailSettings.Visible:=false;

      fEditEvent.gbTargetIP.Visible:=false;

      // execution
      fEditEvent.Execution.TabVisible:=true;
      fEditEvent.gbExecutionCase.Visible:=false;
      OnExecutonConditionChange;

      // alarm
      fEditEvent.Alarm.TabVisible:=false;
    end;
  if leftstr(task_id,1)='1' then
    begin
      fEditEvent.gbReportType.Visible:=false;
      fEditEvent.gbStatistics.Visible:=false;

      fEditEvent.gbAddidtionalParam.Visible:=true;
      fEditEvent.gbAddidtionalParam.Caption:='Ping timeout (ms)';
      fEditEvent.eAddParam.ReadOnly:=false;
      fEditEvent.eAddParam.Text:='1000';
      fEditEvent.bAddParamSelect.Enabled:=false;

      fEditEvent.gbReportOptions.Visible:=false;
      fEditEvent.gbReportEMailSettings.Visible:=false;

      fEditEvent.gbTargetIP.Visible:=true;
      fEditEvent.gbTargetIP.Caption:='Subnet';
      fEditEvent.bTargetIPSelect.Enabled:=true;
      fEditEvent.eTargetIP.Text:='';
      fEditEvent.eTargetIP.ReadOnly:=true;

      // execution
      fEditEvent.Execution.TabVisible:=false;
      fEditEvent.gbExecutionCase.Visible:=false;

      // alarm
      fEditEvent.Alarm.TabVisible:=false;
    end;
  OnReportModeChange;
end;

procedure OnRepeatTypeEdit;
begin
  fEditEvent.eRepeatInterval.Enabled:=fEditEvent.cbRepeatType.Checked;
end;

procedure SetMDays(md_string:string);
begin
  fEditEvent.cbDM1.Checked:=Strutils.AnsiContainsStr(md_string,'01,');
  fEditEvent.cbDM2.Checked:=Strutils.AnsiContainsStr(md_string,'02,');
  fEditEvent.cbDM3.Checked:=Strutils.AnsiContainsStr(md_string,'03,');
  fEditEvent.cbDM4.Checked:=Strutils.AnsiContainsStr(md_string,'04,');
  fEditEvent.cbDM5.Checked:=Strutils.AnsiContainsStr(md_string,'05,');
  fEditEvent.cbDM6.Checked:=Strutils.AnsiContainsStr(md_string,'06,');
  fEditEvent.cbDM7.Checked:=Strutils.AnsiContainsStr(md_string,'07,');
  fEditEvent.cbDM8.Checked:=Strutils.AnsiContainsStr(md_string,'08,');
  fEditEvent.cbDM9.Checked:=Strutils.AnsiContainsStr(md_string,'09,');
  fEditEvent.cbDM10.Checked:=Strutils.AnsiContainsStr(md_string,'10,');
  fEditEvent.cbDM11.Checked:=Strutils.AnsiContainsStr(md_string,'11,');
  fEditEvent.cbDM12.Checked:=Strutils.AnsiContainsStr(md_string,'12,');
  fEditEvent.cbDM13.Checked:=Strutils.AnsiContainsStr(md_string,'13,');
  fEditEvent.cbDM14.Checked:=Strutils.AnsiContainsStr(md_string,'14,');
  fEditEvent.cbDM15.Checked:=Strutils.AnsiContainsStr(md_string,'15,');
  fEditEvent.cbDM16.Checked:=Strutils.AnsiContainsStr(md_string,'16,');
  fEditEvent.cbDM17.Checked:=Strutils.AnsiContainsStr(md_string,'17,');
  fEditEvent.cbDM18.Checked:=Strutils.AnsiContainsStr(md_string,'18,');
  fEditEvent.cbDM19.Checked:=Strutils.AnsiContainsStr(md_string,'19,');
  fEditEvent.cbDM20.Checked:=Strutils.AnsiContainsStr(md_string,'20,');
  fEditEvent.cbDM21.Checked:=Strutils.AnsiContainsStr(md_string,'21,');
  fEditEvent.cbDM22.Checked:=Strutils.AnsiContainsStr(md_string,'22,');
  fEditEvent.cbDM23.Checked:=Strutils.AnsiContainsStr(md_string,'23,');
  fEditEvent.cbDM24.Checked:=Strutils.AnsiContainsStr(md_string,'24,');
  fEditEvent.cbDM25.Checked:=Strutils.AnsiContainsStr(md_string,'25,');
  fEditEvent.cbDM26.Checked:=Strutils.AnsiContainsStr(md_string,'26,');
  fEditEvent.cbDM27.Checked:=Strutils.AnsiContainsStr(md_string,'27,');
  fEditEvent.cbDM28.Checked:=Strutils.AnsiContainsStr(md_string,'28,');
  fEditEvent.cbDM29.Checked:=Strutils.AnsiContainsStr(md_string,'29,');
  fEditEvent.cbDM30.Checked:=Strutils.AnsiContainsStr(md_string,'30,');
  fEditEvent.cbDM31.Checked:=Strutils.AnsiContainsStr(md_string,'31,');
end;

procedure SetWDays(md_string:string);
begin
  fEditEvent.cbDW1.Checked:=Strutils.AnsiContainsStr(md_string,'1,');
  fEditEvent.cbDW2.Checked:=Strutils.AnsiContainsStr(md_string,'2,');
  fEditEvent.cbDW3.Checked:=Strutils.AnsiContainsStr(md_string,'3,');
  fEditEvent.cbDW4.Checked:=Strutils.AnsiContainsStr(md_string,'4,');
  fEditEvent.cbDW5.Checked:=Strutils.AnsiContainsStr(md_string,'5,');
  fEditEvent.cbDW6.Checked:=Strutils.AnsiContainsStr(md_string,'6,');
  fEditEvent.cbDW7.Checked:=Strutils.AnsiContainsStr(md_string,'7,');
end;

procedure TfEditEvent.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfEditEvent.GroupBox8Click(Sender: TObject);
begin

end;

function CollectWeekDaysString:string;
begin
  result:='';
  if fEditEvent.cbDW1.Checked then
    begin
      result:=result+'1,';
    end;
  if fEditEvent.cbDW2.Checked then
    begin
      result:=result+'2,';
    end;
  if fEditEvent.cbDW3.Checked then
    begin
      result:=result+'3,';
    end;
  if fEditEvent.cbDW4.Checked then
    begin
      result:=result+'4,';
    end;
  if fEditEvent.cbDW5.Checked then
    begin
      result:=result+'5,';
    end;
  if fEditEvent.cbDW6.Checked then
    begin
      result:=result+'6,';
    end;
  if fEditEvent.cbDW7.Checked then
    begin
      result:=result+'7,';
    end;
end;

function CollectMonthDaysString:string;
begin
  result:='';
  if fEditEvent.cbDM1.Checked then
    begin
      result:=result+'01,';
    end;
  if fEditEvent.cbDM2.Checked then
    begin
      result:=result+'02,';
    end;
  if fEditEvent.cbDM3.Checked then
    begin
      result:=result+'03,';
    end;
  if fEditEvent.cbDM4.Checked then
    begin
      result:=result+'04,';
    end;
  if fEditEvent.cbDM5.Checked then
    begin
      result:=result+'05,';
    end;
  if fEditEvent.cbDM6.Checked then
    begin
      result:=result+'06,';
    end;
  if fEditEvent.cbDM7.Checked then
    begin
      result:=result+'07,';
    end;
  if fEditEvent.cbDM8.Checked then
    begin
      result:=result+'08,';
    end;
  if fEditEvent.cbDM9.Checked then
    begin
      result:=result+'09,';
    end;
  if fEditEvent.cbDM10.Checked then
    begin
      result:=result+'10,';
    end;
  if fEditEvent.cbDM11.Checked then
    begin
      result:=result+'11,';
    end;
  if fEditEvent.cbDM12.Checked then
    begin
      result:=result+'12,';
    end;
  if fEditEvent.cbDM13.Checked then
    begin
      result:=result+'13,';
    end;
  if fEditEvent.cbDM14.Checked then
    begin
      result:=result+'14,';
    end;
  if fEditEvent.cbDM15.Checked then
    begin
      result:=result+'15,';
    end;
  if fEditEvent.cbDM16.Checked then
    begin
      result:=result+'16,';
    end;
  if fEditEvent.cbDM17.Checked then
    begin
      result:=result+'17,';
    end;
  if fEditEvent.cbDM18.Checked then
    begin
      result:=result+'18,';
    end;
  if fEditEvent.cbDM19.Checked then
    begin
      result:=result+'19,';
    end;
  if fEditEvent.cbDM20.Checked then
    begin
      result:=result+'20,';
    end;
  if fEditEvent.cbDM21.Checked then
    begin
      result:=result+'21,';
    end;
  if fEditEvent.cbDM22.Checked then
    begin
      result:=result+'22,';
    end;
  if fEditEvent.cbDM23.Checked then
    begin
      result:=result+'23,';
    end;
  if fEditEvent.cbDM24.Checked then
    begin
      result:=result+'24,';
    end;
  if fEditEvent.cbDM25.Checked then
    begin
      result:=result+'25,';
    end;
  if fEditEvent.cbDM26.Checked then
    begin
      result:=result+'26,';
    end;
  if fEditEvent.cbDM27.Checked then
    begin
      result:=result+'27,';
    end;
  if fEditEvent.cbDM28.Checked then
    begin
      result:=result+'28,';
    end;
  if fEditEvent.cbDM29.Checked then
    begin
      result:=result+'29,';
    end;
  if fEditEvent.cbDM30.Checked then
    begin
      result:=result+'30,';
    end;
  if fEditEvent.cbDM31.Checked then
    begin
      result:=result+'31,';
    end;
end;

procedure TfEditEvent.bOKClick(Sender: TObject);
var
  new_task_id, id_part1,id_part2,id_part3:string;
  isErr:boolean;
  int_prm1,int_prm2,int_prm3:integer;
  mdString,mwString:string;
  tmp_int:integer;
  dtBegin,dtEnd:TDateTime;
begin
  if trim(eTaskName.Text)='' then
    begin
      ShowMessage('Empty task name!');
      Exit;
    end;
  if uSchEditor.EventNameUsed(trim(eTaskName.Text),initEventName) then
    begin
      ShowMessage('Task name "'+trim(eTaskName.Text)+'" already used!');
      Exit;
    end;
  if not ValidName(eTaskName.Text) then
    begin
      ShowMessage('Task name contains invalid symbols!');
      Exit;
    end;

  if trim(eTaskType.Text)='' then
    begin
      ShowMessage('Invalid task type!');
      Exit;
    end;

  // check schedule always ======================
  mdString:=CollectMonthDaysString;
  mwString:=CollectWeekDaysString;
  if (mdString='') or (mwString='') then
    begin
      ShowMessage('No any days for this task allowed!');
      Exit;
    end;

  isErr:=false;
  try
    int_prm1:=strtoint(eTimeH.Text);
    int_prm2:=strtoint(eTimeM.Text);
    int_prm3:=strtoint(eTimeS.Text);
    dtBegin:=EncodeTime(int_prm1,int_prm2,int_prm3,0);
  except
    isErr:=true;
  end;
  if isErr then
    begin
      ShowMessage('Invalid execution begin time!');
      Exit;
    end;
  isErr:=false;
  try
    int_prm1:=strtoint(eEndTimeH.Text);
    int_prm2:=strtoint(eEndTimeM.Text);
    int_prm3:=strtoint(eEndTimeS.Text);
    dtEnd:=EncodeTime(int_prm1,int_prm2,int_prm3,0);
  except
    isErr:=true;
  end;
  if isErr then
    begin
      ShowMessage('Invalid execution end time!');
      Exit;
    end;

  if cbRepeatType.Checked then
    begin
      try
        tmp_int:=strtoint(eRepeatInterval.Text);
      except
        ShowMessage('Invalid repeat interval!');
        Exit;
      end;
      if tmp_int<60 then
        begin
          ShowMessage('Repeat interval must be greater than 60 seconds!');
          Exit;
        end;
    end;
  // ============================================

  new_task_id:=GetIDFromEventName(eTaskType.Text);
  id_part1:=GetFieldFromString(new_task_id,ParamLimiter,1);
  id_part2:=GetFieldFromString(new_task_id,ParamLimiter,2);
  id_part3:=GetFieldFromString(new_task_id,ParamLimiter,3);
  // individual for 1 ============================
  if id_part1='1' then
    begin
      isErr:=false;
      try
        int_prm1:=strtoint(uStrUtils.GetFieldFromString(eTargetIP.Text,'.',1));
        int_prm2:=strtoint(uStrUtils.GetFieldFromString(eTargetIP.Text,'.',2));
        int_prm3:=strtoint(uStrUtils.GetFieldFromString(eTargetIP.Text,'.',3));
      except
        isErr:=true;
      end;
      if isErr then
        begin
          ShowMessage('Invalid subnet!');
          Exit;
        end;
      try
        int_prm1:=strtoint(eAddParam.Text);
      except
        ShowMessage('Invalid ping timeout!');
        Exit;
      end;
      if int_prm1<100 then
        begin
          ShowMessage('Ping timeout too small!');
          Exit;
        end;
      if int_prm1>5000 then
        begin
          ShowMessage('Ping timeout too big!');
          Exit;
        end;
    end;
  // =============================================
  // individual for 2 ============================
  if id_part1='2' then
    begin
      // report
      if cbReportMode.ItemIndex<0 then
        begin
          ShowMessage('Appearance in report not selected!');
          Exit;
        end;
      // execution
      if trim(eBatch.Text)='' then
        begin
          ShowMessage('Batch for execution not selected!');
          Exit;
        end;
    end;
  // individual for 3 ============================
  if id_part1='3' then
    begin
      if not (cbReportOptions11.Checked or cbReportOptions12.Checked or
              cbReportOptions211.Checked or cbReportOptions212.Checked or
              cbReportOptions22.Checked) then
        begin
          ShowMessage('Select report options, please!');
          Exit;
        end;
      if trim(eEMailSender.Text)='' then
        begin
          ShowMessage('Invalid sender e-mail!');
          Exit;
        end;
      if not ValidSymbols(eEMailSender.Text) then
        begin
          ShowMessage('Invalid symbols in sender e-mail!');
          Exit;
        end;
      if trim(eEMailSendTo.Text)='' then
        begin
          ShowMessage('Invalid "send to" e-mail!');
          Exit;
        end;
      if not ValidSymbols(eEMailSendTo.Text) then
        begin
          ShowMessage('Invalid symbols in "send to" e-mail!');
          Exit;
        end;
      if trim(eEMailSMTPServer.Text)='' then
        begin
          ShowMessage('Invalid SMTP server!');
          Exit;
        end;
      if not ValidSymbols(eEMailSMTPServer.Text) then
        begin
          ShowMessage('Invalid symbols in SMTP server!');
          Exit;
        end;
      try
        tmp_int:=strtoint(eEMailSMTPPort.Text);
      except
        ShowMessage('Invalid SMTP port!');
        Exit;
      end;
      if trim(eEMailLogin.Text)='' then
        begin
          ShowMessage('Invalid login!');
          Exit;
        end;
      if not ValidSymbols(eEMailLogin.Text) then
        begin
          ShowMessage('Invalid symbols in login!');
          Exit;
        end;
      if not ValidSymbols(eEMailPassword.Text) then
        begin
          ShowMessage('Invalid symbols in password!');
          Exit;
        end;
      if not ValidSymbols(eEMailSubject.Text) then
        begin
          ShowMessage('Invalid symbols in e-mail subject!');
          Exit;
        end;
    end;
  // ============================================
  // individual for 4 ============================
  if id_part1='4' then
    begin
      if trim(eTargetIP.Text)='' then
        begin
          ShowMessage('Empty target IP or host name!');
          Exit;
        end;
      // report and stat
      if cbReportMode.ItemIndex<0 then
        begin
          ShowMessage('Appearance in report not selected!');
          Exit;
        end;
      if cbReportMode.ItemIndex<>0 then // not never
        begin
          try
            tmp_int:=strtoint(eResultRepeatCount.Text);
          except
            ShowMessage('Invalid number of times for appearance in report condition satisfied!');
            Exit;
          end;
          if tmp_int<=0 then
            begin
              ShowMessage('Invalid number of times for appearance in report condition satisfied!');
              exit;
            end;
        end;
      if cbStatistics.Checked then
        begin
          if not ValidSymbols(eStatName.Text) then
            begin
              ShowMessage('Statistics marker contains invalid symbols!');
              Exit;
            end;
        end;
      // execution
      if cbExecutionCondition.ItemIndex<0 then
        begin
          ShowMessage('Execution condition not selected!');
          Exit;
        end;
      if cbExecutionCondition.ItemIndex<>0 then // not never
        begin
          try
            tmp_int:=strtoint(eResultRepeatCountForExecution.Text);
          except
            ShowMessage('Invalid number of times for execution condition satisfied!');
            Exit;
          end;
          if tmp_int<=0 then
            begin
              ShowMessage('Invalid number of times for execution condition satisfied!');
              exit;
            end;
          if trim(eBatch.Text)='' then
            begin
              ShowMessage('Batch for execution not selected!');
              Exit;
            end;
        end;
      // alarm
      if cbAlarmMode.ItemIndex<0 then
        begin
          ShowMessage('Execution condition not selected!');
          Exit;
        end;
      if cbAlarmMode.ItemIndex<>0 then // not never
        begin
          try
            tmp_int:=strtoint(eResultRepeatCountForAlarm.Text);
          except
            ShowMessage('Invalid number of times for alarm condition satisfied!');
            Exit;
          end;
          if tmp_int<=0 then
            begin
              ShowMessage('Invalid number of times for alarm condition satisfied!');
              exit;
            end;
          if trim(eAlarmTemplate.Text)='' then
            begin
              ShowMessage('Alarm template not selected!');
              Exit;
            end;
        end;
      // additional params
      if id_part3='2' then
        begin
          if trim(eAddParam.Text)='' then
            begin
              ShowMessage('Empty TCP port!');
              Exit;
            end;
          try
            int_prm1:=strtoint(eAddParam.Text);
          except
            ShowMessage('Invalid TCP port!');
            Exit;
          end;
        end;
      if id_part3='8' then
        begin
          if trim(eAddParam.Text)='' then
            begin
              ShowMessage('Empty TCP port!');
              Exit;
            end;
          try
            int_prm1:=strtoint(eAddParam.Text);
          except
            ShowMessage('Invalid TCP port!');
            Exit;
          end;
        end;
      if id_part3='5' then
        begin
          if trim(eAddParam.Text)='' then
            begin
              ShowMessage('Empty HTTP header!');
              Exit;
            end;
        end;
    end;
  // =============================================

  // return result ===============================
  res.er_event.event_name:=trim(eTaskName.Text);
  res.er_event.ev_days_of_month:=mdString;
  res.er_event.ev_days_of_week:=mwString;
  res.er_event.event_execution_str:='';
  if id_part1='4' then
    begin
      if cbExecutionCondition.ItemIndex=0 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'0'+ParamLimiter;
        end;
      if cbExecutionCondition.ItemIndex=1 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'1/1'+ParamLimiter;
        end;
      if cbExecutionCondition.ItemIndex=3 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'1/2'+ParamLimiter;
        end;
      if cbExecutionCondition.ItemIndex=2 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'1/3'+ParamLimiter;
        end;
      if cbExecutionCondition.ItemIndex=5 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'1/4'+ParamLimiter;
        end;
      if cbExecutionCondition.ItemIndex=4 then
        begin
          res.er_event.event_execution_str:=res.er_event.event_execution_str+'1/5'+ParamLimiter;
        end;
       res.er_event.event_execution_str:=res.er_event.event_execution_str+trim(eResultRepeatCountForExecution.Text)+ParamLimiter;
       res.er_event.event_execution_str:=res.er_event.event_execution_str+trim(eBatch.Text)+ParamLimiter;
    end;
  res.er_event.event_alarm_str:='';
  res.er_event.event_main_param:='';
  if id_part1='1' then
    begin
      res.er_event.event_main_param:=trim(eTargetIP.Text);
    end;
  if id_part1='3' then
    begin
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailSender.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailSendTo.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailSMTPServer.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailSMTPPort.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailLogin.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailPassword.Text)+ParamLimiter;
      res.er_event.event_main_param:=res.er_event.event_main_param+trim(eEMailSubject.Text)+ParamLimiter;
    end;
  if id_part1='4' then
    begin
      res.er_event.event_main_param:=trim(eTargetIP.Text);
    end;
  res.er_event.ev_repeat_type:=1;
  res.er_event.ev_repeat_interval:=0;
  if cbRepeatType.Checked then
    begin
      res.er_event.ev_repeat_type:=2;
      res.er_event.ev_repeat_interval:=strtoint(eRepeatInterval.Text);
    end;
  res.er_event.ev_time_h:=strtoint(eTimeH.Text);
  res.er_event.ev_time_m:=strtoint(eTimeM.Text);
  res.er_event.ev_time_s:=strtoint(eTimeS.Text);
  res.er_event.ev_end_time_h:=strtoint(eEndTimeH.Text);
  res.er_event.ev_end_time_m:=strtoint(eEndTimeM.Text);
  res.er_event.ev_end_time_s:=strtoint(eEndTimeS.Text);

  res.er_event.event_str:=new_task_id;
  if id_part1='1' then
    begin
      res.er_event.event_str:=res.er_event.event_str+ParamLimiter+trim(eAddParam.Text);
    end;
  if id_part1='2' then
    begin
      if cbReportMode.ItemIndex=1 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'0';
        end;
      res.er_event.event_str:=res.er_event.event_str+ParamLimiter+trim(eBatch.Text);
    end;
  if id_part1='3' then
    begin
      res.er_event.event_str:=res.er_event.event_str+ParamLimiter;
      if cbReportOptions11.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+'1/';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+'0/';
        end;
      if cbReportOptions12.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+'1/';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+'0/';
        end;
      if cbReportOptions22.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+'1/';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+'0/';
        end;
      if cbReportOptions211.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+'1/';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+'0/';
        end;
      if cbReportOptions212.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+'1';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+'0';
        end;
    end;
  if id_part1='4' then
    begin
      if cbReportMode.ItemIndex=0 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'0';
        end;
      if cbReportMode.ItemIndex=1 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1/1';
        end;
      if cbReportMode.ItemIndex=3 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1/2';
        end;
      if cbReportMode.ItemIndex=2 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1/3';
        end;
      if cbReportMode.ItemIndex=5 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1/4';
        end;
      if cbReportMode.ItemIndex=4 then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1/5';
        end;
      res.er_event.event_str:=res.er_event.event_str+ParamLimiter+trim(eResultRepeatCount.Text);

      if cbStatistics.Checked then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'1';
        end
        else
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+'0';
        end;

      res.er_event.event_str:=res.er_event.event_str+ParamLimiter+trim(eStatName.Text);

      if (id_part3='2') or (id_part3='5') or (id_part3='8') then
        begin
          res.er_event.event_str:=res.er_event.event_str+ParamLimiter+trim(eAddParam.Text);
        end;

      // event_alarm_str
      res.er_event.event_alarm_str:='';
      if cbShowStatusInAI.Checked then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+'1';
        end
        else
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+'0';
        end;
      if cbAlarmMode.ItemIndex=0 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'0';
        end;
      if cbAlarmMode.ItemIndex=1 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'1/1';
        end;
      if cbAlarmMode.ItemIndex=3 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'1/2';
        end;
      if cbAlarmMode.ItemIndex=2 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'1/3';
        end;
      if cbAlarmMode.ItemIndex=5 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'1/4';
        end;
      if cbAlarmMode.ItemIndex=4 then
        begin
          res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+'1/5';
        end;
      res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+trim(eResultRepeatCountForAlarm.Text);
      res.er_event.event_alarm_str:=res.er_event.event_alarm_str+ParamLimiter+trim(eAlarmTemplate.Text);
    end;
  // =============================================

  res.res:=true;
  Close;
end;

procedure TfEditEvent.bSelectAlarmTemplateClick(Sender: TObject);
var
  rs:string;
begin
  rs:=uAlarmTemplateEditor.SelectAlarmTemplate(fEditEvent.eAlarmTemplate.Text);
  if rs<>'' then
    begin
      fEditEvent.eAlarmTemplate.text:=rs;
    end;
end;

procedure TfEditEvent.bSelectBatchClick(Sender: TObject);
var
  rs:string;
begin
  rs:=uBchEditor.SelectBatch(fEditEvent.eBatch.Text);
  if rs<>'' then
    begin
      fEditEvent.eBatch.text:=rs;
    end;
end;

procedure TfEditEvent.bSelectTaskTypeClick(Sender: TObject);
var
  rs:string;
begin
  rs:=uSelectEventType.SelectEventType(uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text));
  if rs<>'' then
    begin
      fEditEvent.eTaskType.Text:=uEventClassifier.GetEventNameFromID(rs);
      OnTaskTypeEdit;
    end;
end;

procedure TfEditEvent.bSetTo000000Click(Sender: TObject);
begin
  fEditEvent.eTimeH.Text:='0';
  fEditEvent.eTimeM.Text:='0';
  fEditEvent.eTimeS.Text:='0';
end;

procedure TfEditEvent.bSetTo235959Click(Sender: TObject);
begin
  fEditEvent.eEndTimeH.Text:='23';
  fEditEvent.eEndTimeM.Text:='59';
  fEditEvent.eEndTimeS.Text:='59';
end;

procedure TfEditEvent.bTargetIPSelectClick(Sender: TObject);
var
  task_id:string;
  sel:string;
begin
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  if leftstr(task_id,1)='1' then
    begin
      sel:=uSelectSubnet.SelectSubnet(eTargetIP.Text);
      if sel<>'' then
        begin
          eTargetIP.Text:=sel;
        end;
    end;
end;

procedure TfEditEvent.cbAlarmModeChange(Sender: TObject);
begin
  OnAlarmConditionChange;
end;

procedure TfEditEvent.cbExecutionConditionChange(Sender: TObject);
begin
  OnExecutonConditionChange;
end;

procedure TfEditEvent.cbRepeatTypeChange(Sender: TObject);
begin
  OnRepeatTypeEdit;
end;

procedure TfEditEvent.cbReportModeChange(Sender: TObject);
begin
  OnReportModeChange;
end;

procedure TfEditEvent.cbStatisticsChange(Sender: TObject);
begin
  OnStatModeChange;
end;

procedure OnReportModeChange;
begin
  if fEditEvent.cbReportMode.ItemIndex>=2 then
    begin
      fEditEvent.Label8.Visible:=true;
      fEditEvent.eResultRepeatCount.Visible:=true;
      fEditEvent.Label9.Visible:=true;
    end
    else
    begin
      fEditEvent.Label8.Visible:=false;
      fEditEvent.eResultRepeatCount.Visible:=false;
      fEditEvent.Label9.Visible:=false;
    end;
end;

procedure OnExecutonConditionChange;
var
  task_id:string;
begin
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  if leftstr(task_id,1)='4' then
    begin
      if fEditEvent.cbExecutionCondition.ItemIndex>=2 then
        begin
          fEditEvent.Label11.Visible:=true;
          fEditEvent.eResultRepeatCountForExecution.Visible:=true;
          fEditEvent.Label12.Visible:=true;
        end
        else
        begin
          fEditEvent.Label11.Visible:=false;
          fEditEvent.eResultRepeatCountForExecution.Visible:=false;
          fEditEvent.Label12.Visible:=false;
        end;
      if fEditEvent.cbExecutionCondition.ItemIndex>=1 then
        begin
          fEditEvent.eBatch.Enabled:=true;
          fEditEvent.bSelectBatch.Enabled:=true;
        end
        else
        begin
          fEditEvent.eBatch.Enabled:=false;
          fEditEvent.bSelectBatch.Enabled:=false;
       end;
    end;
  if leftstr(task_id,1)='2' then
    begin
      fEditEvent.eBatch.Enabled:=true;
      fEditEvent.bSelectBatch.Enabled:=true;
    end;
end;

procedure OnAlarmConditionChange;
var
  task_id:string;
begin
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  if leftstr(task_id,1)='4' then
    begin
      if fEditEvent.cbAlarmMode.ItemIndex>=2 then
        begin
          fEditEvent.Label19.Visible:=true;
          fEditEvent.eResultRepeatCountForAlarm.Visible:=true;
          fEditEvent.Label20.Visible:=true;
        end
        else
        begin
          fEditEvent.Label19.Visible:=false;
          fEditEvent.eResultRepeatCountForAlarm.Visible:=false;
          fEditEvent.Label20.Visible:=false;
        end;
      if fEditEvent.cbAlarmMode.ItemIndex>=1 then
        begin
          fEditEvent.eAlarmTemplate.Enabled:=true;
          fEditEvent.bSelectAlarmTemplate.Enabled:=true;
        end
        else
        begin
          fEditEvent.eAlarmTemplate.Enabled:=false;
          fEditEvent.bSelectAlarmTemplate.Enabled:=false;
       end;
    end;
end;

procedure TfEditEvent.bCancelClick(Sender: TObject);
begin
  close;
end;

procedure TfEditEvent.bAddParamSelectClick(Sender: TObject);
var
  task_id,task_id3:string;
  sel:string;
begin
  task_id:=uEventClassifier.GetIDFromEventName(fEditEvent.eTaskType.Text);
  if leftstr(task_id,1)='4' then
    begin
      task_id3:=GetFieldFromString(task_id,ParamLimiter,3);
      if task_id3='2' then
        begin
          sel:=uSelectPortNumber.SelectPort(eAddParam.Text);
          if sel<>'' then
            begin
              eAddParam.Text:=sel;
            end;
        end;
      if task_id3='5' then
        begin
          sel:=uSelectHTTPHeader.SelectHTTPHeader(eAddParam.Text);
          if sel<>'' then
            begin
              eAddParam.Text:=sel;
            end;
        end;
    end;
end;

procedure TfEditEvent.bDMAllOffClick(Sender: TObject);
begin
  fEditEvent.cbDM1.Checked:=false;
  fEditEvent.cbDM2.Checked:=false;
  fEditEvent.cbDM3.Checked:=false;
  fEditEvent.cbDM4.Checked:=false;
  fEditEvent.cbDM5.Checked:=false;
  fEditEvent.cbDM6.Checked:=false;
  fEditEvent.cbDM7.Checked:=false;
  fEditEvent.cbDM8.Checked:=false;
  fEditEvent.cbDM9.Checked:=false;
  fEditEvent.cbDM10.Checked:=false;
  fEditEvent.cbDM11.Checked:=false;
  fEditEvent.cbDM12.Checked:=false;
  fEditEvent.cbDM13.Checked:=false;
  fEditEvent.cbDM14.Checked:=false;
  fEditEvent.cbDM15.Checked:=false;
  fEditEvent.cbDM16.Checked:=false;
  fEditEvent.cbDM17.Checked:=false;
  fEditEvent.cbDM18.Checked:=false;
  fEditEvent.cbDM19.Checked:=false;
  fEditEvent.cbDM20.Checked:=false;
  fEditEvent.cbDM21.Checked:=false;
  fEditEvent.cbDM22.Checked:=false;
  fEditEvent.cbDM23.Checked:=false;
  fEditEvent.cbDM24.Checked:=false;
  fEditEvent.cbDM25.Checked:=false;
  fEditEvent.cbDM26.Checked:=false;
  fEditEvent.cbDM27.Checked:=false;
  fEditEvent.cbDM28.Checked:=false;
  fEditEvent.cbDM29.Checked:=false;
  fEditEvent.cbDM30.Checked:=false;
  fEditEvent.cbDM31.Checked:=false;
end;

procedure TfEditEvent.bDMAllOnClick(Sender: TObject);
begin
  fEditEvent.cbDM1.Checked:=true;
  fEditEvent.cbDM2.Checked:=true;
  fEditEvent.cbDM3.Checked:=true;
  fEditEvent.cbDM4.Checked:=true;
  fEditEvent.cbDM5.Checked:=true;
  fEditEvent.cbDM6.Checked:=true;
  fEditEvent.cbDM7.Checked:=true;
  fEditEvent.cbDM8.Checked:=true;
  fEditEvent.cbDM9.Checked:=true;
  fEditEvent.cbDM10.Checked:=true;
  fEditEvent.cbDM11.Checked:=true;
  fEditEvent.cbDM12.Checked:=true;
  fEditEvent.cbDM13.Checked:=true;
  fEditEvent.cbDM14.Checked:=true;
  fEditEvent.cbDM15.Checked:=true;
  fEditEvent.cbDM16.Checked:=true;
  fEditEvent.cbDM17.Checked:=true;
  fEditEvent.cbDM18.Checked:=true;
  fEditEvent.cbDM19.Checked:=true;
  fEditEvent.cbDM20.Checked:=true;
  fEditEvent.cbDM21.Checked:=true;
  fEditEvent.cbDM22.Checked:=true;
  fEditEvent.cbDM23.Checked:=true;
  fEditEvent.cbDM24.Checked:=true;
  fEditEvent.cbDM25.Checked:=true;
  fEditEvent.cbDM26.Checked:=true;
  fEditEvent.cbDM27.Checked:=true;
  fEditEvent.cbDM28.Checked:=true;
  fEditEvent.cbDM29.Checked:=true;
  fEditEvent.cbDM30.Checked:=true;
  fEditEvent.cbDM31.Checked:=true;
end;

procedure TfEditEvent.bDMInvertClick(Sender: TObject);
begin
  fEditEvent.cbDM1.Checked:=not fEditEvent.cbDM1.Checked;
  fEditEvent.cbDM2.Checked:=not fEditEvent.cbDM2.Checked;
  fEditEvent.cbDM3.Checked:=not fEditEvent.cbDM3.Checked;
  fEditEvent.cbDM4.Checked:=not fEditEvent.cbDM4.Checked;
  fEditEvent.cbDM5.Checked:=not fEditEvent.cbDM5.Checked;
  fEditEvent.cbDM6.Checked:=not fEditEvent.cbDM6.Checked;
  fEditEvent.cbDM7.Checked:=not fEditEvent.cbDM7.Checked;
  fEditEvent.cbDM8.Checked:=not fEditEvent.cbDM8.Checked;
  fEditEvent.cbDM9.Checked:=not fEditEvent.cbDM9.Checked;
  fEditEvent.cbDM10.Checked:=not fEditEvent.cbDM10.Checked;
  fEditEvent.cbDM11.Checked:=not fEditEvent.cbDM11.Checked;
  fEditEvent.cbDM12.Checked:=not fEditEvent.cbDM12.Checked;
  fEditEvent.cbDM13.Checked:=not fEditEvent.cbDM13.Checked;
  fEditEvent.cbDM14.Checked:=not fEditEvent.cbDM14.Checked;
  fEditEvent.cbDM15.Checked:=not fEditEvent.cbDM15.Checked;
  fEditEvent.cbDM16.Checked:=not fEditEvent.cbDM16.Checked;
  fEditEvent.cbDM17.Checked:=not fEditEvent.cbDM17.Checked;
  fEditEvent.cbDM18.Checked:=not fEditEvent.cbDM18.Checked;
  fEditEvent.cbDM19.Checked:=not fEditEvent.cbDM19.Checked;
  fEditEvent.cbDM20.Checked:=not fEditEvent.cbDM20.Checked;
  fEditEvent.cbDM21.Checked:=not fEditEvent.cbDM21.Checked;
  fEditEvent.cbDM22.Checked:=not fEditEvent.cbDM22.Checked;
  fEditEvent.cbDM23.Checked:=not fEditEvent.cbDM23.Checked;
  fEditEvent.cbDM24.Checked:=not fEditEvent.cbDM24.Checked;
  fEditEvent.cbDM25.Checked:=not fEditEvent.cbDM25.Checked;
  fEditEvent.cbDM26.Checked:=not fEditEvent.cbDM26.Checked;
  fEditEvent.cbDM27.Checked:=not fEditEvent.cbDM27.Checked;
  fEditEvent.cbDM28.Checked:=not fEditEvent.cbDM28.Checked;
  fEditEvent.cbDM29.Checked:=not fEditEvent.cbDM29.Checked;
  fEditEvent.cbDM30.Checked:=not fEditEvent.cbDM30.Checked;
  fEditEvent.cbDM31.Checked:=not fEditEvent.cbDM31.Checked;
end;

end.

