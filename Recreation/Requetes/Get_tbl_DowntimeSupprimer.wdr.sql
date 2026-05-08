-- Requête pour tbl_DowntimeSupprimer (Architect Standard)
SELECT uuid, fld_DowntimeDelete, fld_StartTime
FROM tbl_DowntimeSupprimer
WHERE uuid = {pUuid}
