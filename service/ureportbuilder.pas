unit uReportBuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dateutils, blcksock, strutils, uStrUtils,
  uPath, uNetwork;

type
  TOfflineRecord = record
    r_msg: string;
    r_dt_begin: tDateTime;
    r_dt_end: tDateTime;
  end;
  TOfflineRecordArr = array of TOfflineRecord;

  TLogRecord = record
    r_rslt: integer;
    r_msg: string;
    r_dt: tDateTime;
  end;
  TLogRecordArr = array of TLogRecord;

  // stat ------------------------------------
  TStatRecord = record
    r_rslt: integer;
    r_msg: string[199];
    r_persent: integer;
    r_count: integer;
  end;
  TStatRecordArr = array of TStatRecord;

  TStatDateRecord = record
    r_event_date: tdate;
    r_arr: TStatRecordArr;
  end;
  TStatDateRecordArr = array of TStatDateRecord;

  TStatDateSRecord = record
    r_event_name: string[199];
    r_arr: TStatDateRecordArr;
  end;
  TStatDateSRecordArr = array of TStatDateSRecord;

  TStatGlobalRecord = record
    r_event_name: string[199];
    r_arr: TStatRecordArr;
  end;
  TStatGlobalRecordArr = array of TStatGlobalRecord;

  TStatGlobalResult = record
    r_arr_date: TStatDateSRecordArr;
    r_arr_global: TStatGlobalRecordArr;
  end;
  // -------------------------------------

  TStatElement = record
    r_event_name: string;
    r_msg: string;
    r_rslt: integer;
    r_date: TDate;
  end;

function BuildReport(dt_begin, dt_end: TDateTime; params: string;
  callReportProgressIndicator: boolean; sock: TTCPBlockSocket): string;

function GetOfflineReportStrings(dt_begin, dt_end: tdatetime): TOfflineRecordArr;
function GetReportLogStrings(dt_begin, dt_end: tdatetime): TLogRecordArr;
function GetServerLogStrings(dt_begin, dt_end: tdatetime): TLogRecordArr;
function CalculateStatInfo(dt_begin, dt_end: tdatetime;
  isGlobal, isPerDay: boolean): TStatGlobalResult;

procedure ReportProgressIndicator(sts:string; sock: TTCPBlockSocket);


implementation

uses umain;


function BuildReport(dt_begin, dt_end: TDateTime; params: string;
  callReportProgressIndicator: boolean; sock: TTCPBlockSocket): string;
var
  doc: TStrings;
  offline_arr: TOfflineRecordArr;
  report_log_arr: TLogRecordArr;
  server_log_arr: TLogRecordArr;
  stat_log_res: TStatGlobalResult;
  x, y, z: integer;
  err_arr: array of string;
  fp: string;
  ColorBegin, ColorEnd: string;
  include11, include12, include22: boolean;
  include21_per_day, include21_all: boolean;
begin

  cs7.Enter;

  include11 := False;
  include12 := False;
  include22 := False;
  include21_per_day := False;
  include21_all := False;
  if GetFieldFromString(params, '/', 1) = '1' then
  begin
    include11 := True;
  end;
  if GetFieldFromString(params, '/', 2) = '1' then
  begin
    include12 := True;
  end;
  if GetFieldFromString(params, '/', 3) = '1' then
  begin
    include22 := True;
  end;
  if GetFieldFromString(params, '/', 4) = '1' then
  begin
    include21_all := True;
  end;
  if GetFieldFromString(params, '/', 5) = '1' then
  begin
    include21_per_day := True;
  end;

  if include11 then
  begin
    setlength(err_arr, 0);

    if callReportProgressIndicator then
      begin
        ReportProgressIndicator('Collecting IMS server offline records...',sock);
      end;
    try
      offline_arr := GetOfflineReportStrings(dt_begin, dt_end);
    except
      setlength(err_arr, length(err_arr) + 1);
      err_arr[length(err_arr) - 1] :=
        'Error while collecting IMS server offline records!';
    end;
  end;

  if include12 then
  begin
    if callReportProgressIndicator then
      begin
        ReportProgressIndicator('Collecting server log messages...',sock);
      end;
    try
      server_log_arr := GetServerLogStrings(dt_begin, dt_end);
    except
      setlength(err_arr, length(err_arr) + 1);
      err_arr[length(err_arr) - 1] := 'Error while collecting server log messages!';
    end;
  end;

  if include21_all or include21_per_day then
  begin
    if callReportProgressIndicator then
      begin
        ReportProgressIndicator('Collecting statistics...',sock);
      end;
    stat_log_res := CalculateStatInfo(dt_begin, dt_end, include21_all,
      include21_per_day);
  end;

  if include22 then
  begin
    if callReportProgressIndicator then
      begin
        ReportProgressIndicator('Collecting report messages...',sock);
      end;
    try
      report_log_arr := GetReportLogStrings(dt_begin, dt_end);
    except
      setlength(err_arr, length(err_arr) + 1);
      err_arr[length(err_arr) - 1] := 'Error while collecting report messages!';
    end;
  end;


  if callReportProgressIndicator then
    begin
      ReportProgressIndicator('Generating report...',sock);
    end;

  doc := TStringList.Create;

  // header
  doc.Add('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">');
  doc.Add('<html>');
  doc.Add('<head>');
  doc.Add('<title>itfx IMS ' + GetAppVer + ' report</title>');
  doc.Add('<meta http-equiv="Content-Type" content="text/html;charset=windows-1251" >');
  doc.Add('</head>');
  doc.Add('<body BGCOLOR="#FFFFFF">');

  // report header
  doc.Add('<center><FONT SIZE=5><b>itfx IMS ' + GetAppVer +
    ' report</b></FONT></center><br>');
  doc.Add('<center>' + FormatDateTime('yyyy.mm.dd hh:nn:ss', dt_begin) +
    ' - ' + FormatDateTime('yyyy.mm.dd hh:nn:ss', dt_end) + '</center><br>');
  doc.Add('<br>');

  for x := 1 to Length(err_arr) do
  begin
    doc.Add('<b>' + err_arr[x - 1] + '</b>' + '<br>');
  end;
  if Length(err_arr) > 0 then
  begin
    doc.Add('<br>');
  end;

  if include11 or include12 then
  begin
    // part 1: itfx IMS server information
    doc.Add('<FONT SIZE=4><b>Part 1: itfx IMS server information</b></FONT><br>');
    doc.Add('<br>');
  end;

  if include11 then
  begin
    // part 1.1: itfx IMS offline records
    doc.Add('<b>Part 1.1: itfx IMS server offline records:</b><br>');
    if Length(offline_arr) = 0 then
    begin
      doc.Add('No offline records found in reported interval.<br>');
    end
    else
    begin
      doc.Add('<table BORDER="1">');
      doc.Add('<tbody>');
      doc.Add('<tr><td>Begin date & time</td><td>End date & time</td><td>State</td>');
      for x := 1 to length(offline_arr) do
      begin
        doc.Add('<tr><td>' + DT2STR(offline_arr[x - 1].r_dt_begin) +
          '</td><td>' + DT2STR(offline_arr[x - 1].r_dt_end) +
          '</td><td>' + trim(offline_arr[x - 1].r_msg) + '</td>');
      end;
    end;
    doc.Add('</tbody>');
    doc.Add('</table>');
    doc.Add('<br>');
  end;


  if include12 then
  begin
    // Part 1.2: itfx IMS server log
    doc.Add('<b>Part 1.2: itfx IMS server log</b><br>');
    if Length(server_log_arr) = 0 then
    begin
      doc.Add('No server log records found in reported interval.<br>');
    end
    else
    begin
      doc.Add('<table BORDER="1">');
      doc.Add('<tbody>');
      doc.Add('<tr><td>Date & time</td><td>Event</td></tr>');
      for x := 1 to length(server_log_arr) do
      begin
        doc.Add('<tr><td>' + DT2STR(server_log_arr[x - 1].r_dt) +
          '</td><td>' + trim(server_log_arr[x - 1].r_msg) + '</td></tr>');
      end;
    end;
    doc.Add('</tbody>');
    doc.Add('</table>');
    doc.Add('<br>');
  end;

  if include21_all or include21_per_day or include22 then
  begin
    // part 2: Report
    doc.Add('<FONT SIZE=4><b>Part 2: Report</b></FONT><br>');
    doc.Add('<br>');
  end;

  if include21_per_day or include22 then
  begin
    // part 2.1: Statistics
    doc.Add('<b>Part 2.1: Statistics</b><br>');

    // part 2.1.1: Overall statistics
    if include21_all then
    begin
      doc.Add('<b>Part 2.1.1: Overall statistics</b><br>');
      if Length(stat_log_res.r_arr_global) = 0 then
      begin
        doc.Add('No statistics records found in reported interval.<br>');
      end
      else
      begin
        for x := 1 to Length(stat_log_res.r_arr_global) do
        begin
          doc.Add('Event: ' + stat_log_res.r_arr_global[x - 1].r_event_name + '<br>');
          doc.Add('<table BORDER="1">');
          doc.Add('<tbody>');
          doc.Add('<tr><td>State</td><td>Percentage</td><td>Events count</td></tr>');
          for y := 1 to Length(stat_log_res.r_arr_global[x - 1].r_arr) do
          begin
            ColorBegin := '';
            ColorEnd := '';
            if stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_rslt = 0 then // RED
            begin
              ColorBegin := '<FONT COLOR=#FF0000>';
              ColorEnd := '</FONT>';
            end;
            if stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_rslt = 1 then // GREEN
            begin
              ColorBegin := '<FONT COLOR=#008900>';
              ColorEnd := '</FONT>';
            end;
            if stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_rslt = 4 then // GREY
            begin
              ColorBegin := '<FONT COLOR=#707070>';
              ColorEnd := '</FONT>';
            end;
            doc.Add('<tr><td>' + ColorBegin +
              trim(stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_msg) + ColorEnd +
              '</td><td>' + ColorBegin +
              IntToStr(stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_persent) +
              ColorEnd + '</td><td>' + ColorBegin +
              IntToStr(stat_log_res.r_arr_global[x - 1].r_arr[y - 1].r_count) + ColorEnd + '</td></tr>');
          end;
          doc.Add('</tbody>');
          doc.Add('</table>');
        end;
      end;
      doc.Add('<br>');
    end;

    // part 2.1.2: Per day statistics
    if include21_per_day then
    begin
      doc.Add('<b>Part 2.1.2: Per day statistics</b><br>');
      if Length(stat_log_res.r_arr_date) = 0 then
      begin
        doc.Add('No statistics records found in reported interval.<br>');
      end
      else
      begin
        for x := 1 to length(stat_log_res.r_arr_date) do
        begin
          doc.Add('Event: ' + stat_log_res.r_arr_date[x - 1].r_event_name + '<br>');
          doc.Add('<table BORDER="1">');
          doc.Add('<tbody>');
          doc.Add(
            '<tr><td>Date</td><td>Statistics</td></tr>');
          for y := 1 to length(stat_log_res.r_arr_date[x - 1].r_arr) do
          begin
            doc.Add('<tr><td>' + D2STR(
              stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_event_date) + '</td>');
            doc.Add('<td><table BORDER="1"><tbody>');
            doc.Add('<tr><td>State</td><td>Percentage</td><td>Events count</td></tr>');
            for z := 1 to length(stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr) do
            begin
              ColorBegin := '';
              ColorEnd := '';
              if stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_rslt = 0 then
                // RED
              begin
                ColorBegin := '<FONT COLOR=#FF0000>';
                ColorEnd := '</FONT>';
              end;
              if stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_rslt = 1 then
                // GREEN
              begin
                ColorBegin := '<FONT COLOR=#008900>';
                ColorEnd := '</FONT>';
              end;
              if stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_rslt = 4 then
                // GREY
              begin
                ColorBegin := '<FONT COLOR=#707070>';
                ColorEnd := '</FONT>';
              end;
              doc.Add('<tr><td>' + ColorBegin +
                trim(stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_msg) +
                ColorEnd + '</td><td>' + ColorBegin +
                IntToStr(stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_persent) +
                ColorEnd + '</td><td>' + ColorBegin +
                IntToStr(stat_log_res.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_count) +
                ColorEnd + '</td></tr>');
            end;
            doc.Add('</tbody></table>');
            doc.Add('</td></tr>');
          end;
          doc.Add('</tbody>');
          doc.Add('</table>');
        end;
      end;
      doc.Add('<br>');
    end;

  end;

  if include22 then
  begin
    // Part 2.2: Messages
    doc.Add('<b>Part 2.2: Messages</b><br>');
    if Length(report_log_arr) = 0 then
    begin
      doc.Add('No report log records found in reported interval.<br>');
    end
    else
    begin
      doc.Add('<table BORDER="1">');
      doc.Add('<tbody>');
      doc.Add('<tr><td>Date & time</td><td>Event</td></tr>');
      for x := 1 to length(report_log_arr) do
      begin
        ColorBegin := '';
        ColorEnd := '';
        if report_log_arr[x - 1].r_rslt = 0 then // RED
        begin
          ColorBegin := '<FONT COLOR=#FF0000>';
          ColorEnd := '</FONT>';
        end;
        if report_log_arr[x - 1].r_rslt = 1 then // GREEN
        begin
          ColorBegin := '<FONT COLOR=#008900>';
          ColorEnd := '</FONT>';
        end;
        if report_log_arr[x - 1].r_rslt = 4 then // GREY
        begin
          ColorBegin := '<FONT COLOR=#707070>';
          ColorEnd := '</FONT>';
        end;
        doc.Add('<tr><td>' + ColorBegin + DT2STR(report_log_arr[x - 1].r_dt) +
          ColorEnd + '</td><td>' + ColorBegin + trim(report_log_arr[x - 1].r_msg) +
          ColorEnd + '</td></tr>');
      end;
    end;
    doc.Add('</tbody>');
    doc.Add('</table>');
  end;

  // bottom
  doc.Add('<HR>');
  doc.Add('Generated ' + DT2STR(now) + ' by itfx IMS server<br>');
  doc.Add('itfx software solutions (c) 2013');
  doc.Add('</body>');
  doc.Add('</html>');

  {// erasing data
  for x:=1 to length(stat_log_res.r_arr_global) do
    begin
      setlength(stat_log_res.r_arr_global[x-1].r_arr,0);
    end;
  for x:=1 to length(stat_log_res.r_arr_date) do
    begin
      for y:=1 to length(stat_log_res.r_arr_date[x-1].r_arr) do
        begin
          setlength(stat_log_res.r_arr_date[x-1].r_arr[y-1].r_arr,0);
        end;
      setlength(stat_log_res.r_arr_date[x-1].r_arr,0);
    end;
  setlength(stat_log_res.r_arr_global,0);
  setlength(stat_log_res.r_arr_date,0);}

  fp := GetReportTmpFilePath(now);
  try
    doc.SaveToFile(fp);
  except
    fp := '';
  end;
  Result := fp;

  cs7.Leave;
end;


function GetOfflineReportStrings(dt_begin, dt_end: tdatetime): TOfflineRecordArr;
var
  dt_first, dt_last, dt_curr: tDateTime;
  fp: string;
  tf: textfile;
  tmp, tmp2: string;
  dt_str1, dt_str2: string;
  dt_param1, dt_param2: tDateTime;
  cnt: integer;
  tmp_int:extended;
begin
  setlength(Result, 0);
  cnt := 0;
  dt_first := int(dt_begin);
  dt_last := int(dt_end);
  dt_curr := int(dt_first);

  while dt_curr <= dt_last do
  begin
    fp := GetOfflineLogFilePath(dt_curr);
    if FileExists(fp) then
    begin
      AssignFile(tf, fp);

      try
        reset(tf);
        while not EOF(tf) do
          begin
            readln(tf, tmp);

            dt_str1 := MidStr(tmp, 1, 19);
            dt_str2 := MidStr(tmp, 23, 19);
            dt_param1 := STR2DT(dt_str1);
            dt_param2 := STR2DT(dt_str2);

            if ((dt_param1 >= dt_begin) and (dt_param1 <= dt_end)) or
              ((dt_param2 >= dt_begin) and (dt_param2 <= dt_end)) or
              ((dt_param1 <= dt_begin) and (dt_param2 >= dt_end)) then
            begin
              tmp2 := RightStr(tmp, length(tmp) - 43);

              cnt := cnt + 1;
              setlength(Result, cnt);
              Result[cnt - 1].r_dt_begin := dt_param1;
              Result[cnt - 1].r_dt_end := dt_param2;
              Result[cnt - 1].r_msg := tmp2;
            end;
          end;
      except
      end;
      try
        closefile(tf);
      except
      end;
    end;
    dt_curr := dt_curr + 1;
  end;
end;

function GetReportLogStrings(dt_begin, dt_end: tdatetime): TLogRecordArr;
var
  dt_first, dt_last, dt_curr: tDateTime;
  fp: string;
  tf: textfile;
  tmp, tmp2: string;
  dt_str1: string;
  dt_param1: tDateTime;
  cnt: integer;
  rslt: integer;
  readed:boolean;
  readed_cnt:integer;
  tmp_int:extended;
begin
  setlength(Result, 0);
  cnt := 0;
  dt_first := int(dt_begin);
  dt_last := int(dt_end);
  dt_curr := int(dt_first);

  while dt_curr <= dt_last do
  begin
    fp := GetReportLogsFilePath(dt_curr);
    if FileExists(fp) then
    begin
      AssignFile(tf, fp);

      readed:=false;
      readed_cnt:=0;
      while not readed do
      begin
        try
          reset(tf);
          while not EOF(tf) do
          begin
            readln(tf, tmp);

            dt_str1 := MidStr(tmp, 1, 19);
            dt_param1 := STR2DT(dt_str1);
            rslt := StrToInt(MidStr(tmp, 22, 1));

            if ((dt_param1 >= dt_begin) and (dt_param1 <= dt_end)) then
            begin
              tmp2 := RightStr(tmp, length(tmp) - 23);

              cnt := cnt + 1;
              setlength(Result, cnt);
              Result[cnt - 1].r_dt := dt_param1;
              Result[cnt - 1].r_msg := tmp2;
              Result[cnt - 1].r_rslt := rslt;
            end;
          end;
          closefile(tf);
          readed:=true;
        except
          readed:=false;
          readed_cnt:=readed_cnt+1;
          sleep(50);
          if readed_cnt>=5 then
          begin
            tmp_int:=1/0;
          end;
        end;
      end;
    end;
    dt_curr := dt_curr + 1;
  end;
end;


function GetServerLogStrings(dt_begin, dt_end: tdatetime): TLogRecordArr;
var
  dt_first, dt_last, dt_curr: tDateTime;
  fp: string;
  tf: textfile;
  tmp, tmp2: string;
  dt_str1: string;
  dt_param1: tDateTime;
  cnt: integer;
  //rslt:integer;
  readed:boolean;
  readed_cnt:integer;
  tmp_int:extended;
begin
  setlength(Result, 0);
  cnt := 0;
  dt_first := int(dt_begin);
  dt_last := int(dt_end);
  dt_curr := int(dt_first);

  while dt_curr <= dt_last do
  begin
    fp := GetDailyLogFilePath(dt_curr);
    if FileExists(fp) then
    begin
      AssignFile(tf, fp);

      readed:=false;
      readed_cnt:=0;
      while not readed do
      begin
        try
          reset(tf);
          while not EOF(tf) do
          begin
            readln(tf, tmp);

            dt_str1 := MidStr(tmp, 1, 19);
            dt_param1 := STR2DT(dt_str1);
            //rslt:=strtoint(MidStr(tmp,1,22));

            if ((dt_param1 >= dt_begin) and (dt_param1 <= dt_end)) then
            begin
              tmp2 := RightStr(tmp, length(tmp) - 21);

              cnt := cnt + 1;
              setlength(Result, cnt);
              Result[cnt - 1].r_dt := dt_param1;
              Result[cnt - 1].r_msg := tmp2;
              Result[cnt - 1].r_rslt := 255;
            end;
          end;
          closefile(tf);
          readed:=true;
        except
          readed:=false;
          readed_cnt:=readed_cnt+1;
          sleep(50);
          if readed_cnt>=5 then
          begin
            tmp_int:=1/0;
          end;
        end;
      end;
    end;
    dt_curr := dt_curr + 1;
  end;
end;

function CalculateStatInfo(dt_begin, dt_end: tdatetime;
  isGlobal, isPerDay: boolean): TStatGlobalResult;
var
  tf: textfile;
  fp, tmp: string;
  dt_first, dt_last, dt_curr: tDateTime;
  st_res_type, st_name_len: string;
  res_type, name_len, name_pos, msg_len, msg_pos: integer;
  ev_name, ev_msg: string;

  arrStatElements: array of TStatElement;

  asel: integer;
  ael, ae_index: integer;
  aedl, aeddl, aed_index, aedd_index: integer;

  x, y, z: integer;
  found: boolean;
  tmp_int: integer;

  tmp_ext: Extended;
  readed:boolean;
  readed_cnt:integer;
begin
  Setlength(Result.r_arr_date, 0);
  Setlength(Result.r_arr_global, 0);


  Setlength(arrStatElements, 0);


  dt_first := int(dt_begin);
  dt_last := int(dt_end);
  dt_curr := int(dt_first);

  asel := 0;

  while dt_curr <= dt_last do
  begin
    fp := GetReportDataFilePath(dt_curr);
    if FileExists(fp) then
    begin
      AssignFile(tf, fp);

      readed:=false;
      readed_cnt:=0;
      while not readed do
      begin
        try
          reset(tf);

          while not EOF(tf) do
          begin
            readln(tf, tmp);

            st_res_type := MidStr(tmp, 1, 1);
            res_type := StrToInt(st_res_type);
            st_name_len := uStrUtils.GetFieldFromString(tmp, ' ', 2);
            name_len := StrToInt(st_name_len);
            name_pos := 4 + length(st_name_len);

            ev_name := MidStr(tmp, name_pos, name_len);
            msg_pos := 5 + length(st_name_len) + name_len;
            msg_len := length(tmp) - msg_pos + 1;
            ev_msg := MidStr(tmp, msg_pos, msg_len);

            asel := asel + 1;

            setlength(arrStatElements, asel);
            arrStatElements[asel - 1].r_date := dt_curr;
            arrStatElements[asel - 1].r_msg := ev_msg;
            arrStatElements[asel - 1].r_rslt := res_type;
            arrStatElements[asel - 1].r_event_name := ev_name;
          end;
          closefile(tf);
          readed:=true;
        except
          readed:=false;
          readed_cnt:=readed_cnt+1;
          sleep(50);
          if readed_cnt>=5 then
          begin
            tmp_ext:=1/0;
          end;
        end;
      end;
    end;
    dt_curr := dt_curr + 1;
  end;

  ael := 0;
  aedl := 0;
  aeddl := 0;
  for x := 1 to asel do
  begin
    if isGlobal then
    begin

      // event_name global
      found := False;
      for y := 1 to ael do
      begin
        if Result.r_arr_global[y - 1].r_event_name =
          arrStatElements[x - 1].r_event_name then
        begin
          ae_index := y - 1;
          found := True;
          Break;
        end;
      end;
      if not found then
      begin
        ael := ael + 1;
        setlength(Result.r_arr_global, ael);
        Result.r_arr_global[ael - 1].r_event_name := arrStatElements[x - 1].r_event_name;
        ae_index := ael - 1;
      end;

      // event_msg global
      found := False;
      for y := 1 to length(Result.r_arr_global[ae_index].r_arr) do
      begin
        if Result.r_arr_global[ae_index].r_arr[y - 1].r_msg =
          arrStatElements[x - 1].r_msg then
        begin
          Result.r_arr_global[ae_index].r_arr[y - 1].r_count :=
            Result.r_arr_global[ae_index].r_arr[y - 1].r_count + 1;
          found := True;
          Break;
        end;
      end;
      if not found then
      begin
        tmp_int := length(Result.r_arr_global[ae_index].r_arr);
        setlength(Result.r_arr_global[ae_index].r_arr, tmp_int + 1);
        Result.r_arr_global[ae_index].r_arr[tmp_int].r_count := 1;
        Result.r_arr_global[ae_index].r_arr[tmp_int].r_msg :=
          arrStatElements[x - 1].r_msg;
        Result.r_arr_global[ae_index].r_arr[tmp_int].r_rslt :=
          arrStatElements[x - 1].r_rslt;
        Result.r_arr_global[ae_index].r_arr[tmp_int].r_persent := 0;
      end;
    end;

    if isPerDay then
    begin
      // event_name day
      found := False;
      for y := 1 to aedl do
      begin
        if (Result.r_arr_date[y - 1].r_event_name =
          arrStatElements[x - 1].r_event_name) then
        begin
          aed_index := y - 1;
          found := True;
          Break;
        end;
      end;
      if not found then
      begin
        aedl := aedl + 1;
        setlength(Result.r_arr_date, aedl);
        Result.r_arr_date[aedl - 1].r_event_name := arrStatElements[x - 1].r_event_name;
        aed_index := aedl - 1;
      end;

      // event_date day
      found := False;
      for z := 1 to aeddl do
      begin
        if (Result.r_arr_date[y - 1].r_arr[z - 1].r_event_date =
          arrStatElements[x - 1].r_date) then
        begin
          aedd_index := z - 1;
          found := True;
          Break;
        end;
      end;
      if not found then
      begin
        aeddl := aeddl + 1;
        setlength(Result.r_arr_date[aed_index].r_arr, aeddl);
        Result.r_arr_date[aed_index].r_arr[aeddl - 1].r_event_date :=
          arrStatElements[x - 1].r_date;
        aedd_index := aeddl - 1;
      end;

      // event_msg day
      found := False;
      for y := 1 to length(Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr) do
      begin
        if Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[y - 1].r_msg =
          arrStatElements[x - 1].r_msg then
        begin
          Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[y - 1].r_count :=
            Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[y - 1].r_count + 1;
          found := True;
          Break;
        end;
      end;
      if not found then
      begin
        tmp_int := length(Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr);
        setlength(Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr, tmp_int + 1);
        Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[tmp_int].r_count := 1;
        Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[tmp_int].r_msg :=
          arrStatElements[x - 1].r_msg;
        Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[tmp_int].r_rslt :=
          arrStatElements[x - 1].r_rslt;
        Result.r_arr_date[aed_index].r_arr[aedd_index].r_arr[tmp_int].r_persent := 0;
      end;
    end;
  end;

  // calclulations
  if isPerDay then
  begin
    for x := 1 to length(Result.r_arr_date) do
    begin
      for y := 1 to length(Result.r_arr_date[x - 1].r_arr) do
      begin
        tmp_int := 0;
        for z := 1 to length(Result.r_arr_date[x - 1].r_arr[y - 1].r_arr) do
        begin
          tmp_int := tmp_int + Result.r_arr_date[x - 1].r_arr[y -
            1].r_arr[z - 1].r_count;
        end;
        for z := 1 to length(Result.r_arr_date[x - 1].r_arr[y - 1].r_arr) do
        begin
          Result.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_persent :=
            round(100 * Result.r_arr_date[x - 1].r_arr[y - 1].r_arr[z - 1].r_count / tmp_int);
        end;
      end;
    end;
  end;
  if isGlobal then
  begin
    for x := 1 to length(Result.r_arr_global) do
    begin
      tmp_int := 0;
      for y := 1 to length(Result.r_arr_global[x - 1].r_arr) do
      begin
        tmp_int := tmp_int + Result.r_arr_global[x - 1].r_arr[y - 1].r_count;
      end;
      for y := 1 to length(Result.r_arr_global[x - 1].r_arr) do
      begin
        Result.r_arr_global[x - 1].r_arr[y - 1].r_persent :=
          round(100 * Result.r_arr_global[x - 1].r_arr[y - 1].r_count / tmp_int);
      end;
    end;
  end;
end;

procedure ReportProgressIndicator(sts:string; sock: TTCPBlockSocket);
begin
  uNetwork.SendStringViaSocket(sock,'rep_rdy'+sts,SNDRCVTimeout);
end;

end.
