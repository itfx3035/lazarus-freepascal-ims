unit uSelectSubnet;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  uStrUtils;

type

  { TfSelectSubnet }

  TfSelectSubnet = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    eIpPart1: TEdit;
    eIpPart2: TEdit;
    eIpPart3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSelectSubnet: TfSelectSubnet;
  res:string;

function SelectSubnet(in_str:string):string;

implementation

{$R *.lfm}

{ TfSelectSubnet }

function SelectSubnet(in_str:string):string;
begin
  Application.CreateForm(TfSelectSubnet, fSelectSubnet);
  if trim(in_str)='' then
  begin
    fSelectSubnet.eIpPart1.Text:='192';
    fSelectSubnet.eIpPart2.Text:='168';
    fSelectSubnet.eIpPart3.Text:='0';
  end
  else
  begin
    fSelectSubnet.eIpPart1.Text:=uStrUtils.GetFieldFromString(in_str,'.',1);
    fSelectSubnet.eIpPart2.Text:=uStrUtils.GetFieldFromString(in_str,'.',2);
    fSelectSubnet.eIpPart3.Text:=uStrUtils.GetFieldFromString(in_str,'.',3);
  end;
  res:='';
  fSelectSubnet.ShowModal;
  result:=res;
end;

procedure TfSelectSubnet.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfSelectSubnet.bOKClick(Sender: TObject);
var
  isErr:boolean;
  prm1,prm2,prm3:integer;
begin
  isErr:=false;
  try
    prm1:=strtoint(eIpPart1.Text);
  except
    ShowMessage('Invalid integer value in subnet ip - part 1.');
    isErr:=true;
  end;
  try
    prm2:=strtoint(eIpPart2.Text);
  except
    ShowMessage('Invalid integer value in subnet ip - part 2.');
    isErr:=true;
  end;
  try
    prm3:=strtoint(eIpPart3.Text);
  except
    ShowMessage('Invalid integer value in subnet ip - part 1.');
    isErr:=true;
  end;
  if isErr then
    begin
      exit;
    end;
  res:=inttostr(prm1)+'.'+inttostr(prm2)+'.'+inttostr(prm3);
  close;
end;

procedure TfSelectSubnet.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

end.

