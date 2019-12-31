unit uEditAlarmTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids, Menus, uCustomTypes,uEventClassifier, math, uStrUtils,
  uEditAlarmElement;

type

  { TfEditAlarmTemplate }

  TfEditAlarmTemplate = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    eATName: TEdit;
    Label1: TLabel;
    pmiCopyAlarmTask: TMenuItem;
    miCopyAlarmTask: TMenuItem;
    miActions: TMenuItem;
    miAddAlarmTask: TMenuItem;
    miDelAlarmTask: TMenuItem;
    miEditAlarmTask: TMenuItem;
    mmEditAlarmMenu: TMainMenu;
    pmEditBatchMenu: TPopupMenu;
    pmiAddAlarmTask: TMenuItem;
    pmiDelAlarmTask: TMenuItem;
    pmiEditAlarmTask: TMenuItem;
    sgATEdit: TStringGrid;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure miAddAlarmTaskClick(Sender: TObject);
    procedure miCopyAlarmTaskClick(Sender: TObject);
    procedure miDelAlarmTaskClick(Sender: TObject);
    procedure miEditAlarmTaskClick(Sender: TObject);
    procedure pmiAddAlarmTaskClick(Sender: TObject);
    procedure pmiCopyAlarmTaskClick(Sender: TObject);
    procedure pmiDelAlarmTaskClick(Sender: TObject);
    procedure pmiEditAlarmTaskClick(Sender: TObject);
    procedure sgATEditDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fEditAlarmTemplate: TfEditAlarmTemplate;
  DecodedAT: tDecodedAlarmTemplate;
  initATName:string;
  res: TAlarmTemplateResult;

function EditAlarmTemplate(in_atl:TAlarmTemplate;name_read_only:boolean):TAlarmTemplateResult;
function DecodeAlarmTemplate(altt:TAlarmTemplate):tDecodedAlarmTemplate;
function EncodeAlarmTemplate(a_name:string;tdatt:tDecodedAlarmTemplate):TAlarmTemplate;
procedure RefreshList;

procedure AddAlarmTemplateEl;
procedure CopyAlarmTemplateEl;
procedure EditAlarmTemplateEl;
procedure DelAlarmTemplateEl;

implementation
{$R *.lfm}
{ TfEditAlarmTemplate }
uses uAlarmTemplateEditor;

function EditAlarmTemplate(in_atl:TAlarmTemplate;name_read_only:boolean):TAlarmTemplateResult;
begin
  Application.CreateForm(TfEditAlarmTemplate, fEditAlarmTemplate);
  DecodedAT:=DecodeAlarmTemplate(in_atl);
  if length(DecodedAT)=1 then
    begin
      if DecodedAT[0].ate_param='err' then
        begin
          showmessage('Error decoding alarm template!');
          Setlength(DecodedAT,0);
        end;
    end;
  fEditAlarmTemplate.eATName.Text:=in_atl.alarm_template_name;
  if name_read_only then
    begin
      fEditAlarmTemplate.eATName.Enabled:=false;
    end;

  RefreshList;
  res.res:=false;

  initATName:=in_atl.alarm_template_name;

  fEditAlarmTemplate.ShowModal;

  result:=res;
end;

procedure RefreshList;
var
  x,l:integer;
begin
  l:=length(DecodedAT);
  fEditAlarmTemplate.sgATEdit.RowCount:=max(l+1,2);
  if l=0 then
    begin
      fEditAlarmTemplate.sgATEdit.Cells[0,1]:='';
    end;
  for x:=1 to l do
    begin
      fEditAlarmTemplate.sgATEdit.Cells[0,x]:=uEventClassifier.GetAlarmTypeStr(DecodedAT[x-1].ate_type,DecodedAT[x-1].ate_param);
    end;
end;

procedure TfEditAlarmTemplate.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfEditAlarmTemplate.bOKClick(Sender: TObject);
begin
  if length(DecodedAT)=0 then
    begin
      ShowMessage('Empty alarm template!');
      Exit;
    end;
  if trim(eATName.Text)='' then
    begin
      ShowMessage('Empty alarm template name!');
      Exit;
    end;
  if not ValidName(eATName.Text) then
    begin
      ShowMessage('Alarm template name contains invalid symbols!');
      Exit;
    end;
  if uAlarmTemplateEditor.AlarmNameUsed(trim(eATName.Text),initATName) then
    begin
      ShowMessage('Alarm template name "'+trim(eATName.Text)+'" already used!');
      Exit;
    end;

  res.atr_alarm_template:=EncodeAlarmTemplate(trim(eATName.Text),DecodedAT);
  res.res:=true;
  Close;
end;

procedure TfEditAlarmTemplate.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfEditAlarmTemplate.miAddAlarmTaskClick(Sender: TObject);
begin
  AddAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.miCopyAlarmTaskClick(Sender: TObject);
begin
  CopyAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.miDelAlarmTaskClick(Sender: TObject);
begin
  DelAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.miEditAlarmTaskClick(Sender: TObject);
begin
  EditAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.pmiAddAlarmTaskClick(Sender: TObject);
begin
  AddAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.pmiCopyAlarmTaskClick(Sender: TObject);
begin
  CopyAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.pmiDelAlarmTaskClick(Sender: TObject);
begin
  DelAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.pmiEditAlarmTaskClick(Sender: TObject);
begin
  EditAlarmTemplateEl;
end;

procedure TfEditAlarmTemplate.sgATEditDblClick(Sender: TObject);
begin
  EditAlarmTemplateEl;
end;

function DecodeAlarmTemplate(altt:TAlarmTemplate):tDecodedAlarmTemplate;
var
  count:integer;
  x:integer;
  tmp:string;
begin
  setlength(result,0);
  try
    count:=strtoint(uStrUtils.GetFieldFromString(altt.alarm_template_str, ParamLimiter, 1));
    setlength(result,count);
    for x:=1 to count do
      begin
        result[x-1].ate_param:=uStrUtils.GetFieldFromString(altt.alarm_template_params,ParamLimiter,x);
        result[x-1].ate_type:=strtoint(uStrUtils.GetFieldFromString(altt.alarm_template_str,ParamLimiter,x+1));
      end;
  except
    setlength(result,1);
    Result[0].ate_param:='err';
  end;
end;

function EncodeAlarmTemplate(a_name:string;tdatt:tDecodedAlarmTemplate):TAlarmTemplate;
var
  x,l:integer;
begin
  l:=Length(tdatt);
  Result.alarm_template_name:=a_name;
  Result.alarm_template_str:=inttostr(l)+ParamLimiter;
  Result.alarm_template_params:='';
  for x:=1 to l do
    begin
      Result.alarm_template_str:=Result.alarm_template_str+inttostr(tdatt[x-1].ate_type)+ParamLimiter;
      Result.alarm_template_params:=Result.alarm_template_params+tdatt[x-1].ate_param+ParamLimiter;
    end;
end;

procedure EditAlarmTemplateEl;
var
  r:integer;
  aer:TDecodedAlarmTemplateElementResult;
begin
  r:=fEditAlarmTemplate.sgATEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  if r>Length(DecodedAT) then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  aer:=uEditAlarmElement.EditAlarmElement(DecodedAT[r-1]);
  if aer.res then
    begin
      DecodedAT[r-1]:=aer.daer_alarm_element;
      RefreshList;
    end;
end;

procedure CopyAlarmTemplateEl;
var
  r:integer;
  aer:TDecodedAlarmTemplateElementResult;
begin
  r:=fEditAlarmTemplate.sgATEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  if r>Length(DecodedAT) then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  aer:=uEditAlarmElement.EditAlarmElement(DecodedAT[r-1]);
  if aer.res then
    begin
      SetLength(DecodedAT,length(DecodedAT)+1);
      DecodedAT[length(DecodedAT)-1]:=aer.daer_alarm_element;
      RefreshList;
    end;
end;

procedure AddAlarmTemplateEl;
var
  aer:TDecodedAlarmTemplateElementResult;
  dat:TDecodedAlarmTemplateElement;
begin
  dat.ate_type:=1;
  dat.ate_param:='';
  aer:=uEditAlarmElement.EditAlarmElement(dat);
  if aer.res then
    begin
      SetLength(DecodedAT,length(DecodedAT)+1);
      DecodedAT[length(DecodedAT)-1]:=aer.daer_alarm_element;
      RefreshList;
    end;
end;

procedure DelAlarmTemplateEl;
var
  r,x:integer;
begin
  r:=fEditAlarmTemplate.sgATEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  if r>Length(DecodedAT) then
    begin
      ShowMessage('Select alarm template element first!');
      exit;
    end;
  if MessageDlg('Are you sure?','Delete alarm?',mtConfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      for x:=r to Length(DecodedAT)-1 do
        begin
          DecodedAT[x-1]:=DecodedAT[x];
        end;
      SetLength(DecodedAT,Length(DecodedAT)-1);
      RefreshList;
    end;
end;

end.

