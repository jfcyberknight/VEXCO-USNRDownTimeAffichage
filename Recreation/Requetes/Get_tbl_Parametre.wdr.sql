-- Requête pour tbl_Parametre (Architect Standard)
SELECT uuid, fld_IDParam, fld_PlusPetiteValeur, fld_EnleverDuRapport
FROM tbl_Parametre
WHERE uuid = {pUuid}
