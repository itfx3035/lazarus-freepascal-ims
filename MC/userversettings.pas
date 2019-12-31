unit uServerSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls;

type

  { TfServerSettings }

  TfServerSettings = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    eCollectorAgentPort: TEdit;
    eMCPasswd: TEdit;
    eAIPasswd: TEdit;
    eSUDOPasswd: TEdit;
    eMCPort: TEdit;
    eReserveServiceListeningPort: TEdit;
    eUserInformationAgentPort: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fServerSettings: TfServerSettings;

procedure RunServerSettings;

implementation
{$R *.lfm}
{ TfServerSettings }
uses uMain;

procedure RunServerSettings;
begin
  Application.CreateForm(TfServerSettings, fServerSettings);

  fServerSettings.eMCPort.Text:=inttostr(uMain.ssManagerConsoleListeningPort);
  fServerSettings.eCollectorAgentPort.Text:=inttostr(uMain.ssAgentCollectorListeningPort);
  fServerSettings.eUserInformationAgentPort.Text:=inttostr(uMain.ssAgentInformationListeningPort);
  fServerSettings.eReserveServiceListeningPort.Text:=inttostr(uMain.ssReservServiceListeningPort);
  fServerSettings.eSUDOPasswd.Text:=uMain.ssSudoPwd;
  fServerSettings.eAIPasswd.Text:=uMain.ssAILogonPwd;
  if uMain.sServerOSVer='LIN' then
    begin
      fServerSettings.eSUDOPasswd.Enabled:=false;
      fServerSettings.label9.Enabled:=false;
    end;
  fServerSettings.eMCPasswd.Text:=uMain.ssMCLogonPwd;

  fServerSettings.PageControl1.TabIndex:=0;

  fServerSettings.ShowModal;
end;

procedure TfServerSettings.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfServerSettings.bOKClick(Sender: TObject);
var
  tmp_int:integer;
begin
  try
    tmp_int:=strtoint(fServerSettings.eMCPort.Text);
  except
    ShowMessage('Invalid management console listening port!');
    exit;
  end;
  try
    tmp_int:=strtoint(fServerSettings.eCollectorAgentPort.Text);
  except
    ShowMessage('Invalid collector agent listening port!');
    exit;
  end;
  try
    tmp_int:=strtoint(fServerSettings.eUserInformationAgentPort.Text);
  except
    ShowMessage('Invalid user information agent listening port!');
    exit;
  end;
  try
    tmp_int:=strtoint(fServerSettings.eReserveServiceListeningPort.Text);
  except
    ShowMessage('Invalid reserve service listening port!');
    exit;
  end;

  uMain.ssManagerConsoleListeningPort:=strtoint(fServerSettings.eMCPort.Text);
  uMain.ssAgentCollectorListeningPort:=strtoint(fServerSettings.eCollectorAgentPort.Text);
  uMain.ssAgentInformationListeningPort:=strtoint(fServerSettings.eUserInformationAgentPort.Text);
  uMain.ssReservServiceListeningPort:=strtoint(fServerSettings.eReserveServiceListeningPort.Text);
  uMain.ssSudoPwd:=fServerSettings.eSUDOPasswd.Text;
  uMain.ssAILogonPwd:=fServerSettings.eAIPasswd.Text;
  uMain.ssMCLogonPwd:=fServerSettings.eMCPasswd.Text;

  WaitSocketForOp(2); // save settings to server

  Close;
end;

procedure TfServerSettings.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

end.

