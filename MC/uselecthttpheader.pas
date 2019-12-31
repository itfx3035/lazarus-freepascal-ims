unit uSelectHTTPHeader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  httpsend;

type

  { TfSelectHTTPHeader }

  TfSelectHTTPHeader = class(TForm)
    bGetHeader: TButton;
    bCancel: TButton;
    bOK: TButton;
    bSetOKHeader: TButton;
    eWebPage: TEdit;
    eHeader: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bGetHeaderClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bSetOKHeaderClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSelectHTTPHeader: TfSelectHTTPHeader;
  res:string;

function SelectHTTPHeader(in_str:string):string;

implementation

{$R *.lfm}

{ TfSelectHTTPHeader }


function SelectHTTPHeader(in_str:string):string;
begin
  Application.CreateForm(TfSelectHTTPHeader, fSelectHTTPHeader);
  res:='';
  fSelectHTTPHeader.ShowModal;
  result:=res;
end;

procedure TfSelectHTTPHeader.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfSelectHTTPHeader.bGetHeaderClick(Sender: TObject);
var
  HTTP:httpsend.THTTPSend;
begin
  HTTP:=httpsend.THTTPSend.Create;
  if HTTP.HTTPMethod('GET', trim(eWebPage.Text)) then
    begin
      try
        eHeader.Text:=HTTP.Headers[0];
      except
        ShowMessage('Error getting HTTP header on this web page!');
      end;
    end
    else
    begin
      ShowMessage('Error getting HTTP header on this web page!');
    end;
  try
    HTTP.Free;
  except
  end;
end;

procedure TfSelectHTTPHeader.bOKClick(Sender: TObject);
begin
  if eHeader.Text<>'' then
    begin
      res:=trim(eHeader.Text);
      close;
    end
    else
    begin
      ShowMessage('Invalid HTTP header!');
    end;
end;

procedure TfSelectHTTPHeader.bSetOKHeaderClick(Sender: TObject);
begin
  eHeader.Text:='HTTP/1.1 200 OK';
end;

procedure TfSelectHTTPHeader.bCancelClick(Sender: TObject);
begin
  Close;
end;

end.

