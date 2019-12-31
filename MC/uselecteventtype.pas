unit uSelectEventType;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, uCustomTypes, uEventClassifier;

type

  { TfSelectEventType }

  TfSelectEventType = class(TForm)
    bCancel: TButton;
    bOK: TButton;
    tvEvents: TTreeView;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure tvEventsDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fSelectEventType: TfSelectEventType;
  res:string;

function SelectEventType(in_type:string):string;

implementation

Uses uMain;

{$R *.lfm}

{ TfSelectEventType }


function SelectEventType(in_type:string):string;
var
  select_node,tn_root,tn1,tn2,tn3:TTreeNode;
begin
  Application.CreateForm(TfSelectEventType, fSelectEventType);
  res:='';

  tn_root:=TTreeNode.Create(fSelectEventType.tvEvents.Items);
  tn_root:=fSelectEventType.tvEvents.Items.AddFirst(tn_root,'Task types');

  tn1:=fSelectEventType.tvEvents.Items.AddChild(tn_root,GetEventNameFromID('4'));
  tn2:=fSelectEventType.tvEvents.Items.AddChild(tn1,GetEventNameFromID('4'+ParamLimiter+'1'));
  tn3:=fSelectEventType.tvEvents.Items.AddChild(tn2,GetEventNameFromID('4'+ParamLimiter+'1'+ParamLimiter+'1'));
  tn3:=fSelectEventType.tvEvents.Items.AddChild(tn2,GetEventNameFromID('4'+ParamLimiter+'1'+ParamLimiter+'2'));
  tn3:=fSelectEventType.tvEvents.Items.AddChild(tn2,GetEventNameFromID('4'+ParamLimiter+'1'+ParamLimiter+'5'));
  tn3:=fSelectEventType.tvEvents.Items.AddChild(tn2,GetEventNameFromID('4'+ParamLimiter+'1'+ParamLimiter+'8'));

  tn1:=fSelectEventType.tvEvents.Items.AddChild(tn_root,GetEventNameFromID('3'));
  tn2:=fSelectEventType.tvEvents.Items.AddChild(tn1,GetEventNameFromID('3'+ParamLimiter+'1'));
  tn3:=fSelectEventType.tvEvents.Items.AddChild(tn2,GetEventNameFromID('3'+ParamLimiter+'1'+ParamLimiter+'1'));

  tn1:=fSelectEventType.tvEvents.Items.AddChild(tn_root,GetEventNameFromID('2'));

  tn1:=fSelectEventType.tvEvents.Items.AddChild(tn_root,GetEventNameFromID('1'));
  tn2:=fSelectEventType.tvEvents.Items.AddChild(tn1,GetEventNameFromID('1'+ParamLimiter+'1'));

  select_node:=fSelectEventType.tvEvents.Items.FindNodeWithText(GetEventNameFromID(in_type));

  fSelectEventType.tvEvents.Items.SelectOnlyThis(select_node);

  fSelectEventType.ShowModal;
  Result:=res;
end;

procedure TfSelectEventType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfSelectEventType.tvEventsDblClick(Sender: TObject);
begin
  bOK.Click;
end;

procedure TfSelectEventType.bCancelClick(Sender: TObject);
begin
  close;
end;

procedure TfSelectEventType.bOKClick(Sender: TObject);
var
  treenode:TTreeNode;
  tmp:string;
begin
  treenode:=fSelectEventType.tvEvents.Items.GetSelections(0);
  if treenode.HasChildren then
    begin
      exit;
    end;
  res:='';

  // ---------------------------------------------
  tmp:=GetIDFromEventName(treenode.Text);
  // --------------------------------------------
  if tmp='4'+ParamLimiter+'1'+ParamLimiter+'1' then
    begin
      res:=tmp;
    end;
  if tmp='4'+ParamLimiter+'1'+ParamLimiter+'2' then
    begin
      res:=tmp;
    end;
  if tmp='4'+ParamLimiter+'1'+ParamLimiter+'5' then
    begin
      res:=tmp;
    end;
  if tmp='4'+ParamLimiter+'1'+ParamLimiter+'8' then
    begin
      res:=tmp;
    end;
  // --------------------------------------------
  if tmp='1'+ParamLimiter+'1' then
    begin
      res:=tmp;
    end;
  // --------------------------------------------
  if tmp='2' then
    begin
      res:=tmp;
    end;
  // --------------------------------------------
  if tmp='3'+ParamLimiter+'1'+ParamLimiter+'1' then
    begin
      res:=tmp;
    end;
  // --------------------------------------------
  if res<>'' then
    begin
      close;
    end;
end;

end.

