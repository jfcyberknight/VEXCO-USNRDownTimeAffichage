-- Migration: 20260520_fix_historical_shifts.sql
-- Description: Met à jour le champ Shift et la date de production (DateTime/fld_DateQuart)
--              dans les tables d'arrêts pour le lundi matin entre 06:01 et 07:00 (lundi uniquement).
-- Architecte: Senior Software Architect

-- 1. Table active: fpusnr_downtime_view
UPDATE fpusnr_downtime_view
SET Shift = 'Jour',
    DateTime = CAST(StartTime AS DATE)
WHERE DATEPART(WEEKDAY, StartTime) = 2 -- Lundi (en considérant DATEFIRST = 7 par défaut, dimanche = 1)
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 2. Table active autre: fpusnr_downtime_view_autre
UPDATE fpusnr_downtime_view_autre
SET Shift = 'Jour',
    DateTime = CAST(StartTime AS DATE)
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 3. Table active traiter: fpusnr_downtime_view_traiter
UPDATE fpusnr_downtime_view_traiter
SET fld_Quart = 1,
    fld_DateQuart = CAST(fld_DateDebut AS DATE),
    fld_QuartRapJour = 1,
    fld_DateRapportJour = CAST(fld_DateDebut AS DATE)
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3;

-- 4. Table archive: fpusnr_Arc_downtime_view
UPDATE fpusnr_Arc_downtime_view
SET Shift = 'Jour',
    DateTime = CAST(StartTime AS DATE)
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 5. Table archive autre: fpusnr_arc_downtime_view_autre
UPDATE fpusnr_arc_downtime_view_autre
SET Shift = 'Jour',
    DateTime = CAST(StartTime AS DATE)
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 6. Table archive traiter: fpusnr_arc_downtime_view_traiter
UPDATE fpusnr_arc_downtime_view_traiter
SET fld_Quart = 1,
    fld_DateQuart = CAST(fld_DateDebut AS DATE),
    fld_QuartRapJour = 1,
    fld_DateRapportJour = CAST(fld_DateDebut AS DATE)
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3;

GO
