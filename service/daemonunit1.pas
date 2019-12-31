unit DaemonUnit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DaemonApp, uMain;

type

  { TDaemon1 }

  TDaemon1 = class(TDaemon)
    procedure DataModuleExecute(Sender: TCustomDaemon);
    procedure DataModuleShutDown(Sender: TCustomDaemon);
    procedure DataModuleStart(Sender: TCustomDaemon; var OK: Boolean);
    procedure DataModuleStop(Sender: TCustomDaemon; var OK: Boolean);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Daemon1: TDaemon1;

implementation

procedure RegisterDaemon;
begin
  RegisterDaemonClass(TDaemon1)
end;

{ TDaemon1 }

procedure TDaemon1.DataModuleExecute(Sender: TCustomDaemon);
begin
  //umain.StartSequence;
end;

procedure TDaemon1.DataModuleShutDown(Sender: TCustomDaemon);
begin
  umain.StopSequence;
end;

procedure TDaemon1.DataModuleStart(Sender: TCustomDaemon; var OK: Boolean);
begin
  umain.StartSequence;
end;


procedure TDaemon1.DataModuleStop(Sender: TCustomDaemon; var OK: Boolean);
begin
  umain.StopSequence;
  ok:=True;
end;

{$R *.lfm}


initialization
  RegisterDaemon;
end.

