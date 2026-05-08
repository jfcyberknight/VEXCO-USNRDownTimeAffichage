-- Requête pour fpusnr_downtime_view_autre
SELECT Machine, DowntimeCode, Shift, Duration, DateTime, RecordCount, TagStartTime, TagNames, TagValues, TagDateTimeEnd, GroupType, StartTime, fld_NoDowntime
FROM fpusnr_downtime_view_autre
WHERE 1=1
