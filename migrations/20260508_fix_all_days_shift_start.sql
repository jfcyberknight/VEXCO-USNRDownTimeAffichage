-- Migration: 20260508_fix_all_days_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail pour tous les jours de semaine (7h00 -> 6h01).
-- Note: Le schéma semble avoir des noms de colonnes inversés ou erronés (ex: ThursdayEnd utilisé pour le début du jeudi).
-- Architecte: Senior Software Architect

-- 1. Vérification avant mise à jour
SELECT 
    ShiftId, 
    MondayStart, 
    TuesdayStart, 
    WednesdayStart, 
    ThursdayEnd AS ThursdayStart_Candidate, -- Suspecté d'être le début du Jeudi
    FridayStart,
    SundayEnd AS FridayEnd_Candidate -- Suspecté d'être la fin du Vendredi ou début ?
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

-- 2. Mise à jour de l'heure de début pour tous les jours de semaine
-- On applique 06:01:00 à toutes les colonnes identifiées comme gérant les débuts de quarts.

UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    ThursdayEnd = CAST(CONVERT(VARCHAR(10), ThursdayEnd, 120) + ' 06:01:00' AS DATETIME2), -- Correction pour le Jeudi
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2)
WHERE ShiftId = 1;

-- 3. Vérification après mise à jour
SELECT 
    ShiftId, 
    MondayStart, 
    TuesdayStart, 
    WednesdayStart, 
    ThursdayEnd AS ThursdayStart_Updated,
    FridayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

GO
