-- Migration: 20260508_fix_all_days_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail pour les jours de semaine (7h00 -> 6h01).
-- Structure corrigée : Utilise ThursdayStart et FridayStart.
-- Architecte: Senior Software Architect

-- 1. Vérification avant mise à jour
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, ThursdayStart, FridayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

-- 2. Mise à jour de l'heure de début pour les jours de semaine uniquement
-- On cible le quart de "Jour" (généralement ShiftId = 1)

UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 06:01:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2)
WHERE ShiftId = 1;

-- 3. Vérification après mise à jour
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, ThursdayStart, FridayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

GO
