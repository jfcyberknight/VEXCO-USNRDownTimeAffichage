-- Requête pour fpusnr_shifttimes
SELECT ShiftId, MondayStart, MondayEnd, TuesdayStart, TuesdayEnd, WednesdayStart, WednesdayEnd, ThursdayStart, ThursdayEnd, FridayStart, FridayEnd, SaturdayStart, SaturdayEnd, SundayStart, SundayEnd, manualOverride, isCached
FROM fpusnr_shifttimes
WHERE 1=1
