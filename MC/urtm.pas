unit uRTM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, StrUtils, uSaveRestorePositionAndSize;

type



  { TfRTM }

  TfRTM = class(TForm)
    lbRTM: TListBox;
    sbRTM: TStatusBar;
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fRTM: TfRTM;

procedure AddRTMMsg(m_str,m_type:string);
procedure SetRTMStatus(s_str:string);

implementation

{$R *.lfm}

procedure AddRTMMsg(m_str,m_type:string);
var
  dt_str:string;
  //rslt:string;
  msg_str:string;
  res:string;
begin

  if m_type='1' then
    begin
      res:=m_str;
    end;
  if m_type='2' then
    begin
      dt_str := MidStr(m_str, 1, 19);
      //rslt := StrToInt(MidStr(m_str, 22, 1));
      msg_str := RightStr(m_str, length(m_str) - 23);
      res:= dt_str+': '+msg_str;
    end;

  fRTM.lbRTM.Items.Add(res);
  fRTM.lbRTM.ItemIndex:=fRTM.lbRTM.Items.Count-1;
  Application.ProcessMessages;
end;

procedure SetRTMStatus(s_str:string);
begin
  fRTM.sbRTM.SimpleText:=s_str;
  Application.ProcessMessages;
end;

{ TfRTM }

procedure TfRTM.FormShow(Sender: TObject);
begin
  fRTM.lbRTM.Items.Clear;
  fRTM.sbRTM.SimpleText:='';
  uSaveRestorePositionAndSize.RestorePositionAndSize('rtm',fRTM);
end;


procedure TfRTM.FormHide(Sender: TObject);
begin
  uSaveRestorePositionAndSize.SavePositionAndSize('rtm',fRTM);
end;

end.

