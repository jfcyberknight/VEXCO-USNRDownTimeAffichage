-- Requête pour tbl_VerificationUsnr (Architect Standard)
SELECT uuid, IdVerification, fld_Date, fld_Quart, fld_EnvoiFinal, fld_Usager, fld_DateFait, fld_DateApprouver, fld_ApprouverPar, PK_tbl_VerificationUsnr
FROM tbl_VerificationUsnr
WHERE uuid = {pUuid}
