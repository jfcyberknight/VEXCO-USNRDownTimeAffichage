-- Requête pour fpusnr_downtime_view_traiter (Architect Standard)
SELECT uuid, idtbl_perteTempstraite, fld_PT_IdPLC, fld_PT_IdQuart, fld_DateDebut, fld_DateFin, fld_Duree, fld_Equipement, fld_Description, fld_DateRapportJour, fld_QuartRapJour, fld_DateQuart, fld_Quart, fld_NoDowntime, fld_Commentaire, fld_TypePause, fld_PasUnArret, fld_dateModif, fld_ModifierPar
FROM fpusnr_downtime_view_traiter
WHERE uuid = {pUuid}
