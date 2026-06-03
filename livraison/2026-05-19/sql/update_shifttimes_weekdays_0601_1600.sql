-- Lun. : début 06:01, Mar.-ven. : début 07:01, fin 16:00 — week-end inchangé
UPDATE fpusnr_shifttimes
SET
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    MondayEnd   = CAST(CONVERT(VARCHAR(10), MondayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 07:01:00' AS DATETIME2),
    TuesdayEnd   = CAST(CONVERT(VARCHAR(10), TuesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 07:01:00' AS DATETIME2),
    WednesdayEnd   = CAST(CONVERT(VARCHAR(10), WednesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 07:01:00' AS DATETIME2),
    ThursdayEnd   = CAST(CONVERT(VARCHAR(10), ThursdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 07:01:00' AS DATETIME2),
    FridayEnd   = CAST(CONVERT(VARCHAR(10), FridayEnd, 120)   + ' 16:00:00' AS DATETIME2)
WHERE ShiftId = 1;
