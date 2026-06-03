-- Lecture snapshot : quart Jour (ShiftId = 1)
USE fpusnr;
GO

SELECT 
    MondayStart, MondayEnd, 
    TuesdayStart, TuesdayEnd, 
    WednesdayStart, WednesdayEnd, 
    ThursdayStart, ThursdayEnd, 
    FridayStart, FridayEnd, 
    SaturdayStart, SaturdayEnd, 
    SundayStart, SundayEnd 
FROM fpusnr_shifttimes
WHERE ShiftId = 1;
