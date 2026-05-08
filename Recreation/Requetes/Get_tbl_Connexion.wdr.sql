-- Requête pour tbl_Connexion (Architect Standard)
SELECT uuid, IDtbl_Connexion, fld_NomConnexion, fld_Serveur, fld_MotPasse, fld_BaseDeDonnee
FROM tbl_Connexion
WHERE uuid = {pUuid}
