%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Yu Wang https://github.com/yuwangcn yuwangcn@illnois.edu yuwangpicb@gmail.com
% 2021-09
% TDL raw data annalysis
% Leakiness estimation based on TDL and LI6800 data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Leakiness = TDL_leakiness_all(TDLfile, licorfile, TDLStartimeH, TDLStartimeM,TDLStartimeS,LicorStartTimeH,LicorStartTimeM,LicorStartTimeS, FigName,Rd,Output)
global SamplematrixRef_cal
SamplematrixRef_cal=TDL_RawData_correction(TDLfile, TDLStartimeH, TDLStartimeM,TDLStartimeS,LicorStartTimeH,LicorStartTimeM,LicorStartTimeS);
Leakiness=TDL_Leakiness(SamplematrixRef_cal,licorfile,Rd,FigName,Output);
