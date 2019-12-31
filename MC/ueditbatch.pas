unit uEditBatch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, Menus, uCustomTypes, uStrUtils, math, uEditBatchElement;

type

  { TfBatchEdit }

  TfBatchEdit = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    eBatchName: TEdit;
    Label1: TLabel;
    pmiCopyBatchCommand: TMenuItem;
    miCopyBatchElement: TMenuItem;
    pmiDelBatchCommand: TMenuItem;
    pmiEditBatchCommand: TMenuItem;
    pmiAddBatchCommand: TMenuItem;
    miDelBatchCommand: TMenuItem;
    miEditBatchCommand: TMenuItem;
    miAddBatchElement: TMenuItem;
    miActions: TMenuItem;
    mmEditBatchMenu: TMainMenu;
    pmEditBatchMenu: TPopupMenu;
    sgBchEdit: TStringGrid;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure miAddBatchElementClick(Sender: TObject);
    procedure miCopyBatchElementClick(Sender: TObject);
    procedure miDelBatchCommandClick(Sender: TObject);
    procedure miEditBatchCommandClick(Sender: TObject);
    procedure pmiAddBatchCommandClick(Sender: TObject);
    procedure pmiCopyBatchCommandClick(Sender: TObject);
    procedure pmiDelBatchCommandClick(Sender: TObject);
    procedure pmiEditBatchCommandClick(Sender: TObject);
    procedure sgBchEditDblClick(Sender: TObject);
    procedure sgBchEditResize(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fBatchEdit: TfBatchEdit;
  DecodedBatch: TDecodedBatch;
  res: TBatchResult;
  initBatchName:string;

function EditBatch(in_bch:tBatch;name_read_only:boolean):TBatchResult;
function DecodeBatch(batch:tBatch):TDecodedBatch;
function EncodeBatch(b_name:string;dbatch:TDecodedBatch):TBatch;
procedure RefreshList;
procedure EditBatchEl;
procedure CopyBatchEl;
procedure AddBatchEl;
procedure DelBatchEl;



implementation
{$R *.lfm}

uses uBchEditor;

{ TfBatchEdit }



function EditBatch(in_bch:tBatch;name_read_only:boolean):TBatchResult;
begin
  Application.CreateForm(TfBatchEdit, fBatchEdit);
  DecodedBatch:=DecodeBatch(in_bch);
  if length(DecodedBatch)=1 then
    begin
      if DecodedBatch[0].be_param='err' then
        begin
          showmessage('Error decoding batch!');
          Setlength(DecodedBatch,0);
        end;
    end;
  fBatchEdit.eBatchName.Text:=in_bch.batch_name;
  if name_read_only then
    begin
      fBatchEdit.eBatchName.Enabled:=false;
    end;

  RefreshList;
  res.res:=false;

  initBatchName:=in_bch.batch_name;

  fBatchEdit.ShowModal;

  result:=res;
end;

function DecodeBatch(batch:TBatch):TDecodedBatch;
var
  count:integer;
  x:integer;
  tmp:string;
begin
  setlength(result,0);
  try
    count:=strtoint(uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, 1));
    setlength(result,count);
    for x:=1 to count do
      begin
        result[x-1].be_param:=uStrUtils.GetFieldFromString(batch.batch_params, ParamLimiter, x);
        // wait or not
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+2);
        if trim(tmp)='1' then
          begin
            result[x-1].be_wait:=true;
          end
          else
          begin
            result[x-1].be_wait:=false;
          end;
        // write log or not
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+3);
        if trim(tmp)='1' then
          begin
            result[x-1].be_write_log:=true;
          end
          else
          begin
            result[x-1].be_write_log:=false;
          end;
        // timeout
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+4);
        result[x-1].be_timeout:=strtoint(tmp);
      end;
  except
    setlength(result,1);
    Result[0].be_param:='err';
  end;
end;

function EncodeBatch(b_name:string;dbatch:TDecodedBatch):TBatch;
var
  x,l:integer;
begin
  l:=Length(dbatch);
  Result.batch_name:=b_name;
  Result.batch_str:=inttostr(l)+ParamLimiter;
  Result.batch_params:='';
  for x:=1 to l do
    begin
      if dbatch[x-1].be_wait then
        begin
          Result.batch_str:=Result.batch_str+'1'+ParamLimiter;
        end
        else
        begin
          Result.batch_str:=Result.batch_str+'0'+ParamLimiter;
        end;
      if dbatch[x-1].be_write_log then
        begin
          Result.batch_str:=Result.batch_str+'1'+ParamLimiter;
        end
        else
        begin
          Result.batch_str:=Result.batch_str+'0'+ParamLimiter;
        end;
      Result.batch_str:=Result.batch_str+inttostr(dbatch[x-1].be_timeout)+ParamLimiter;

      Result.batch_params:=Result.batch_params+dbatch[x-1].be_param+ParamLimiter;
    end;
end;

procedure RefreshList;
var
  x,l:integer;
begin
  l:=length(DecodedBatch);
  fBatchEdit.sgBchEdit.RowCount:=max(l+1,2);
  if l=0 then
    begin
      fBatchEdit.sgBchEdit.Cells[0,1]:='';
      fBatchEdit.sgBchEdit.Cells[1,1]:='';
      fBatchEdit.sgBchEdit.Cells[2,1]:='';
      fBatchEdit.sgBchEdit.Cells[3,1]:='';
    end;
  for x:=1 to l do
    begin
      fBatchEdit.sgBchEdit.Cells[0,x]:=DecodedBatch[x-1].be_param;
      if DecodedBatch[x-1].be_wait then
        begin
          fBatchEdit.sgBchEdit.Cells[1,x]:='Yes';
        end
        else
        begin
          fBatchEdit.sgBchEdit.Cells[1,x]:='';
        end;
      if DecodedBatch[x-1].be_write_log then
        begin
          fBatchEdit.sgBchEdit.Cells[2,x]:='Yes';
        end
        else
        begin
          fBatchEdit.sgBchEdit.Cells[2,x]:='';
        end;
      fBatchEdit.sgBchEdit.Cells[3,x]:=inttostr(DecodedBatch[x-1].be_timeout);
    end;
end;

procedure TfBatchEdit.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfBatchEdit.miAddBatchElementClick(Sender: TObject);
begin
  AddBatchEl;
end;

procedure TfBatchEdit.miCopyBatchElementClick(Sender: TObject);
begin
  CopyBatchEl;
end;

procedure TfBatchEdit.miDelBatchCommandClick(Sender: TObject);
begin
  DelBatchEl;
end;

procedure TfBatchEdit.miEditBatchCommandClick(Sender: TObject);
begin
  EditBatchEl;
end;

procedure TfBatchEdit.pmiAddBatchCommandClick(Sender: TObject);
begin
  AddBatchEl;
end;

procedure TfBatchEdit.pmiCopyBatchCommandClick(Sender: TObject);
begin
  CopyBatchEl;
end;

procedure TfBatchEdit.pmiDelBatchCommandClick(Sender: TObject);
begin
  DelBatchEl;
end;

procedure TfBatchEdit.pmiEditBatchCommandClick(Sender: TObject);
begin
  EditBatchEl;
end;

procedure TfBatchEdit.sgBchEditDblClick(Sender: TObject);
begin
  EditBatchEl;
end;

procedure TfBatchEdit.sgBchEditResize(Sender: TObject);
begin
  sgBchEdit.Columns.Items[0].Width:=sgBchEdit.Width-(561-300);
end;

procedure TfBatchEdit.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfBatchEdit.bOKClick(Sender: TObject);
begin
  if length(DecodedBatch)=0 then
    begin
      ShowMessage('Empty batch!');
      Exit;
    end;
  if trim(eBatchName.Text)='' then
    begin
      ShowMessage('Empty batch name!');
      Exit;
    end;
  if not ValidName(eBatchName.Text) then
    begin
      ShowMessage('Batch name contains invalid symbols!');
      Exit;
    end;
  if uBchEditor.BatchNameUsed(trim(eBatchName.Text),initBatchName) then
    begin
      ShowMessage('Batch name "'+trim(eBatchName.Text)+'" already used!');
      Exit;
    end;

  res.br_batch:=EncodeBatch(trim(eBatchName.Text),DecodedBatch);
  res.res:=true;
  Close;
end;

procedure EditBatchEl;
var
  r:integer;
  ber:TDecodedBatchElementResult;
begin
  r:=fBatchEdit.sgBchEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  if r>Length(DecodedBatch) then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  ber:=uEditBatchElement.EditBatchElement(DecodedBatch[r-1]);
  if ber.res then
    begin
      DecodedBatch[r-1]:=ber.dber_batch_element;
      RefreshList;
    end;
end;

procedure CopyBatchEl;
var
  r:integer;
  ber:TDecodedBatchElementResult;
begin
  r:=fBatchEdit.sgBchEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  if r>Length(DecodedBatch) then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  ber:=uEditBatchElement.EditBatchElement(DecodedBatch[r-1]);
  if ber.res then
    begin
      SetLength(DecodedBatch,length(DecodedBatch)+1);
      DecodedBatch[length(DecodedBatch)-1]:=ber.dber_batch_element;
      RefreshList;
    end;
end;

procedure AddBatchEl;
var
  ber:TDecodedBatchElementResult;
  in_b:TDecodedBatchElement;
begin
  in_b.be_param:='';
  in_b.be_timeout:=0;
  in_b.be_wait:=true;
  in_b.be_write_log:=true;
  ber:=uEditBatchElement.EditBatchElement(in_b);
  if ber.res then
    begin
      SetLength(DecodedBatch,length(DecodedBatch)+1);
      DecodedBatch[length(DecodedBatch)-1]:=ber.dber_batch_element;
      RefreshList;
    end;
end;

procedure DelBatchEl;
var
  r,x:integer;
begin
  r:=fBatchEdit.sgBchEdit.Row;
  if r<1 then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  if r>Length(DecodedBatch) then
    begin
      ShowMessage('Select batch element first!');
      exit;
    end;
  if MessageDlg('Are you sure?','Delete batch element?',mtConfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      for x:=r to Length(DecodedBatch)-1 do
        begin
          DecodedBatch[x-1]:=DecodedBatch[x];
        end;
      SetLength(DecodedBatch,Length(DecodedBatch)-1);
      RefreshList;
    end;
end;

end.

