-- Requête pour fpusnr_DowntimeStatusConfig (Architect Standard)
SELECT uuid, Code, Colour, Group, Renamable, Description, Source, PK_DowntimeStatusConfig
FROM fpusnr_DowntimeStatusConfig
WHERE uuid = {pUuid}
