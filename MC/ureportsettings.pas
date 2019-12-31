unit uReportSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  EditBtn, uCustomTypes, dateutils;

type

  { TfReportSettings }

  TfReportSettings = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    bSelectPath: TButton;
    cbReportOptions11: TCheckBox;
    cbReportOptions12: TCheckBox;
    cbReportOptions211: TCheckBox;
    cbReportOptions212: TCheckBox;
    cbReportOptions22: TCheckBox;
    deDateBegin: TDateEdit;
    deDateEnd: TDateEdit;
    eFileName: TEdit;
    gbReportOptions: TGroupBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    sdReport: TSaveDialog;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bSelectPathClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fReportSettings: TfReportSettings;
  res: string;

function GetReportSettings():string;

implementation

{$R *.lfm}

{ TfReportSettings }


function GetReportSettings():string;
begin
  Application.CreateForm(TfReportSettings, fReportSettings);
  fReportSettings.deDateBegin.Date:=now;
  fReportSettings.deDateEnd.Date:=now;
  res:='';
  fReportSettings.ShowModal;
  result:=res;
end;

procedure TfReportSettings.bCancelClick(Sender: TObject);
begin
  res:='';
  Close;
end;

procedure TfReportSettings.bOKClick(Sender: TObject);
var
  tf:textfile;
begin
  // check
  if fReportSettings.deDateBegin.Date>fReportSettings.deDateEnd.Date then
    begin
      ShowMessage('Invalid period!');
      exit;
    end;
  if not (fReportSettings.cbReportOptions11.Checked or
          fReportSettings.cbReportOptions12.Checked or
          fReportSettings.cbReportOptions211.Checked or
          fReportSettings.cbReportOptions212.Checked or
          fReportSettings.cbReportOptions22.Checked) then
    begin
      ShowMessage('Select report options, please!');
      Exit;
    end;

  eFileName.Text:=trim(eFileName.Text);
  if eFileName.Text='' then
    begin
      ShowMessage('Empty file name!');
      Exit;
    end;
  try
    AssignFile(tf,eFileName.Text);
    Rewrite(tf);
    WriteLn(tf,'R/W test');
    CloseFile(tf);
    DeleteFile(eFileName.Text);
  except
    ShowMessage('Can''t write to file ['+eFileName.Text+']!');
    Exit;
  end;

  res:=FloatToStr(StartOfTheDay(fReportSettings.deDateBegin.Date))+ParamLimiter;
  res:=res+FloatToStr(EndOfTheDay(fReportSettings.deDateEnd.Date))+ParamLimiter;
  if cbReportOptions11.Checked then
    begin
      res:=res+'1/';
    end
    else
    begin
      res:=res+'0/';
    end;
  if cbReportOptions12.Checked then
    begin
      res:=res+'1/';
    end
    else
    begin
      res:=res+'0/';
     end;
  if cbReportOptions22.Checked then
    begin
      res:=res+'1/';
    end
    else
    begin
      res:=res+'0/';
    end;
  if cbReportOptions211.Checked then
    begin
      res:=res+'1/';
    end
    else
    begin
      res:=res+'0/';
    end;
  if cbReportOptions212.Checked then
    begin
      res:=res+'1';
    end
    else
    begin
      res:=res+'0';
  end;
  res:=res+ParamLimiter+eFileName.Text;
  Close;
end;

procedure TfReportSettings.bSelectPathClick(Sender: TObject);
begin
  if sdReport.Execute then
    begin
      eFileName.Text:=sdReport.FileName;
    end;
end;

procedure TfReportSettings.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

end.

