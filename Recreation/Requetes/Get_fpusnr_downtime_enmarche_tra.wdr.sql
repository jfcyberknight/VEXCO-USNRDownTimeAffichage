-- Requête pour fpusnr_downtime_enmarche_tra
SELECT idtbl_perteTempstraite, fld_PT_IdPLC, fld_PT_IdQuart, fld_DateDebut, fld_DateFin, fld_Duree, fld_Equipement, fld_Description, fld_DateRapportJour, fld_QuartRapJour, fld_DateQuart, fld_Quart, fld_NoDowntime
FROM fpusnr_downtime_enmarche_tra
WHERE 1=1
