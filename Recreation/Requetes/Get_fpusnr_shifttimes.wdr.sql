-- Requête pour fpusnr_shifttimes (Architect Standard)
SELECT uuid, ShiftId, MondayStart, MondayEnd, TuesdayStart, TuesdayEnd, WednesdayStart, WednesdayEnd, ThursdayEnd, FridayStart, SaturdayStart, SaturdayEnd, SundayStart, SundayEnd, manualOverride, isCached
FROM fpusnr_shifttimes
WHERE uuid = {pUuid}
