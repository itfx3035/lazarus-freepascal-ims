unit uEditAlarmElement;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  uCustomTypes, uStrUtils;

type

  { TfEditAlarmElement }

  TfEditAlarmElement = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    cbAlarmType: TComboBox;
    eEMailLogin: TEdit;
    eEMailPassword: TEdit;
    eEMailSender: TEdit;
    eEMailSendTo: TEdit;
    eEMailSMTPPort: TEdit;
    eEMailSMTPServer: TEdit;
    eEMailSubject: TEdit;
    gbEMailSettings: TGroupBox;
    Label1: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label7: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure cbAlarmTypeChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fEditAlarmElement: TfEditAlarmElement;
  res:TDecodedAlarmTemplateElementResult;

procedure OnEditAlarmType;

function EditAlarmElement(in_el:TDecodedAlarmTemplateElement):TDecodedAlarmTemplateElementResult;

implementation

function EditAlarmElement(in_el:TDecodedAlarmTemplateElement):TDecodedAlarmTemplateElementResult;
begin
  Application.CreateForm(TfEditAlarmElement, fEditAlarmElement);
  res.res:=false;

  fEditAlarmElement.cbAlarmType.Items.Clear;
  fEditAlarmElement.cbAlarmType.Items.Add('Active alarm in information agent');
  fEditAlarmElement.cbAlarmType.Items.Add('Send e-mail');
  fEditAlarmElement.cbAlarmType.ItemIndex:=in_el.ate_type-1;

  OnEditAlarmType;
  if in_el.ate_type=2 then
  begin
    fEditAlarmElement.eEMailSender.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,1);
    fEditAlarmElement.eEMailSendTo.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,2);
    fEditAlarmElement.eEMailSMTPServer.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,3);
    fEditAlarmElement.eEMailSMTPPort.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,4);
    fEditAlarmElement.eEMailLogin.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,5);
    fEditAlarmElement.eEMailPassword.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,6);
    fEditAlarmElement.eEMailSubject.Text:=uStrUtils.GetFieldFromString(in_el.ate_param,ParamLimiter2,7);
  end;

  fEditAlarmElement.ShowModal;
  result:=res;
end;

{ TfEditAlarmElement }

procedure TfEditAlarmElement.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfEditAlarmElement.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfEditAlarmElement.bOKClick(Sender: TObject);
var
  tmp_int:integer;
begin
  if fEditAlarmElement.cbAlarmType.ItemIndex=0 then
  begin
    res.daer_alarm_element.ate_type:=1;
    res.daer_alarm_element.ate_param:='';
  end;
  if fEditAlarmElement.cbAlarmType.ItemIndex=1 then
  begin
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

    res.daer_alarm_element.ate_type:=2;
    res.daer_alarm_element.ate_param:='';
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailSender.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailSendTo.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailSMTPServer.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailSMTPPort.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailLogin.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailPassword.Text+ParamLimiter2;
    res.daer_alarm_element.ate_param:=res.daer_alarm_element.ate_param+fEditAlarmElement.eEMailSubject.Text;
  end;
  res.res:=true;
  Close;
end;

procedure TfEditAlarmElement.cbAlarmTypeChange(Sender: TObject);
begin
  OnEditAlarmType;
end;

procedure OnEditAlarmType;
begin
  if fEditAlarmElement.cbAlarmType.ItemIndex=0 then
  begin
    fEditAlarmElement.gbEMailSettings.Visible:=false;
  end;
  if fEditAlarmElement.cbAlarmType.ItemIndex=1 then
  begin
    fEditAlarmElement.gbEMailSettings.Visible:=true;
  end;
end;

{$R *.lfm}

end.

