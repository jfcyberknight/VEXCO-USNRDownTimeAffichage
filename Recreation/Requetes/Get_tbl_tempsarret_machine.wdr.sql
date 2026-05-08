-- Requête pour tbl_tempsarret_machine (Architect Standard)
SELECT uuid, idTempsArretMachine, fld_Machine, fld_TempsArret, tbl_tempsarret_machine$Machin
FROM tbl_tempsarret_machine
WHERE uuid = {pUuid}
