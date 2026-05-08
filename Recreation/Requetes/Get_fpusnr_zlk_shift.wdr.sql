-- Requête pour fpusnr_zlk_shift (Architect Standard)
SELECT uuid, ShiftNumber, ShiftName, PLCShiftNumber
FROM fpusnr_zlk_shift
WHERE uuid = {pUuid}
