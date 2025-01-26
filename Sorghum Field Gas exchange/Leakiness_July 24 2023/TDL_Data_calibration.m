%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Yu Wang https://github.com/yuwangcn yuwangcn@illnois.edu yuwangpicb@gmail.com
% 2021-09
% TDL raw data annalysis
% Leakiness estimation based on TDL and LI6800 data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FinalValues=TDL_Data_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle)
CalibrationAvgt=CalibrationAvg_Cycle(:,3:5);
SampleC12OO=Samplematrix_Cycle(:,6);
SampleC13OO=Samplematrix_Cycle(:,7);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Correction 
%Constants	
RPDB_13=0.0112372;
RVPDB_13=0.0111797;
isotopologues_other_C=0.00474;
isotopologues_other_O=0.01185;
RVSMOW_18=0.0020052;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calibration Tank 1
d13CtankVPDB=-11.50;
TotalCO2=443.308;%(¦Ìmol mol-1)	
d18Otank=-8.05;
%Calculated Values	
C12OOAndC13OO=TotalCO2*(1-isotopologues_other_C);%441.2067201;
R13=RVPDB_13*(1+d13CtankVPDB/1000);%0.011051133;s=sprintf('%1.8f',R13)
C12OO=C12OOAndC13OO/(1+R13);%436.3841803;% (¦Ìmol mol-1)	
C13OO=R13*C12OO;%4.822539812;% (¦Ìmol mol-1)	
%Standard gas tanks
dCOO2500ppmtank_VPDB=-12.325;
dCOO10percenttank_VPDB=-11.505;
dCOO100percenttank_VPDB=-25.444;

CalibrationAvgt(:,4)=(CalibrationAvgt(:,2)+CalibrationAvgt(:,3))./(1-isotopologues_other_C);%RawC12OOandC13OO
CalibrationAvgt(:,5)=((CalibrationAvgt(:,3)./CalibrationAvgt(:,2))/(RVPDB_13)-1)*1000;%Rawd13C

ADJ0_C12OO=CalibrationAvgt(:,2)-CalibrationAvgt(1,2);
ADJ0_C13OO=CalibrationAvgt(:,3)-CalibrationAvgt(1,3);
ADJ0_SampleC12OO=SampleC12OO-CalibrationAvgt(1,2);
ADJ0_SampleC13OO=SampleC13OO-CalibrationAvgt(1,3);
%Adjust for 12CO2 calibration	
C12OOgain=C12OO/ADJ0_C12OO(5);
ADJC12_C12OO=ADJ0_C12OO*C12OOgain;
ADJC12_SampleC12OO=ADJ0_SampleC12OO*C12OOgain;
%Adjust for 13CO2 calibration
ExpectedC13z=((dCOO10percenttank_VPDB/1000+1)*RVPDB_13)*ADJC12_C12OO(1:4);
p = polyfit(ADJ0_C13OO(1:4),ExpectedC13z,2);
ADJC13_C13OO=power(ADJ0_C13OO,2)*p(1)+ADJ0_C13OO*p(2)+p(3);
ADJC13_SampleC13OO=power(ADJ0_SampleC13OO,2)*p(1)+ADJ0_SampleC13OO*p(2)+p(3);
FinalValuesCali(:,1)=CalibrationAvg_Cycle(:,1);
FinalValuesCali(:,2)=CalibrationAvgt(:,1);
FinalValuesCali(:,3)=floor(CalibrationAvg_Cycle(:,2)/10);
FinalValuesCali(:,4)=ADJC12_C12OO;
FinalValuesCali(:,5)=ADJC13_C13OO;
FinalValuesSample(:,4)=ADJC12_SampleC12OO;
FinalValuesSample(:,5)=ADJC13_SampleC13OO;
FinalValuesSample(:,3)=Samplematrix_Cycle(:,1);
FinalValuesSample(:,2)=13;
FinalValuesSample(:,1)=Samplematrix_Cycle(:,21);
FinalValues=[FinalValuesCali;FinalValuesSample];
FinalValues(:,6)=FinalValues(:,4)+FinalValues(:,5);
FinalValues(:,7)=((FinalValues(:,5)./FinalValues(:,4))/RVPDB_13-1)*1000;
end