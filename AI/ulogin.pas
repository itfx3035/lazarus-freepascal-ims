unit uLogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TLoginParams = Record
    lp_server:string;
    lp_password:string;
    lp_remember: boolean;
    lp_port: integer;
    lp_valid: boolean;
  end;

  { TfLogin }
  TfLogin = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    bOptions: TButton;
    cbRemember: TCheckBox;
    ePort: TEdit;
    eServer: TEdit;
    ePassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bOptionsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fLogin: TfLogin;
  res:boolean;

function GetLoginParams(lp:TLoginParams):TLoginParams;

implementation

{$R *.lfm}

{ TfLogin }

function GetLoginParams(lp:TLoginParams):TLoginParams;
begin
  res:=false;
  Application.CreateForm(TfLogin, fLogin);
  fLogin.Height:=102;
  fLogin.eServer.Text:=lp.lp_server;
  fLogin.ePort.Text:=inttostr(lp.lp_port);
  fLogin.cbRemember.Checked:=lp.lp_remember;
  fLogin.ShowModal;
  result.lp_valid:=res;
  if res then
    begin
      Result.lp_server:=fLogin.eServer.Text;
      Result.lp_password:=fLogin.ePassword.Text;
      Result.lp_remember:=fLogin.cbRemember.Checked;
      Result.lp_port:=StrToInt(fLogin.ePort.Text);
    end;
end;

procedure TfLogin.bCancelClick(Sender: TObject);
begin
  fLogin.Close;
end;

procedure TfLogin.bOKClick(Sender: TObject);
var
  tmp_int:Integer;
begin
  try
    tmp_int:=StrToInt(ePort.Text);
    res:=true;
    fLogin.Close;
  except
    ShowMessage('Invalid port number!');
    Exit;
  end;
end;

procedure TfLogin.bOptionsClick(Sender: TObject);
begin
  bOptions.Visible:=false;
  fLogin.Height:=160;
end;

procedure TfLogin.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;



end.

