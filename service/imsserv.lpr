Program imsserv;

Uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  DaemonApp, lazdaemonapp, DaemonMapperUnit1, DaemonUnit1, umain, ustrutils,
  uschedulerexecuter, uscheduler, ureserveservicelistener,
  ureserveserviceconnection, ureportbuilder, uprocessexecute, upath,
  uofflineinspector, unetwork, umclistener, umcconnection, umail, ulog, ucrypt,
  uconst, ubatchexecute, ualarm, uagentinformationlistener,
  uagentinformationconnection
  { add your units here };

{$R *.res}

begin
  Application.Title:='IMS server';
  Application.Initialize;
  Application.Run;
end.
