-- Migration: 20260508_fix_all_days_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail pour tous les jours de la semaine (7h00 -> 6h01).
-- Architecte: Senior Software Architect

-- 1. Vérification des quarts actuels
-- SELECT ShiftNumber, ShiftName FROM fpusnr_zlk_shift;

-- 2. Vérification avant mise à jour
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, FridayStart, SaturdayStart, SundayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

-- 3. Mise à jour de l'heure de début pour tous les jours
-- On cible le quart de "Jour" (généralement ShiftId = 1)
-- On applique 06:01:00 à tous les jours disponibles dans la structure.

UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2),
    SaturdayStart = CAST(CONVERT(VARCHAR(10), SaturdayStart, 120) + ' 06:01:00' AS DATETIME2),
    SundayStart = CAST(CONVERT(VARCHAR(10), SundayStart, 120) + ' 06:01:00' AS DATETIME2)
WHERE ShiftId = 1;

-- Note: ThursdayStart semble manquant dans le schéma ou nommé différemment. 
-- S'il existe au moment de l'exécution, il devra être ajouté.

-- 4. Vérification après mise à jour
SELECT 
    ShiftId, 
    MondayStart, TuesdayStart, WednesdayStart, FridayStart, SaturdayStart, SundayStart
FROM fpusnr_shifttimes
WHERE ShiftId = 1;

-- 5. Mise à jour de la fin du quart précédent si nécessaire (Quart de Nuit)
-- Pour éviter les chevauchements, la fin du quart de nuit doit correspondre au début du quart de jour.
-- UPDATE fpusnr_shifttimes
-- SET SundayEnd = CAST(CONVERT(VARCHAR(10), SundayEnd, 120) + ' 06:01:00' AS DATETIME2),
--     MondayEnd = ...
-- WHERE ShiftId = 2; -- Supposant ShiftId 2 = Nuit

GO
