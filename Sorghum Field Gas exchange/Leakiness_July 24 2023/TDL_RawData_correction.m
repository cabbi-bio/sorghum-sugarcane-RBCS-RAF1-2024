
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Yu Wang https://github.com/yuwangcn yuwangcn@illnois.edu yuwangpicb@gmail.com
% 2021-09
% TDL raw data annalysis
% Leakiness estimation based on TDL and LI6800 data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate the gas sample changes every second
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SamplematrixRef_cal=TDL_RawData_correction(TDLfile, TDLStartimeH, TDLStartimeM,TDLStartimeS,LicorStartTimeH,LicorStartTimeM,LicorStartTimeS)
global SamplematrixRef_cal;
%Get the TDL raw data
TDLRaw=importdata(TDLfile); 
TDLRawdata=TDLRaw.data;
m0=size(TDLRawdata,1);
if ~isempty(find(TDLRawdata(:,1)==0, 1))
TDLRawdata=TDLRawdata(find(TDLRawdata(:,1)==0):m0,:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global LicorStartingTime;
LicorStartingTime=LicorStartTimeH*3600+LicorStartTimeM*60+LicorStartTimeS;
LicorEndTime=LicorStartingTime+40*60;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set the starting time point 
%(hour*3600+minute*60+second)*10
global StartingTime
StartingTime=(TDLStartimeH*3600+TDLStartimeM*60+TDLStartimeS)*10;
TimeMatrix=TDLRawdata(:,1)-TDLRawdata(1,1)+StartingTime;
TDLRawdata(:,1)=TimeMatrix;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%delete the imcomplete cycle in the beginning
mt=size(TDLRawdata,1);
[m1,n1]=find(TDLRawdata(:,3)==1);
EndPoint=300;
for i=1:300
    if (m1(i)-m1(i+1))>1
    EndPoint=i;
    end
end
if EndPoint==300
    TDLRawdata_s=TDLRawdata(m1(1):mt,:);
else
    TDLRawdata_s=TDLRawdata(m1(EndPoint+1):mt,:);
end
mt_s=size(TDLRawdata_s,1);
[m2,n2]=find(TDLRawdata_s(:,3)==1);

%average the calibration steps
CalibrationTimes=size(m2,1)/300;
CalibrationAvg=zeros(round(CalibrationTimes*3),5);
for Cali=1:CalibrationTimes
    if Cali<CalibrationTimes
    TDLRawdata_s(m2((Cali-1)*300+1):m2(Cali*300+1)-1,21)=Cali;
    else
    TDLRawdata_s(m2((Cali-1)*300+1):mt_s,21)=Cali; 
    end
for Calstep=1:3
CalibrationAvg((Cali-1)*3+Calstep,1)=Cali; 
CalibrationAvg((Cali-1)*3+Calstep,2)=mean(TimeMatrix(m2((Cali-1)*300+101)+(Calstep-1)*300:m2((Cali-1)*300+1)+(Calstep-1)*300+300-1));
CalibrationAvg((Cali-1)*3+Calstep,3)=mean(TDLRawdata_s(m2((Cali-1)*300+101)+(Calstep-1)*300:m2((Cali-1)*300+1)+(Calstep-1)*300+300-1,3));
CalibrationAvg((Cali-1)*3+Calstep,4:5)=mean(TDLRawdata_s(m2((Cali-1)*300+101)+(Calstep-1)*300:m2((Cali-1)*300+1)+(Calstep-1)*300+300-1,6:7));
end      
end
A20=TDLRawdata_s(m2,:);
%Licor measurement start time
%(hour*3600+minute*60+second)*10

[m_sample,n_sample]=find(TDLRawdata_s(:,3)==11);
Samplematrix=TDLRawdata_s(m_sample,:);
AveragePoints=10;
Samplematrix_sec=zeros(floor(size(m_sample,1)/AveragePoints),size(TDLRawdata_s,2));
for Avi=1:floor(size(m_sample,1)/AveragePoints)
Samplematrix_sec(Avi,:)=mean(Samplematrix((Avi-1)*10+1:Avi*10,:));
end
Samplematrix_sec(:,1)=floor(Samplematrix_sec(:,1)/10);
%LicorStartingPoint=find(Samplematrix_sec(:,1)==LicorStartingTime);
StartM=find(Samplematrix_sec(:,1)>=LicorStartingTime);
LicorStartingPoint=StartM(1);
LicorStartingCycle=Samplematrix_sec(LicorStartingPoint,21);

EndM=find(Samplematrix_sec(:,1)<LicorEndTime);
LicorEndPoint=EndM(end:end);
LicorEndCycle=Samplematrix_sec(LicorEndPoint,21);


CalibrationAvg_Cycle=CalibrationAvg(find(CalibrationAvg(:,1)==LicorStartingCycle),:);
Samplematrix_Cycle=Samplematrix_sec(find(Samplematrix_sec(:,21)==LicorStartingCycle),:);
Samplematrix_Cycle=Samplematrix_Cycle(find(Samplematrix_Cycle(:,1)>=LicorStartingTime),:);
SamplematrixRef_Cycle_cal=AvgData_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle);
SamplematrixRef_cal=zeros(1,5);

for Rcycle=LicorStartingCycle:LicorEndCycle
    if Rcycle==LicorStartingCycle
        CalibrationAvg_Cycle=CalibrationAvg(find(CalibrationAvg(:,1)==LicorStartingCycle),:);
        Samplematrix_Cycle=Samplematrix_sec(find(Samplematrix_sec(:,21)==LicorStartingCycle),:);
        Samplematrix_Cycle=Samplematrix_Cycle(find(Samplematrix_Cycle(:,1)>=LicorStartingTime),:);
        SamplematrixRef_Cycle_cal=AvgData_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle);
    end
    
    if Rcycle==LicorEndCycle
        CalibrationAvg_Cycle=CalibrationAvg(find(CalibrationAvg(:,1)==LicorEndCycle),:);
        Samplematrix_Cycle=Samplematrix_sec(find(Samplematrix_sec(:,21)==LicorEndCycle),:);
        Samplematrix_Cycle=Samplematrix_Cycle(find(Samplematrix_Cycle(:,1)<=LicorEndTime),:);
        SamplematrixRef_Cycle_cal=AvgData_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle);
    end
        
CalibrationAvg_Cycle=CalibrationAvg(find(CalibrationAvg(:,1)==Rcycle),:);
Samplematrix_Cycle=Samplematrix_sec(find(Samplematrix_sec(:,21)==Rcycle),:);
SamplematrixRef_Cycle_cal=AvgData_calibration(CalibrationAvg_Cycle,Samplematrix_Cycle);
if Rcycle==LicorStartingCycle
    SamplematrixRef_cal=SamplematrixRef_Cycle_cal;
else
SamplematrixRef_cal=[SamplematrixRef_cal;SamplematrixRef_Cycle_cal];
end
end
end
%dlmwrite('SamplematrixRef_cal.txt',SamplematrixRef_cal,'delimiter','\t','precision', '%.8f');
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %Correction 
% % %Constants	
% % RPDB_13=0.0112372;
% % RVPDB_13=0.0111797;
% % isotopologues_other_C=0.00474;
% % isotopologues_other_O=0.01185;
% % RVSMOW_18=0.0020052;
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %Calibration Tank 1
% % d13CtankVPDB=-11.50;
% % TotalCO2=443.308;%(¦Ìmol mol-1)	
% % d18Otank=-8.05;
% % %Calculated Values	
% % C12OOAndC13OO=TotalCO2*(1-isotopologues_other_C);%441.2067201;
% % R13=RVPDB_13*(1+d13CtankVPDB/1000);%0.011051133;s=sprintf('%1.8f',R13)
% % C12OO=C12OOAndC13OO/(1+R13);%436.3841803;% (¦Ìmol mol-1)	
% % C13OO=R13*C12OO;%4.822539812;% (¦Ìmol mol-1)	
% % SampleC12OO=597.1502;
% % SampleC13OO=6.4911;




