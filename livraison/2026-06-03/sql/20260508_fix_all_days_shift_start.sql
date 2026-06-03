-- Migration: 20260508_fix_all_days_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail du lundi à 06h01 
--              et maintien/réinitialisation des autres jours à 07h01.
-- Architecte: Senior Software Architect

USE fpusnr;
GO

UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 07:01:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 07:01:00' AS DATETIME2),
    ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 07:01:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 07:01:00' AS DATETIME2)
WHERE ShiftId = 1;

GO
