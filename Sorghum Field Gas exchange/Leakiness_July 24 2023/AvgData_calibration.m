%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The code is developed by Yu Wang
% 2022-06
%TDL average raw data annalysis
%Calibration for each cycle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FinalValues=AvgData_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle)
%%%%%
%Two points calibration
global CalibrationAvgt;
global FinalValues;
CalibrationAvgt(:,1)=CalibrationAvg_Cycle(:,3);
CalibrationAvgt(:,2)=CalibrationAvg_Cycle(:,4);
CalibrationAvgt(:,3)=CalibrationAvg_Cycle(:,5);
RefC12OO=CalibrationAvgt(end,2);
RefC13OO=CalibrationAvgt(end,3);
SampleC12OO=Samplematrix_Cycle(:,6);
SampleC13OO=Samplematrix_Cycle(:,7);
SampNo=size(Samplematrix_Cycle(:,6),1);
%Test
% CalibrationAvgt(1,2)=95;
% CalibrationAvgt(1,3)=1;
% CalibrationAvgt(2,2)=480;
% CalibrationAvgt(2,3)=5;
% SampleC12OO=300;
% SampleC13OO=3;

RVPDB_13=0.0111797;
%Tank1
% Tank1_CO2_12=94.5554901637192;
% Tank1_CO2_13=1.05210181530221;
%Tank2
% Tank2_CO2_12=480.391558825833;
% Tank2_CO2_13=5.346486418;

Tank1_CO2_12=70.7102371;
Tank1_CO2_13=0.758488551;
Tank2_CO2_12=1464.098453;
Tank2_CO2_13=15.71439664;

k12=(Tank2_CO2_12-Tank1_CO2_12)/(CalibrationAvgt(2,2)-CalibrationAvgt(1,2));
a12=Tank2_CO2_12-CalibrationAvgt(2,2)*k12;
k13=(Tank2_CO2_13-Tank1_CO2_13)/(CalibrationAvgt(2,3)-CalibrationAvgt(1,3));
a13=Tank2_CO2_13-CalibrationAvgt(2,3)*k13;

ADJRefC12OO=RefC12OO.*k12+a12;
ADJRefC13OO=RefC13OO.*k13+a13;


Cali12=[Tank1_CO2_12;Tank2_CO2_12;ADJRefC12OO];
Cali13=[Tank1_CO2_13;Tank2_CO2_13;ADJRefC13OO];

for i=1:SampNo

ADJC12_SampleC12OO(i)=SampleC12OO(i).*k12+a12;
ADJC13_SampleC13OO(i)=SampleC13OO(i).*k13+a13;

end

FinalValuesCali(:,1)=CalibrationAvg_Cycle(:,1);
FinalValuesCali(:,2)=CalibrationAvgt(:,1);
FinalValuesCali(:,3)=round(CalibrationAvg_Cycle(:,2)/10);
FinalValuesCali(:,4)=Cali12;
FinalValuesCali(:,5)=Cali13;

FinalValuesSample(:,3)=Samplematrix_Cycle(:,1);
FinalValuesSample(:,2)=Samplematrix_Cycle(:,3);
FinalValuesSample(:,1)=Samplematrix_Cycle(:,21);
FinalValuesSample(:,4)=ADJC12_SampleC12OO;
FinalValuesSample(:,5)=ADJC13_SampleC13OO;
FinalValues=[FinalValuesCali;FinalValuesSample];
FinalValues(:,6)=FinalValues(:,4)+FinalValues(:,5);
FinalValues(:,7)=((FinalValues(:,5)./FinalValues(:,4))/RVPDB_13-1)*1000;

end