-- Requête pour tbl_TempsPause (Architect Standard)
SELECT uuid, IDTypePause, fld_DescriptionPause, fld_Duree
FROM tbl_TempsPause
WHERE uuid = {pUuid}
