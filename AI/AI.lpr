program AI;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, ulogin, ucustomtypes, unetwork, ucrypt, ustrutils, uAlarm,
  usaverestorepositionandsize, upath
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='itfx IMS information agent';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.

