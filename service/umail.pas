unit uMail;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SMTPSend, mimemess, mimepart, synautil;


function SendMailAttachment(MailFrom,MailTo,Subject,SMTPHost,Username,Password,FilePath:string):integer;
function SendMailText(MailFrom,MailTo,Subject,SMTPHost,Username,Password,MailText:string):integer;

implementation

function SendMailAttachment(MailFrom,MailTo,Subject,SMTPHost,Username,Password,FilePath:string):integer;
var
  res:boolean;
  mm:TMimeMess;
  root_mpart:TMimePart;
  data:TStrings;
begin
  mm:=TMimeMess.Create;
  root_mpart:=mm.AddPartMultipart('mixed',nil);

  try
    data:=TStringList.Create;
    data.Add('Message from itfx IMS server');
    mm.AddPartText(data,root_mpart);

    mm.AddPartBinaryFromFile(FilePath,root_mpart);

    mm.Header.from:=MailFrom;
    mm.Header.ToList.Add(MailTo);
    mm.Header.Subject:=Subject;
    mm.Header.XMailer:='X-mailer: itfx IMS';
    mm.Header.Date:=now;
    mm.EncodeMessage;
  except
    result:=-2;
    exit;
  end;

  try
    res:=SMTPSend.SendToRaw(MailFrom,MailTo,SMTPHost,mm.Lines,Username,Password);
  except
    result:=-1;
    exit;
  end;

  if res then
    begin
      result:=1;
    end
    else
    begin
      result:=-1;
    end;
end;

function SendMailText(MailFrom,MailTo,Subject,SMTPHost,Username,Password,MailText:string):integer;
var
  res:boolean;
  mm:TMimeMess;
  root_mpart:TMimePart;
  data:TStrings;
begin
  mm:=TMimeMess.Create;
  root_mpart:=mm.AddPartMultipart('mixed',nil);

  try
    data:=TStringList.Create;
    data.Add('Message from itfx IMS server');
    data.Add(MailText);

    mm.AddPartText(data,root_mpart);

    mm.Header.from:=MailFrom;
    mm.Header.ToList.Add(MailTo);
    mm.Header.Subject:=Subject;
    mm.Header.XMailer:='X-mailer: itfx IMS';
    mm.Header.Date:=now;
    mm.EncodeMessage;
  except
    result:=-2;
    exit;
  end;

  try
    res:=SMTPSend.SendToRaw(MailFrom,MailTo,SMTPHost,mm.Lines,Username,Password);
  except
    result:=-1;
    exit;
  end;

  if res then
    begin
      result:=1;
    end
    else
    begin
      result:=-1;
    end;
end;


end.

