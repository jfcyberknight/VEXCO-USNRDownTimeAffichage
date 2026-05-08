-- Requête pour fpusnr_downtimemessage (Architect Standard)
SELECT uuid, fld_IdDownTimeMessage, fld_DatedernierDowntime, fld_Messageenvoyer
FROM fpusnr_downtimemessage
WHERE uuid = {pUuid}
