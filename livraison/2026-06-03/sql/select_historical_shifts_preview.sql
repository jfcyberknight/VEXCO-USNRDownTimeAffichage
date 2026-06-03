-- Vérification: Aperçu des enregistrements qui seront modifiés par la migration historique
-- Exécuter AVANT d'appliquer 20260520_fix_historical_shifts.sql pour valider l'impact.

USE fpusnr;
GO

SET DATEFIRST 7;

-- 1. Table active: fpusnr_downtime_view
SELECT 'fpusnr_downtime_view' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(StartTime) AS [PlusAncien],
       MAX(StartTime) AS [PlusRecent]
FROM fpusnr_downtime_view
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 2. Table active autre: fpusnr_downtime_view_autre
SELECT 'fpusnr_downtime_view_autre' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(StartTime) AS [PlusAncien],
       MAX(StartTime) AS [PlusRecent]
FROM fpusnr_downtime_view_autre
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 3. Table active traiter: fpusnr_downtime_view_traiter
SELECT 'fpusnr_downtime_view_traiter' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(fld_DateDebut) AS [PlusAncien],
       MAX(fld_DateDebut) AS [PlusRecent]
FROM fpusnr_downtime_view_traiter
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3;

-- 4. Table archive: fpusnr_Arc_downtime_view
SELECT 'fpusnr_Arc_downtime_view' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(StartTime) AS [PlusAncien],
       MAX(StartTime) AS [PlusRecent]
FROM fpusnr_Arc_downtime_view
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 5. Table archive autre: fpusnr_arc_downtime_view_autre
SELECT 'fpusnr_arc_downtime_view_autre' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(StartTime) AS [PlusAncien],
       MAX(StartTime) AS [PlusRecent]
FROM fpusnr_arc_downtime_view_autre
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit';

-- 6. Table archive traiter: fpusnr_arc_downtime_view_traiter
SELECT 'fpusnr_arc_downtime_view_traiter' AS [Table],
       COUNT(*) AS [NbLignes],
       MIN(fld_DateDebut) AS [PlusAncien],
       MAX(fld_DateDebut) AS [PlusRecent]
FROM fpusnr_arc_downtime_view_traiter
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3;

GO

-- Détail des enregistrements impactés (limité à 50 par table pour lisibilité)

-- Détail table active
SELECT TOP 50 'fpusnr_downtime_view' AS [Table],
       StartTime, EndTime, Shift, DateTime,
       DATENAME(WEEKDAY, StartTime) AS [JourSemaine]
FROM fpusnr_downtime_view
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit'
ORDER BY StartTime DESC;

-- Détail table active autre
SELECT TOP 50 'fpusnr_downtime_view_autre' AS [Table],
       StartTime, EndTime, Shift, DateTime,
       DATENAME(WEEKDAY, StartTime) AS [JourSemaine]
FROM fpusnr_downtime_view_autre
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit'
ORDER BY StartTime DESC;

-- Détail table active traiter
SELECT TOP 50 'fpusnr_downtime_view_traiter' AS [Table],
       fld_DateDebut, fld_DateFin, fld_Quart, fld_DateQuart,
       DATENAME(WEEKDAY, fld_DateDebut) AS [JourSemaine]
FROM fpusnr_downtime_view_traiter
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3
ORDER BY fld_DateDebut DESC;

-- Détail table archive
SELECT TOP 50 'fpusnr_Arc_downtime_view' AS [Table],
       StartTime, EndTime, Shift, DateTime,
       DATENAME(WEEKDAY, StartTime) AS [JourSemaine]
FROM fpusnr_Arc_downtime_view
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit'
ORDER BY StartTime DESC;

-- Détail table archive autre
SELECT TOP 50 'fpusnr_arc_downtime_view_autre' AS [Table],
       StartTime, EndTime, Shift, DateTime,
       DATENAME(WEEKDAY, StartTime) AS [JourSemaine]
FROM fpusnr_arc_downtime_view_autre
WHERE DATEPART(WEEKDAY, StartTime) = 2
  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
  AND Shift = 'Nuit'
ORDER BY StartTime DESC;

-- Détail table archive traiter
SELECT TOP 50 'fpusnr_arc_downtime_view_traiter' AS [Table],
       fld_DateDebut, fld_DateFin, fld_Quart, fld_DateQuart,
       DATENAME(WEEKDAY, fld_DateDebut) AS [JourSemaine]
FROM fpusnr_arc_downtime_view_traiter
WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
  AND fld_Quart = 3
ORDER BY fld_DateDebut DESC;

GO
