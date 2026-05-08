-- Requête pour fpusnr_arc_downtime_view_autr
SELECT Machine, DowntimeCode, Shift, Duration, DateTime, RecordCount, TagStartTime, TagNames, TagValues, TagDateTimeEnd, GroupType, StartTime, fld_NoDowntime
FROM fpusnr_arc_downtime_view_autr
WHERE 1=1
