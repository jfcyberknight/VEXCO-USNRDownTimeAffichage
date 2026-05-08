-- Requête pour fpusnr_downtime_view (Architect Standard)
SELECT uuid, Machine, DowntimeCode, Shift, Duration, DateTime, RecordCount, TagStartTime, TagNames, TagValues, TagDateTimeEnd, GroupType, StartTime, fld_NoDowntime, fld_Commentaire, fld_PasUnArret, fld_DurationBase, fld_DateModif, fld_ModifierPar, _dta_index_fpusnr_downtime_vi, StartTimeDownTimeCodeShiftno, idtbl_perteTempstraite, fld_PT_IdPLC, fld_PT_IdQuart, fld_DateDebut, fld_DateFin, fld_Duree, fld_Equipement, fld_Description, fld_DateRapportJour, fld_QuartRapJour, fld_DateQuart, fld_Quart, fld_TypePause, fld_dateModif
FROM fpusnr_downtime_view
WHERE uuid = {pUuid}
