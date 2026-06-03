SELECT 
	'Chariot' AS Machine,	
	CASE 
		WHEN {Paramfld_Quart} = 1 THEN 'Jour'
		WHEN {Paramfld_Quart} = 2 THEN 'Soir'
		ELSE 'Nuit' 
	END AS Shift,	
	fpusnr_downtime_view_traiter.fld_Duree AS Duration,	
	CAST(fpusnr_downtime_view_traiter.fld_DateDebut AS DATE) AS DATETIME,	
	fpusnr_downtime_view_traiter.fld_DateDebut AS StartTime,	
	fpusnr_downtime_view_traiter.fld_DateFin AS EndTime,	
	fpusnr_downtime_view_traiter.fld_Commentaire AS Commentaire,	
	{Paramfld_Quart} AS fld_Quart,	
	LOWER(fpusnr_downtime_view_traiter.fld_Description) AS DowntimeCode,	
	fpusnr_downtime_view_traiter.fld_PasUnArret AS fld_PasUnArret
FROM 
	fpusnr_downtime_view_traiter
WHERE 
	-- Filtre sur la plage horaire exacte du quart (calculée par WinDev à partir de fpusnr_shifttimes)
	fpusnr_downtime_view_traiter.fld_DateDebut >= {ParamShiftStartDateTime}
	AND fpusnr_downtime_view_traiter.fld_DateDebut < {ParamShiftEndDateTime}
	AND	
	(
		fpusnr_downtime_view_traiter.fld_PasUnArret <> 1
		OR	fpusnr_downtime_view_traiter.fld_PasUnArret IS NULL 
	)
	AND	fpusnr_downtime_view_traiter.fld_Duree >= {ParamDuration}
ORDER BY 
	StartTime ASC
