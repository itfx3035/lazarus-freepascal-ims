unit uBchEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, Menus,
  StdCtrls, math, uCustomTypes, uEditBatch, uStrUtils;

type

  { TfBchEditor }

  TfBchEditor = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    pmiCopyBatch: TMenuItem;
    miCopyBatch: TMenuItem;
    pmiDelBatch: TMenuItem;
    pmiEditBatch: TMenuItem;
    pmiAddBatch: TMenuItem;
    miDeleteBatch: TMenuItem;
    miEditBatch: TMenuItem;
    miAddBatch: TMenuItem;
    miActions: TMenuItem;
    mmBatchEditor: TMainMenu;
    pmBatchEditor: TPopupMenu;
    sgBch: TStringGrid;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure miAddBatchClick(Sender: TObject);
    procedure miCopyBatchClick(Sender: TObject);
    procedure miDeleteBatchClick(Sender: TObject);
    procedure miEditBatchClick(Sender: TObject);
    procedure pmiAddBatchClick(Sender: TObject);
    procedure pmiCopyBatchClick(Sender: TObject);
    procedure pmiDelBatchClick(Sender: TObject);
    procedure pmiEditBatchClick(Sender: TObject);
    procedure sgBchDblClick(Sender: TObject);
    procedure sgBchResize(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fBchEditor: TfBchEditor;
  COPYarrServerBatchList:array of TBatch;
  res:string;
  isSelectMode:boolean;

procedure StartBchEdit;
function SelectBatch(batch_name:string):string;

procedure RefreshList;
procedure EditB;
procedure CopyB;
procedure AddB;
procedure DelB;

function BatchUsedInEvent(batch:TBatch):boolean;
function BatchNameUsed(batch_name,initial_batch_name:string):boolean;


implementation

uses uMain, uSchEditor;

{$R *.lfm}

{ TfBchEditor }

procedure StartBchEdit;
var
  x:integer;
begin
  isSelectMode:=false;

  Setlength(COPYarrServerBatchList,length(uMain.arrServerBatchList));
  for x:=1 to length(uMain.arrServerBatchList) do
    begin
      COPYarrServerBatchList[x-1]:=uMain.arrServerBatchList[x-1];
    end;

  Application.CreateForm(TfBchEditor, fBchEditor);
  RefreshList;

  fBchEditor.ShowModal;
end;

function SelectBatch(batch_name:string):string;
var
  x:integer;
begin
  isSelectMode:=true;

  Setlength(COPYarrServerBatchList,length(uMain.arrServerBatchList));
  for x:=1 to length(uMain.arrServerBatchList) do
    begin
      COPYarrServerBatchList[x-1]:=uMain.arrServerBatchList[x-1];
    end;

  Application.CreateForm(TfBchEditor, fBchEditor);
  RefreshList;

  // find batch name
  for x:=1 to length(COPYarrServerBatchList) do
    begin
      if UpperCase(batch_name)=UpperCase(COPYarrServerBatchList[x-1].batch_name) then
        begin
          fBchEditor.sgBch.Row:=x;
        end;
    end;

  fBchEditor.bOK.Caption:='Select';
  fBchEditor.ShowModal;
  Result:=res;
end;

function BatchNameUsed(batch_name,initial_batch_name:string):boolean;
var
  x:integer;
begin
  result:=false;
  if UPPERCASE(batch_name)=UPPERCASE(initial_batch_name) then
    begin
      exit;
    end;
  for x:=1 to length(COPYarrServerBatchList) do
    begin
      if UPPERCASE(batch_name)=UPPERCASE(COPYarrServerBatchList[x-1].batch_name) then
        begin
          result:=true;
          exit;
        end;
    end;
end;

function BatchUsedInEvent(batch:TBatch):boolean;
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
          tmp_bn:=uStrUtils.GetFieldFromString(uSchEditor.COPYarrServerSch[x-1].event_execution_str,ParamLimiter,3);
          if UpperCase(tmp_bn)=UpperCase(batch.batch_name) then
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
          tmp_bn:=uStrUtils.GetFieldFromString(arrServerSch[x-1].event_execution_str,ParamLimiter,3);
          if UpperCase(tmp_bn)=UpperCase(batch.batch_name) then
            begin
              result:=true;
              exit;
            end;
        end;
    end;
end;

procedure TfBchEditor.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfBchEditor.miAddBatchClick(Sender: TObject);
begin
  AddB;
end;

procedure TfBchEditor.miCopyBatchClick(Sender: TObject);
begin
  CopyB;
end;

procedure TfBchEditor.miDeleteBatchClick(Sender: TObject);
begin
  DelB;
end;

procedure TfBchEditor.miEditBatchClick(Sender: TObject);
begin
  EditB;
end;

procedure TfBchEditor.pmiAddBatchClick(Sender: TObject);
begin
  AddB;
end;

procedure TfBchEditor.pmiCopyBatchClick(Sender: TObject);
begin
  CopyB;
end;

procedure TfBchEditor.pmiDelBatchClick(Sender: TObject);
begin
  DelB;
end;

procedure TfBchEditor.pmiEditBatchClick(Sender: TObject);
begin
  EditB;
end;

procedure TfBchEditor.sgBchDblClick(Sender: TObject);
begin
  if isSelectMode then
    begin
      bOK.Click;
    end
    else
    begin
      EditB;
    end;
end;

procedure TfBchEditor.sgBchResize(Sender: TObject);
begin
  sgBch.Columns.Items[0].Width:=sgBch.Width-(574-540);
end;

procedure TfBchEditor.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfBchEditor.bOKClick(Sender: TObject);
var
  x,r:integer;
begin
  if isSelectMode then
    begin
      r:=fBchEditor.sgBch.Row;
      if r<1 then
        begin
          ShowMessage('Select batch first!');
          exit;
        end;
      if r>Length(COPYarrServerBatchList) then
        begin
          ShowMessage('Select batch first!');
          exit;
        end;

      Setlength(uMain.arrServerBatchList,length(COPYarrServerBatchList));
      for x:=1 to length(COPYarrServerBatchList) do
        begin
          uMain.arrServerBatchList[x-1]:=COPYarrServerBatchList[x-1];
        end;

      res:=COPYarrServerBatchList[r-1].batch_name;
      close;
    end
    else
    begin
      Setlength(uMain.arrServerBatchList,length(COPYarrServerBatchList));
      for x:=1 to length(COPYarrServerBatchList) do
        begin
          uMain.arrServerBatchList[x-1]:=COPYarrServerBatchList[x-1];
        end;

      WaitSocketForOp(5); // save batch list to server
      close;
    end;
end;

procedure RefreshList;
var
  x,l,r:integer;
begin
  r:=fBchEditor.sgBch.Row;
  l:=length(COPYarrServerBatchList);
  fBchEditor.sgBch.RowCount:=max(l+1,2);
  if l=0 then
    begin
      fBchEditor.sgBch.Cells[0,1]:='';
    end;
  for x:=1 to l do
    begin
      fBchEditor.sgBch.Cells[0,x]:=COPYarrServerBatchList[x-1].batch_name;
    end;
  fBchEditor.sgBch.Row:=r;
end;

procedure EditB;
var
  r:integer;
  br:TBatchResult;
begin
  r:=fBchEditor.sgBch.Row;
  if r<1 then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  if r>Length(COPYarrServerBatchList) then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  br:=uEditBatch.EditBatch(COPYarrServerBatchList[r-1],BatchUsedInEvent(COPYarrServerBatchList[r-1]));
  if br.res then
    begin
      COPYarrServerBatchList[r-1]:=br.br_batch;
      RefreshList;
    end;
end;

procedure CopyB;
var
  r:integer;
  br:TBatchResult;
  b:TBatch;
begin
  r:=fBchEditor.sgBch.Row;
  if r<1 then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  if r>Length(COPYarrServerBatchList) then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  b:=COPYarrServerBatchList[r-1];
  b.batch_name:='';
  br:=uEditBatch.EditBatch(b,false);
  if br.res then
    begin
      SetLength(COPYarrServerBatchList,Length(COPYarrServerBatchList)+1);
      COPYarrServerBatchList[Length(COPYarrServerBatchList)-1]:=br.br_batch;
      RefreshList;
    end;
end;

procedure AddB;
var
  tmpBatch:tBatch;
  br:TBatchResult;
begin
  tmpBatch.batch_name:='';
  tmpBatch.batch_str:='0';
  tmpBatch.batch_params:='';
  br:=uEditBatch.EditBatch(tmpBatch,false);
  if br.res then
    begin
      SetLength(COPYarrServerBatchList,Length(COPYarrServerBatchList)+1);
      COPYarrServerBatchList[Length(COPYarrServerBatchList)-1]:=br.br_batch;
      RefreshList;
    end;
end;

procedure DelB;
var
  r:integer;
  x:integer;
begin
  r:=fBchEditor.sgBch.Row;
  if r<1 then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  if r>Length(COPYarrServerBatchList) then
    begin
      ShowMessage('Select batch first!');
      exit;
    end;
  if BatchUsedInEvent(COPYarrServerBatchList[r-1]) then
    begin
      ShowMessage('Selected batch used in tasks!');
      exit;
    end;
  if MessageDlg('Are you sure?','Delete batch '+COPYarrServerBatchList[r-1].batch_name+'?',mtConfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      for x:=r to Length(COPYarrServerBatchList)-1 do
        begin
          COPYarrServerBatchList[x-1]:=COPYarrServerBatchList[x];
        end;
      SetLength(COPYarrServerBatchList,Length(COPYarrServerBatchList)-1);
      RefreshList;
    end;
end;

end.

