unit uCustomTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock;

const
  ParamLimiter=#176;
  ParamLimiter2=#177;

type
  TLoginResult = Record
    S:TTCPBlockSocket;
    res:integer;
    res_msg:string;
  end;
  TSchedulerEvent = record
    ev_days_of_month: string; // 1,2,5,10,24,31
    ev_days_of_week: string;  // 1,2,5
    ev_repeat_type: integer; // 1-once per day, 2-every X seconds
    ev_repeat_interval: integer; // X seconds
    ev_time_h: word;
    ev_time_m: word;
    ev_time_s: word;
    ev_end_time_h: word;
    ev_end_time_m: word;
    ev_end_time_s: word;

    event_name: string;
    event_str: string;
    event_main_param: string;

    event_alarm_str: string;
    event_execution_str: string;
  end;
  TEventResult = record
    er_event:TSchedulerEvent;
    res:boolean;
  end;
  TBatch = record
    batch_name: string;
    batch_str: string;
    batch_params: string;
  end;
  TBatchResult = record
    br_batch:TBatch;
    res:boolean;
  end;
  TDecodedBatchElement = record
    be_param:string;
    be_wait:boolean;
    be_write_log:boolean;
    be_timeout:integer;
  end;
  tDecodedBatch = array of TDecodedBatchElement;
  TDecodedBatchElementResult = record
    dber_batch_element:TDecodedBatchElement;
    res:boolean;
  end;


implementation

end.

