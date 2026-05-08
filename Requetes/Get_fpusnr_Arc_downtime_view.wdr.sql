-- Requête pour fpusnr_Arc_downtime_view
SELECT Machine, DowntimeCode, Shift, Crew, Duration, DateTime, RecordCount, TagNames, TagValues, TagDateTimeEnd, GroupType, StartTime, EndTime, fld_NoDowntime
FROM fpusnr_Arc_downtime_view
WHERE 1=1
