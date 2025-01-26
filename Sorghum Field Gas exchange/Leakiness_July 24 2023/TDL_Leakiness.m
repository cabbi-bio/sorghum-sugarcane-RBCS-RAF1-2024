%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Yu Wang https://github.com/yuwangcn yuwangcn@illnois.edu yuwangpicb@gmail.com
% 2021-09
% TDL raw data annalysis
% Leakiness estimation based on TDL and LI6800 data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Leakiness=TDL_Leakiness(SamplematrixRef_cal,licorfile,Rd,FigName,Output)
TDLCali=SamplematrixRef_cal; 
global LicorStartingTime;
LicorEndTime=LicorStartingTime+40*60;
DelayTime=24;
LicorD=importdata(licorfile);%
LicorData=LicorD.data;
Time_Licort=LicorData(:,ismember(LicorD.colheaders,'Hour')==1);
LicorData(:,2)=round(Time_Licort*3600);% Time convert from hour to second
Ci_Licor=LicorData(:,ismember(LicorD.colheaders,'Ci')==1);
A_Licor=LicorData(:,ismember(LicorD.colheaders,'A')==1);
CO2R_Licor=LicorData(:,ismember(LicorD.colheaders,'CO2_r')==1);
CO2S_Licor=LicorData(:,ismember(LicorD.colheaders,'CO2_s')==1);
H2OR_Licor=LicorData(:,ismember(LicorD.colheaders,'H2O_r')==1);
H2OS_Licor=LicorData(:,ismember(LicorD.colheaders,'H2O_s')==1);
CO2Rcorr_Licor=(1000000*CO2R_Licor)./(1000000-H2OR_Licor*1000);
CO2Scorr_Licor=(1000000*CO2S_Licor)./(1000000-H2OS_Licor*1000);	

E_Licor=LicorData(:,ismember(LicorD.colheaders,'E')==1)*1000;%WY202011
gac_Licor=LicorData(:,ismember(LicorD.colheaders,'gtw')==1);

Pressure_Licor=LicorData(:,ismember(LicorD.colheaders,'Pa')==1);%WY202205

LicorData_s=[LicorData(:,2) A_Licor Ci_Licor CO2R_Licor CO2S_Licor H2OR_Licor H2OS_Licor CO2Rcorr_Licor CO2Scorr_Licor E_Licor gac_Licor Pressure_Licor];

for Cycle =TDLCali(1,1):TDLCali(end,1)
[mc,nc]= find(TDLCali(:,1)==Cycle);
TDLCaliCyc=TDLCali(mc,:);
LeakinessCycle=CalLeakiness(TDLCaliCyc,LicorData_s,LicorStartingTime,DelayTime,Rd);
LeakinessCycle(find(isnan(LeakinessCycle(:,2))==1),2)=0;
% if find(~isnan(LeakinessCycle))
%     LeakinessCycle=LeakinessCycle(~isnan(LeakinessCycle));
% end
if  Cycle ==TDLCali(1,1)
    Leakiness=LeakinessCycle;
else
    Leakiness=[Leakiness;LeakinessCycle];
end
end
figure;
plot(Leakiness(:,1)-Leakiness(1,1),Leakiness(:,2),'k.');
hold on
plot(Leakiness(:,1)-Leakiness(1,1),Leakiness(:,5),'b.');
LeakinessS(:,1)=Leakiness(1:end-1,1)-Leakiness(1,1);
LeakinessS(:,2:12)=Leakiness(1:end-1,2:12);
xlabel('Time (s)');
ylabel('Leakiness')
ylim([0 0.6]);
xlim([0 1800]);
title(FigName);
saveas(gcf,FigName,'tiff');
dlmwrite(Output,LeakinessS,'delimiter','\t','precision', '%.4f');
end