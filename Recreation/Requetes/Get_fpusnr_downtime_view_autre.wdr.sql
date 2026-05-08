-- Requête pour fpusnr_downtime_view_autre (Architect Standard)
SELECT uuid, Machine, DowntimeCode, Shift, Duration, DateTime, RecordCount, TagStartTime, TagNames, TagValues, TagDateTimeEnd, GroupType, StartTime, fld_NoDowntime
FROM fpusnr_downtime_view_autre
WHERE uuid = {pUuid}
