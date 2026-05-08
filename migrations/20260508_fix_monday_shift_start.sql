-- Migration: 20260508_fix_monday_shift_start.sql
-- Description: Ajustement de l'heure de début du quart de travail du lundi matin (7h00 -> 6h01).
-- Architecte: Senior Software Architect

-- 1. Vérification des quarts actuels
-- SELECT ShiftNumber, ShiftName FROM fpusnr_zlk_shift;

-- 2. Mise à jour de l'heure de début pour le lundi
-- On cible le quart de "Jour" (généralement ShiftId = 1)
-- Si le système utilise une date de base (ex: 1900-01-01), on préserve la partie date.

UPDATE fpusnr_shifttimes
SET MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2)
WHERE ShiftId = 1;

-- 3. Mise à jour de la fin du quart précédent si nécessaire (Quart de Nuit)
-- Pour éviter les chevauchements, la fin du quart de nuit du dimanche/lundi 
-- doit correspondre au début du quart de jour.
-- UPDATE fpusnr_shifttimes
-- SET SundayEnd = CAST(CONVERT(VARCHAR(10), SundayEnd, 120) + ' 06:01:00' AS DATETIME2)
-- WHERE ShiftId = 2; -- Supposant ShiftId 2 = Nuit

GO
