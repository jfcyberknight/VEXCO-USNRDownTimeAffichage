-- Requête pour fpusnr_shift_logdetail (Architect Standard)
SELECT uuid, LogId, MachineId, StemId, DateTime, SpeciesName, GradeName, Sweep, Taper, Ovality, SmallEndDiameter, LargeEndDiameter, Shift, IsMetric, PieceCount, ProductionValue, MarketValue, UserVolume, AdjustedGrossVol, NominalLumberVolume, LogNumber, Length, DiameterDescription, LengthDescription, BinId, SolutionType, FiberClass, UserVolume_1, OptTime, ForceTerm, IsSimulation, ChipVolume, ChipValue, SawdustVolume, SawdustValue, Confidence, Harmonic, CurveDeflection, EdgerFlitchCount, SubWidthBoardCount, Crew, SweepClass, OptTimeClass, AcousticVelocity, VelocityClass, RealDateTime, fld_quart, fld_DateQuart, fld_TempsCoupe, fld_TempsDowntime, IDUSNR
FROM fpusnr_shift_logdetail
WHERE uuid = {pUuid}
