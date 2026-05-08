-- Requête pour tbl_Trace (Architect Standard)
SELECT uuid, fld_NoTrace, fld_Fenetre, fld_Usager, fld_StartTime, fld_DateheureModifier, fld_Commentaire
FROM tbl_Trace
WHERE uuid = {pUuid}
