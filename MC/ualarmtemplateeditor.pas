unit uAlarmTemplateEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Menus, uCustomTypes, Math, uEditAlarmTemplate, uStrUtils;

type

  { TfAlarmTemplateEditor }

  TfAlarmTemplateEditor = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    pmiCopyTemplate: TMenuItem;
    miCopyTemplate: TMenuItem;
    miActions: TMenuItem;
    miAddTemplate: TMenuItem;
    miDeleteTemplate: TMenuItem;
    miEditTemplate: TMenuItem;
    mmAlarmTemplateEditor: TMainMenu;
    pmAlarmTemplateEditor: TPopupMenu;
    pmiAddTemplate: TMenuItem;
    pmiDelTemplate: TMenuItem;
    pmiEditTemplate: TMenuItem;
    sgAlarms: TStringGrid;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure miAddTemplateClick(Sender: TObject);
    procedure miCopyTemplateClick(Sender: TObject);
    procedure miDeleteTemplateClick(Sender: TObject);
    procedure miEditTemplateClick(Sender: TObject);
    procedure pmiAddTemplateClick(Sender: TObject);
    procedure pmiCopyTemplateClick(Sender: TObject);
    procedure pmiDelTemplateClick(Sender: TObject);
    procedure pmiEditTemplateClick(Sender: TObject);
    procedure sgAlarmsDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fAlarmTemplateEditor: TfAlarmTemplateEditor;
  COPYarrServerAlarmList:array of uCustomTypes.TAlarmTemplate;
  res:string;
  isSelectMode:boolean;


function SelectAlarmTemplate(alarm_template_name:string):string;
procedure StartAlarmTemplateEdit;
procedure RefreshList;
procedure AddA;
procedure EditA;
procedure CopyA;
procedure DelA;
function AlarmUsedInEvent(alarm:TAlarmTemplate):boolean;
function AlarmNameUsed(alarm_name,initial_alarm_name:string):boolean;

implementation
uses uMain, uSchEditor;
{$R *.lfm}

{ TfAlarmTemplateEditor }

function SelectAlarmTemplate(alarm_template_name:string):string;
var
  x:integer;
begin
  isSelectMode:=true;

  Setlength(COPYarrServerAlarmList,length(uMain.arrServerAlarmList));
  for x:=1 to length(uMain.arrServerAlarmList) do
    begin
      COPYarrServerAlarmList[x-1]:=uMain.arrServerAlarmList[x-1];
    end;

  Application.CreateForm(TfAlarmTemplateEditor, fAlarmTemplateEditor);
  RefreshList;

  // find alarm template name
  for x:=1 to length(COPYarrServerAlarmList) do
    begin
      if UpperCase(alarm_template_name)=UpperCase(COPYarrServerAlarmList[x-1].alarm_template_name) then
        begin
          fAlarmTemplateEditor.sgAlarms.Row:=x;
        end;
    end;

  fAlarmTemplateEditor.bOK.Caption:='Select';
  fAlarmTemplateEditor.ShowModal;
  Result:=res;
end;


procedure StartAlarmTemplateEdit;
var
  x:integer;
begin
  isSelectMode:=false;

  Setlength(COPYarrServerAlarmList,length(uMain.arrServerAlarmList));
  for x:=1 to length(uMain.arrServerAlarmList) do
    begin
      COPYarrServerAlarmList[x-1]:=uMain.arrServerAlarmList[x-1];
    end;

  Application.CreateForm(TfAlarmTemplateEditor, fAlarmTemplateEditor);
  RefreshList;

  fAlarmTemplateEditor.ShowModal;
end;

procedure RefreshList;
var
  x,l,r:integer;
begin
  r:=fAlarmTemplateEditor.sgAlarms.Row;
  l:=length(COPYarrServerAlarmList);
  fAlarmTemplateEditor.sgAlarms.RowCount:=max(l+1,2);
  if l=0 then
    begin
      fAlarmTemplateEditor.sgAlarms.Cells[0,1]:='';
    end;
  for x:=1 to l do
    begin
      fAlarmTemplateEditor.sgAlarms.Cells[0,x]:=COPYarrServerAlarmList[x-1].alarm_template_name;
    end;
  fAlarmTemplateEditor.sgAlarms.Row:=r;
end;

procedure TfAlarmTemplateEditor.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfAlarmTemplateEditor.miAddTemplateClick(Sender: TObject);
begin
  AddA;
end;

procedure TfAlarmTemplateEditor.miCopyTemplateClick(Sender: TObject);
begin
  CopyA;
end;

procedure TfAlarmTemplateEditor.miDeleteTemplateClick(Sender: TObject);
begin
  DelA;
end;

procedure TfAlarmTemplateEditor.bOKClick(Sender: TObject);
var
  x,r:integer;
begin
  if isSelectMode then
    begin
      r:=fAlarmTemplateEditor.sgAlarms.Row;
      if r<1 then
        begin
          ShowMessage('Select alarm template first!');
          exit;
        end;
      if r>Length(COPYarrServerAlarmList) then
        begin
          ShowMessage('Select alarm template first!');
          exit;
        end;

      Setlength(uMain.arrServerAlarmList,length(COPYarrServerAlarmList));
      for x:=1 to length(COPYarrServerAlarmList) do
        begin
          uMain.arrServerAlarmList[x-1]:=COPYarrServerAlarmList[x-1];
        end;

      res:=COPYarrServerAlarmList[r-1].alarm_template_name;
      close;
    end
    else
    begin
      Setlength(uMain.arrServerAlarmList,length(COPYarrServerAlarmList));
      for x:=1 to length(COPYarrServerAlarmList) do
        begin
          uMain.arrServerAlarmList[x-1]:=COPYarrServerAlarmList[x-1];
        end;

      WaitSocketForOp(7); // save alarm list to server
      close;
    end;
end;

procedure TfAlarmTemplateEditor.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfAlarmTemplateEditor.miEditTemplateClick(Sender: TObject);
begin
  EditA;
end;

procedure TfAlarmTemplateEditor.pmiAddTemplateClick(Sender: TObject);
begin
  AddA;
end;

procedure TfAlarmTemplateEditor.pmiCopyTemplateClick(Sender: TObject);
begin
  CopyA;
end;

procedure TfAlarmTemplateEditor.pmiDelTemplateClick(Sender: TObject);
begin
  DelA;
end;

procedure TfAlarmTemplateEditor.pmiEditTemplateClick(Sender: TObject);
begin
  EditA;
end;

procedure TfAlarmTemplateEditor.sgAlarmsDblClick(Sender: TObject);
begin
  if isSelectMode then
    begin
      bOK.Click;
    end
    else
    begin
      EditA;
    end;
end;

procedure EditA;
var
  r:integer;
  atr:uCustomTypes.TAlarmTemplateResult;
begin
  r:=fAlarmTemplateEditor.sgAlarms.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  if r>Length(COPYarrServerAlarmList) then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  atr:=uEditAlarmTemplate.EditAlarmTemplate(COPYarrServerAlarmList[r-1],AlarmUsedInEvent(COPYarrServerAlarmList[r-1]));
  if atr.res then
    begin
      COPYarrServerAlarmList[r-1]:=atr.atr_alarm_template;
      RefreshList;
    end;
end;

procedure CopyA;
var
  r:integer;
  atr:uCustomTypes.TAlarmTemplateResult;
  a:uCustomTypes.TAlarmTemplate;
begin
  r:=fAlarmTemplateEditor.sgAlarms.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  if r>Length(COPYarrServerAlarmList) then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  a:=COPYarrServerAlarmList[r-1];
  a.alarm_template_name:='';
  atr:=uEditAlarmTemplate.EditAlarmTemplate(a,false);
  if atr.res then
    begin
      SetLength(COPYarrServerAlarmList,Length(COPYarrServerAlarmList)+1);
      COPYarrServerAlarmList[Length(COPYarrServerAlarmList)-1]:=atr.atr_alarm_template;
      RefreshList;
    end;
end;

function AlarmUsedInEvent(alarm:TAlarmTemplate):boolean;
var
  x,l:integer;
  tmp_bn:string;
begin
  result:=false;
  if isSelectMode then
    begin
      l:=length(uSchEditor.COPYarrServerSch);
      for x:=1 to l do
        begin
          tmp_bn:=uStrUtils.GetFieldFromString(uSchEditor.COPYarrServerSch[x-1].event_alarm_str,ParamLimiter,4);
          if UpperCase(tmp_bn)=UpperCase(alarm.alarm_template_name) then
            begin
              result:=true;
              exit;
            end;
        end;
    end
    else
    begin
      l:=length(arrServerSch);
      for x:=1 to l do
        begin
          tmp_bn:=uStrUtils.GetFieldFromString(arrServerSch[x-1].event_alarm_str,ParamLimiter,4);
          if UpperCase(tmp_bn)=UpperCase(alarm.alarm_template_name) then
            begin
              result:=true;
              exit;
            end;
        end;
    end;
end;

function AlarmNameUsed(alarm_name,initial_alarm_name:string):boolean;
var
  x:integer;
begin
  result:=false;
  if UPPERCASE(alarm_name)=UPPERCASE(initial_alarm_name) then
    begin
      exit;
    end;
  for x:=1 to length(COPYarrServerAlarmList) do
    begin
      if UPPERCASE(alarm_name)=UPPERCASE(COPYarrServerAlarmList[x-1].alarm_template_name) then
        begin
          result:=true;
          exit;
        end;
    end;
end;

procedure AddA;
var
  atl:uCustomTypes.TAlarmTemplate;
  atr:uCustomTypes.TAlarmTemplateResult;
begin
  atl.alarm_template_name:='';
  atl.alarm_template_str:='0';
  atl.alarm_template_params:='';
  atr:=uEditAlarmTemplate.EditAlarmTemplate(atl,false);
  if atr.res then
    begin
      SetLength(COPYarrServerAlarmList,Length(COPYarrServerAlarmList)+1);
      COPYarrServerAlarmList[Length(COPYarrServerAlarmList)-1]:=atr.atr_alarm_template;
      RefreshList;
    end;
end;

procedure DelA;
var
  r:integer;
  x:integer;
begin
  r:=fAlarmTemplateEditor.sgAlarms.Row;
  if r<1 then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  if r>Length(COPYarrServerAlarmList) then
    begin
      ShowMessage('Select alarm template first!');
      exit;
    end;
  if AlarmUsedInEvent(COPYarrServerAlarmList[r-1]) then
    begin
      ShowMessage('Selected alarm template used in tasks!');
      exit;
    end;
  if MessageDlg('Are you sure?','Delete alarm template '+COPYarrServerAlarmList[r-1].alarm_template_name+'?',mtConfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      for x:=r to Length(COPYarrServerAlarmList)-1 do
        begin
          COPYarrServerAlarmList[x-1]:=COPYarrServerAlarmList[x];
        end;
      SetLength(COPYarrServerAlarmList,Length(COPYarrServerAlarmList)-1);
      RefreshList;
    end;
end;

end.

