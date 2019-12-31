unit uSelectPortNumber;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus;

type

  { TfSelectPort }

  TfSelectPort = class(TForm)
    bCancel: TButton;
    bPreset: TButton;
    bOK: TButton;
    ePortNumber: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    pmMustUsedPort: TPopupMenu;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bPresetClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSelectPort: TfSelectPort;
  res:string;

  function SelectPort(in_str:string):string;

implementation

{$R *.lfm}

{ TfSelectPort }

function SelectPort(in_str:string):string;
begin
  Application.CreateForm(TfSelectPort, fSelectPort);
  res:='';
  fSelectPort.ePortNumber.Text:=in_str;
  fSelectPort.ShowModal;
  result:=res;
end;

procedure TfSelectPort.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  CloseAction:=caFree;
end;

procedure TfSelectPort.MenuItem10Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:139';
end;

procedure TfSelectPort.MenuItem11Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:5900';
end;

procedure TfSelectPort.MenuItem12Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:5432';
end;

procedure TfSelectPort.MenuItem1Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:21';
end;

procedure TfSelectPort.MenuItem2Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:22';
end;

procedure TfSelectPort.MenuItem3Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:23';
end;

procedure TfSelectPort.MenuItem4Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:25';
end;

procedure TfSelectPort.MenuItem5Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:80';
end;

procedure TfSelectPort.MenuItem6Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:110';
end;

procedure TfSelectPort.MenuItem7Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:443';
end;

procedure TfSelectPort.MenuItem8Click(Sender: TObject);
begin
  ePortNumber.Text:='TCP:3306';
end;


procedure TfSelectPort.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfSelectPort.bOKClick(Sender: TObject);
var
  i:integer;
begin
  if not (leftstr(ePortNumber.Text,4)='TCP:') then
    begin
      showmessage('Invalid protocol type! Must be TCP.');
    end;
  try
    i:=strtoint(rightstr(ePortNumber.Text,length(ePortNumber.Text)-4));
    res:=trim(ePortNumber.Text);
    close;
  except
    showmessage('Invalid port number!');
  end;
end;

procedure TfSelectPort.bPresetClick(Sender: TObject);
begin
  fSelectPort.pmMustUsedPort.PopUp;
end;

end.

