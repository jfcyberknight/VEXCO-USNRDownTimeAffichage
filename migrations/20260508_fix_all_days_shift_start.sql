-- Migration: 20260508_fix_all_days_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail pour les jours de semaine (7h00 -> 6h01). Samedi et Dimanche restent à NULL.
-- Architecte: Senior Software Architect

-- 1. Vérification avant mise à jour (incluant Samedi/Dimanche pour confirmer l'état NULL)
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, FridayStart, SaturdayStart, SundayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

-- 2. Mise à jour de l'heure de début pour les jours de semaine uniquement
-- On cible le quart de "Jour" (généralement ShiftId = 1)
-- Samedi et Dimanche ne sont volontairement pas inclus pour rester à NULL.

UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2)
WHERE ShiftId = 1;

-- Note: ThursdayStart semble manquant dans le schéma technique (fpusnr_shifttimes). 
-- S'il est ajouté plus tard, il devra suivre la même règle (06:01:00).

-- 3. Vérification après mise à jour
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, FridayStart, SaturdayStart, SundayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

GO
