unit uAlarm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, mmsystem;

type

  { TfAlarm }

  TfAlarm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    lAlarmDateTime: TLabel;
    lName: TLabel;
    TClose: TTimer;
    tSound: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure TCloseTimer(Sender: TObject);
    procedure tSoundTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fAlarm: TfAlarm;

procedure ShowAlarm(alrm_name:string;alrm_dt:tdatetime);

implementation
{$R *.lfm}

procedure ShowAlarm(alrm_name:string;alrm_dt:tdatetime);
begin
  Application.CreateForm(TfAlarm, fAlarm);
  fAlarm.lName.Caption:=alrm_name;
  fAlarm.lAlarmDateTime.Caption:=datetimetostr(alrm_dt);
  fAlarm.tSound.Enabled:=true;
  fAlarm.Show;
end;

{ TfAlarm }

procedure TfAlarm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfAlarm.TCloseTimer(Sender: TObject);
begin
  Close;
end;

procedure TfAlarm.tSoundTimer(Sender: TObject);
var
  fn:string;
begin
  tSound.Enabled:=false;

  fn:=ExtractFilePath(Application.ExeName)+'alarm.wav';
  mmsystem.PlaySound(pchar(fn),0,SND_FILENAME);
end;

end.

