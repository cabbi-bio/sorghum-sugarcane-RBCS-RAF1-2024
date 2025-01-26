
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Yu Wang https://github.com/yuwangcn yuwangcn@illnois.edu yuwangpicb@gmail.com
% 2021-09
% TDL raw data annalysis
% Leakiness estimation based on TDL and LI6800 data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Leakiness =CalLeakiness(TDLCaliCyc,LicorData_s,LicorStartingTime,DelayTime,Rd)
Cr_TDL=TDLCaliCyc(TDLCaliCyc(:,2)==10,6);
dfCr=TDLCaliCyc(TDLCaliCyc(:,2)==10,7);
k=1;
TDLCaliCyc_s=zeros(1,size(TDLCaliCyc,2));
LicorData_sc=zeros(1,size(LicorData_s,2));
for Time_s=1:size(LicorData_s,1)
    if ~isempty(find( TDLCaliCyc(:,3)== LicorData_s(Time_s,1)+DelayTime))
        timex(k)=find(TDLCaliCyc(:,3)== LicorData_s(Time_s,1)+DelayTime);
        %TDLCaliCyc_s(k,:)=TDLCaliCyc(timex(k),:);
        if timex(k)-5>0&&timex(k)+5<=size(TDLCaliCyc,1)
        TDLCaliCyc_s(k,:)=mean(TDLCaliCyc(timex(k)-5:timex(k)+5,:));
        else if timex(k)-5>0&&timex(k)+5<=size(TDLCaliCyc,1)
        TDLCaliCyc_s(k,:)=mean(TDLCaliCyc(timex(k)-5:timex(k)+5,:));
            else
                TDLCaliCyc_s(k,:)=TDLCaliCyc(timex(k),:);
            end
        end
        LicorData_sc(k,:)=LicorData_s(LicorData_s(:,1)== TDLCaliCyc(timex(k),3)-DelayTime,:);
        k=k+1;
    end
end

Cs_TDL=TDLCaliCyc_s(:,6);
dfCs=TDLCaliCyc_s(:,7);

xsi_TDL=Cr_TDL./(Cr_TDL-Cs_TDL);
Dtdl_TDL=(1000*xsi_TDL.*(dfCs-dfCr))./(1000+dfCs-xsi_TDL.*(dfCs-dfCr));

A=LicorData_sc(:,2);

%e_recent=-6;%change the e' calculation WY202006
e_ori=0;
dfCgam=-8;
e_recent=e_ori+dfCr-dfCgam;

Ci_licor=LicorData_sc(:,3);
Cs_H2O=LicorData_sc(:,5);
Pi_Pa_H2O=Ci_licor./Cs_H2O;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
E_Licor=LicorData_sc(:,10);
gac_Licor=LicorData_sc(:,11);
a_bar=4.4;
a_ac=1+(a_bar/1000);
t_licor=(a_ac.*E_Licor/1000)./(2.*gac_Licor);   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rm=0.5*abs(Rd);
AL=(1- t_licor).*Dtdl_TDL.*Cs_TDL-a_bar .*(Cs_TDL-Ci_licor);
AH=e_recent*Rm/(A+0.5*abs(Rd));
AJ=Rm/(A+0.5*abs(Rd));
AK=abs(Rd)/(A+abs(Rd));

%%%%%%%%%%%%%%%%%%
% fLL calculaiton 202205
%gstar= 0.00029130549581659;
gstar= 0.000193; 
x=0.4;
alpha=0;
gbs0=0.00113;%(Brown & Byrd, 1993) mol m-2 s-1
%%%
Pa_k=LicorData_sc(:,12);%(kPa)
Ci_Pa=Ci_licor.*Pa_k*0.00000001*100*1000;
Om=210000;
Om_Pa=210000*Pa_k*0.00000001*100*1000;
gbs= gbs0.*10^6./(1000* Pa_k);
Os= (alpha*A)./(0.047*(gbs*1000000))+Om;
Ospa= Pa_k.*0.00000001.*Os*100*1000;

Jt=zeros(size(LicorData_sc,1),1);
for i =1:size(LicorData_sc,1)
I=(1+(abs(Rd)/A(i)))*(Rm- gbs(i) *Ci_Pa(i)-((7* gbs(i) * gstar * Om_Pa(i))/3))+(A(i)+abs(Rd))*(1-((7* alpha * gstar)/3*0.047));
II=(1-x)/3*( gbs(i)./A(i).*(Ci_Pa(i)-Rm./ gbs(i) - gstar .* Om_Pa(i))-1- alpha * gstar /0.047)-x/2*(1+abs(Rd)./A(i));
III=(x-x^2)/(6*A(i));
Jt(i)=real((-II +sqrt(II^2-4*III*I))/(2*III));
end

Cbs_Pa=(( gstar.*Ospa).*(7/3.*(A+abs(Rd))+(((1-x).*Jt)/3)))./((((1-x).*Jt)./3)-(A+abs(Rd)));%Pa
Cbs=Cbs_Pa./(Pa_k.*0.00000001*100*1000);
Vc=(A+abs(Rd))./(1-(gstar.*Ospa)./Cbs_Pa);
Vp=(x.*Jt)/2;
Vo=(Vc-A-abs(Rd))./0.5;
b4o=-5.5;
b3o=30;%29 or 30

f=11.6;
b4=b4o-((e_recent.*Rm)./Vp);
b3=b3o-e_recent.*abs(Rd)./Vc-f*Vo./Vc;

DC=((Cbs-Ci_licor)./Ci_licor);
%%%%%%%%%%%%%%%%%%%%
for i =1:size(LicorData_sc,1)
LHL(i,1)=((AL(i)/((1+ t_licor(i))* Ci_licor(i))-(-5.5)+AH(i)))./(30-1.8+e_recent*(AJ(i)-AK(i)));%fcomt HL
LLL(i,1)= DC(i).*(AL(i)-(1+t_licor(i))* Ci_licor(i)*b4(i))./((1+t_licor(i))*(b3(i)*Cbs(i)-1.8*(Cbs(i)-Ci_licor(i)))-AL(i));%fLL
end
Leakiness=zeros(size(LicorData_sc,1),11);
Leakiness(:,1)=LicorData_sc(:,1);
Leakiness(:,2)=LHL;
Leakiness(:,3)=Dtdl_TDL;
Leakiness(:,4)=xsi_TDL;
Leakiness(:,5)=LLL;
Leakiness(:,6)=Jt;
Leakiness(:,7)=Cbs;
Leakiness(:,8)=Ci_licor;
Leakiness(:,9)=Vc;
Leakiness(:,10)=Vp;
Leakiness(:,11)=Vo;
Leakiness(:,12)=Cs_TDL;
end