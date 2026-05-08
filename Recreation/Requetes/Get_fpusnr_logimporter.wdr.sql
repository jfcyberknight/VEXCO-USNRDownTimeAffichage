-- Requête pour fpusnr_logimporter (Architect Standard)
SELECT uuid, fld_IDNo, fld_Date, IDLogUSNR, fld_DateIdLogUSNR
FROM fpusnr_logimporter
WHERE uuid = {pUuid}
