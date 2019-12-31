unit uBatchExecute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uProcessExecute, uStrUtils;


type
  TBatch = record
    batch_str: string;
    batch_params: string;
    batch_name: string;
  end;
  TBatchArray=array of TBatch;
  TDecodedBatchElement = record
    be_param:string;
    be_wait:boolean;
    be_write_log:boolean;
    be_timeout:integer;
  end;
  TDecodedBatch = array of TDecodedBatchElement;


function ExecuteBatch(batch:TBatch; sudo_pwd:string):TStringList;
function DecodeBatch(batch:TBatch):TDecodedBatch;
function FindBatch(arr_batch:TBatchArray; batch_name:string):tBatch;

implementation

uses uMain;


function ExecuteBatch(batch:TBatch; sudo_pwd:string):TStringList;
var
  dbatcharr:TDecodedBatch;
  dbatchel:TDecodedBatchElement;
  x,y:integer;
  tmp_string_list:TStringList;
begin
  Result := TStringList.Create;
  dbatcharr:=DecodeBatch(batch);
  if dbatcharr[0].be_param='err' then
    begin
      Result.Add('err');
      exit;
    end;
  Result.Add('Batch ['+batch.batch_name+'] begin execution...');
  for x:=1 to length(dbatcharr) do
    begin
      dbatchel:=dbatcharr[x-1];
      if dbatchel.be_wait then
        begin
          Result.Add('Batch ['+batch.batch_name+'], task #'+inttostr(x)+': executing and waiting ['+dbatchel.be_param+']');
          tmp_string_list:=uProcessExecute.ExecuteAndWaitOutput(dbatchel.be_param,sudo_pwd,dbatchel.be_timeout);
          if dbatchel.be_write_log then
            begin
              for y:=1 to tmp_string_list.Count do
                begin
                  Result.Add('task #'+inttostr(x)+' - '+tmp_string_list[y-1]);
                end;
            end;
          Result.Add('Batch ['+batch.batch_name+'], task #'+inttostr(x)+' finished.');
        end
        else
        begin
          Result.Add('Batch ['+batch.batch_name+'], task #'+inttostr(x)+': executing ['+dbatchel.be_param+']');
          uProcessExecute.ExecuteAndNoWait(dbatchel.be_param,sudo_pwd,dbatchel.be_timeout,dbatchel.be_write_log);
        end;
    end;
  Result.Add('Batch ['+batch.batch_name+'] execution finished.');
end;

function DecodeBatch(batch:TBatch):TDecodedBatch;
var
  count:integer;
  x:integer;
  tmp:string;
begin
  setlength(result,0);
  try
    count:=strtoint(uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, 1));
    setlength(result,count);
    for x:=1 to count do
      begin
        result[x-1].be_param:=uStrUtils.GetFieldFromString(batch.batch_params, ParamLimiter, x);
        // wait or not
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+2);
        if trim(tmp)='1' then
          begin
            result[x-1].be_wait:=true;
          end
          else
          begin
            result[x-1].be_wait:=false;
          end;
        // write log or not
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+3);
        if trim(tmp)='1' then
          begin
            result[x-1].be_write_log:=true;
          end
          else
          begin
            result[x-1].be_write_log:=false;
          end;
        // timeout
        tmp:=uStrUtils.GetFieldFromString(batch.batch_str, ParamLimiter, (x-1)*3+4);
        result[x-1].be_timeout:=strtoint(tmp);
      end;
  except
    setlength(result,1);
    Result[0].be_param:='err';
  end;
end;

function FindBatch(arr_batch:TBatchArray; batch_name:string):tBatch;
var
  x:integer;
begin
  cs9.Enter;

  result.batch_name:='';
  result.batch_params:='';
  result.batch_str:='';
  for x:=1 to length(arr_batch) do
    begin
      if UpperCase(arr_batch[x-1].batch_name)=UpperCase(batch_name) then
        begin
          result.batch_name:=arr_batch[x-1].batch_name;
          result.batch_params:=arr_batch[x-1].batch_params;
          result.batch_str:=arr_batch[x-1].batch_str;
        end;
    end;

  cs9.Leave;
end;

end.

