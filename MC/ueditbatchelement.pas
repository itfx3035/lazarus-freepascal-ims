unit uEditBatchElement;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  uCustomTypes,uStrUtils;

type

  { TfEditBatchElement }

  TfEditBatchElement = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    cbWait: TCheckBox;
    cbWriteLog: TCheckBox;
    eCommand: TEdit;
    eTimeout: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fEditBatchElement: TfEditBatchElement;
  res:TDecodedBatchElementResult;

function EditBatchElement(in_el:TDecodedBatchElement):TDecodedBatchElementResult;

implementation
{$R *.lfm}

{ TfEditBatchElement }

function EditBatchElement(in_el:TDecodedBatchElement):TDecodedBatchElementResult;
begin
  Application.CreateForm(TfEditBatchElement, fEditBatchElement);
  res.res:=false;

  fEditBatchElement.eCommand.Text:=in_el.be_param;
  fEditBatchElement.cbWait.Checked:=in_el.be_wait;
  fEditBatchElement.cbWriteLog.Checked:=in_el.be_write_log;
  fEditBatchElement.eTimeout.Text:=inttostr(in_el.be_timeout);

  fEditBatchElement.ShowModal;
  result:=res;
end;



procedure TfEditBatchElement.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfEditBatchElement.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfEditBatchElement.bOKClick(Sender: TObject);
var
  timeout:integer;
begin
  if trim(eCommand.Text)='' then
    begin
      ShowMessage('Empty command!');
      exit;
    end;
  try
    timeout:=strtoint(eTimeout.Text);
  except
    ShowMessage('Invalid timeout!');
    exit;
  end;
  if not uStrUtils.ValidSymbols(eCommand.Text) then
    begin
      ShowMessage('Command contains invalid symbols!');
      exit;
    end;
  res.res:=true;
  res.dber_batch_element.be_timeout:=timeout;
  res.dber_batch_element.be_write_log:=cbWriteLog.Checked;
  res.dber_batch_element.be_wait:=cbWait.Checked;
  res.dber_batch_element.be_param:=trim(eCommand.Text);
  close;
end;

end.

