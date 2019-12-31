program mc;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, uLogin, unetwork, ucrypt, uServerSettings, uSchEditor,
  ustrutils, uEditEvent, uSelectEventType, uCustomTypes, uSelectPortNumber,
  uSelectHTTPHeader, uBchEditor, uEditBatch, uEditBatchElement,
  uEventClassifier, uSelectSubnet, uEditAlarmTemplate, uAlarmTemplateEditor,
  uEditAlarmElement, uReportSettings, uRTM, uSaveRestorePositionAndSize, uPath;

{$R *.res}

begin
  Application.Title:='itfx IMS management console';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfRTM, fRTM);
  Application.Run;
end.

