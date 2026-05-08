-- Requête pour fpusnr_arc_logimporter (Architect Standard)
SELECT uuid, fld_IDNo, fld_Date, IDLogUSNR
FROM fpusnr_arc_logimporter
WHERE uuid = {pUuid}
