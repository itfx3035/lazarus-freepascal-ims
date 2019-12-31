unit uSchEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Menus, ComCtrls, uStrUtils, Math, uEditEvent, uCustomTypes,
  uEventClassifier, uBchEditor, uAlarmTemplateEditor;

type

  { TfSchEditor }

  TfSchEditor = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    pmiCopyTask: TMenuItem;
    miCopyTask: TMenuItem;
    pmiDelTask: TMenuItem;
    pmiEditTask: TMenuItem;
    pmiAddTask: TMenuItem;
    miDelTask: TMenuItem;
    miEditTask: TMenuItem;
    miAddTask: TMenuItem;
    miActions: TMenuItem;
    mmSch: TMainMenu;
    pmSch: TPopupMenu;
    sgSch: TStringGrid;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuItem1Click(Sender: TObject);
    procedure miAddTaskClick(Sender: TObject);
    procedure miCopyTaskClick(Sender: TObject);
    procedure miDelTaskClick(Sender: TObject);
    procedure miEditTaskClick(Sender: TObject);
    procedure pmiAddTaskClick(Sender: TObject);
    procedure pmiCopyTaskClick(Sender: TObject);
    procedure pmiDelTaskClick(Sender: TObject);
    procedure pmiEditTaskClick(Sender: TObject);
    procedure sgSchDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSchEditor: TfSchEditor;
  IsSchEditorRuning:boolean;
  COPYarrServerSch:array of TSchedulerEvent;

procedure StartSchEdit;
procedure RefreshList;

procedure AddEvent;
procedure EditEvent;
procedure CopyEvent;
procedure DelEvent;


function EventNameUsed(event_name,initial_event_name:string):boolean;

implementation

uses uMain;

{$R *.lfm}

{ TfSchEditor }


function EventNameUsed(event_name,initial_event_name:string):boolean;
var
  x:integer;
begin
  result:=false;
  if UPPERCASE(event_name)=UPPERCASE(initial_event_name) then
    begin
      exit;
    end;
  for x:=1 to length(COPYarrServerSch) do
    begin
      if UPPERCASE(event_name)=UPPERCASE(COPYarrServerSch[x-1].event_name) then
        begin
          result:=true;
          exit;
        end;
    end;
end;


procedure TfSchEditor.miAddTaskClick(Sender: TObject);
begin
  AddEvent;
end;

procedure TfSchEditor.miCopyTaskClick(Sender: TObject);
begin
  CopyEvent;
end;

procedure TfSchEditor.miDelTaskClick(Sender: TObject);
begin
  DelEvent;
end;

procedure TfSchEditor.miEditTaskClick(Sender: TObject);
begin
  EditEvent;
end;

procedure TfSchEditor.pmiAddTaskClick(Sender: TObject);
begin
  AddEvent;
end;

procedure TfSchEditor.pmiCopyTaskClick(Sender: TObject);
begin
  CopyEvent;
end;

procedure TfSchEditor.pmiDelTaskClick(Sender: TObject);
begin
  DelEvent;
end;

procedure TfSchEditor.pmiEditTaskClick(Sender: TObject);
begin
  EditEvent;
end;

procedure TfSchEditor.sgSchDblClick(Sender: TObject);
begin
  EditEvent;
end;

procedure StartSchEdit;
var
  x:integer;
begin
  if IsSchEditorRuning then
    begin
      fSchEditor.SetFocus;
    end
    else
    begin
      Setlength(COPYarrServerSch,length(uMain.arrServerSch));
      for x:=1 to length(uMain.arrServerSch) do
        begin
          COPYarrServerSch[x-1]:=uMain.arrServerSch[x-1];
        end;
      Setlength(COPYarrServerBatchList,length(uMain.arrServerBatchList));
      for x:=1 to length(uMain.arrServerBatchList) do
        begin
          COPYarrServerBatchList[x-1]:=uMain.arrServerBatchList[x-1];
        end;

      Application.CreateForm(TfSchEditor, fSchEditor);
      RefreshList;
      IsSchEditorRuning:=true;
      fSchEditor.Show;
    end;
end;

procedure TfSchEditor.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  IsSchEditorRuning:=false;
  CloseAction:=caFree;
end;

procedure TfSchEditor.MenuItem1Click(Sender: TObject);
begin

end;

procedure TfSchEditor.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfSchEditor.bOKClick(Sender: TObject);
var
  x:integer;
begin
  Setlength(uMain.arrServerBatchList,length(uBchEditor.COPYarrServerBatchList));
  for x:=1 to length(uBchEditor.COPYarrServerBatchList) do
    begin
      uMain.arrServerBatchList[x-1]:=uBchEditor.COPYarrServerBatchList[x-1];
    end;
  Setlength(uMain.arrServerAlarmList,length(uAlarmTemplateEditor.COPYarrServerAlarmList));
  for x:=1 to length(uAlarmTemplateEditor.COPYarrServerAlarmList) do
    begin
      uMain.arrServerAlarmList[x-1]:=uAlarmTemplateEditor.COPYarrServerAlarmList[x-1];
    end;
  Setlength(uMain.arrServerSch,length(COPYarrServerSch));
  for x:=1 to length(COPYarrServerSch) do
    begin
      uMain.arrServerSch[x-1]:=COPYarrServerSch[x-1];
    end;

  WaitSocketForOp(6); // save schedule and batch list to server
  close;
end;

procedure RefreshList;
var
  x,l,r:integer;
  event_type_text:string;
begin
  r:=fSchEditor.sgSch.Row;
  l:=length(COPYarrServerSch);
  fSchEditor.sgSch.RowCount:=max(l+1,2);
  if l=0 then
    begin
      fSchEditor.sgSch.Cells[0,1]:='';
      fSchEditor.sgSch.Cells[1,1]:='';
    end;
  for x:=1 to l do
    begin
      event_type_text:=uEventClassifier.GetEventNameFromID(uEventClassifier.GetEventTypePart(COPYarrServerSch[x-1].event_str));
      fSchEditor.sgSch.Cells[0,x]:=COPYarrServerSch[x-1].event_name;
      fSchEditor.sgSch.Cells[1,x]:=event_type_text;
    end;
  fSchEditor.sgSch.Row:=r;
end;

procedure EditEvent;
var
  r:integer;
  e_res:TEventResult;
begin
  r:=fSchEditor.sgSch.Row;
  if r<1 then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  if r>Length(COPYarrServerSch) then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  e_res:=uEditEvent.EditEvent(COPYarrServerSch[r-1]);
  if e_res.res then
    begin
      COPYarrServerSch[r-1]:=e_res.er_event;
      RefreshList;
    end;
end;

procedure CopyEvent;
var
  r:integer;
  e_res:TEventResult;
  e:TSchedulerEvent;
begin
  r:=fSchEditor.sgSch.Row;
  if r<1 then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  if r>Length(COPYarrServerSch) then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  e:=COPYarrServerSch[r-1];
  e.event_name:='';
  e_res:=uEditEvent.EditEvent(e);
  if e_res.res then
    begin
      setlength(COPYarrServerSch,length(COPYarrServerSch)+1);
      COPYarrServerSch[length(COPYarrServerSch)-1]:=e_res.er_event;
      RefreshList;
    end;
end;

procedure AddEvent;
var
  e_res:TEventResult;
  e_src:TSchedulerEvent;
begin
  e_src.event_alarm_str:='';
  e_src.event_execution_str:='0'+ParamLimiter+'0'+ParamLimiter+'';
  e_src.event_main_param:='';
  e_src.event_name:='';
  e_src.event_str:='4'+ParamLimiter+'1'+ParamLimiter+'1'+ParamLimiter+
                   '1/1'+ParamLimiter+'0'+ParamLimiter+'0'+ParamLimiter+''+ParamLimiter;
  e_src.ev_days_of_month:='01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,';
  e_src.ev_days_of_week:='1,2,3,4,5,6,7';
  e_src.ev_end_time_h:=23;
  e_src.ev_end_time_m:=59;
  e_src.ev_end_time_s:=59;
  e_src.ev_time_h:=0;
  e_src.ev_time_m:=0;
  e_src.ev_time_s:=0;
  e_src.ev_repeat_interval:=3600;
  e_src.ev_repeat_type:=1;


  e_res:=uEditEvent.EditEvent(e_src);
  if e_res.res then
    begin
      setlength(COPYarrServerSch,length(COPYarrServerSch)+1);
      COPYarrServerSch[length(COPYarrServerSch)-1]:=e_res.er_event;
      RefreshList;
    end;
end;

procedure DelEvent;
var
  r:integer;
  x:integer;
begin
  r:=fSchEditor.sgSch.Row;
  if r<1 then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  if r>Length(COPYarrServerSch) then
    begin
      ShowMessage('Select task first!');
      exit;
    end;
  if MessageDlg('Are you sure?','Delete task '+COPYarrServerSch[r-1].event_name+'?',mtConfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      for x:=r to Length(COPYarrServerSch)-1 do
        begin
          COPYarrServerSch[x-1]:=COPYarrServerSch[x];
        end;
      SetLength(COPYarrServerSch,Length(COPYarrServerSch)-1);
      RefreshList;
    end;
end;

end.

