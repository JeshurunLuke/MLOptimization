function s = ODT1Evap(s1, VODT1, VODT2)
%%%%%%%%%%%%%%%%%%%%%
%%%reduce ODT power by exponential decay P(t)=P0*exp(-t/tau1) with t=0 to
%%%t1 (t1 satisfies P0*exp(-t1/tau1)=P1
%%ODT2 ramps on during the first stage of evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
if ~exist('VODT1','var')
    error('Please assign ODT1 power!');
end
if ~exist('VODT2','var')
    error('Please assign ODT2 power!');
end
VODT0 = VODT1;    %DAC value 0-3.7 V, negative means off, 3.5V corresponds to 4.34W
%VODT0 = VODT1.*2;
VODTmin = 0.00;  %Minimum ODT power

%%---The following are for single beam ODT
%% ----------set parameters for different evap stages--------
% VODT = [1, 0.3, 0.1, 0.15];    %[V]  W/V
% tau = [1.5, 2.2, 2.5, 0.5];         % 0.8 [s]

%% --------- The following are for single beam ODT, yileds ~ 5 uK cloud ------------
% VODT = [1.5, 0.2, VODT1];    %[V]  W/V
% tau = [0.2, 2, 0.5];         % 0.8 [s]

%% ----The following are for crossed beam ODT-----------
% VODT = [0.3, 0.1, 0.03, 0.05];    %[V]  W/V
% tau = [0.25, 1.5, 1, 0.5];         % 0.8 [s]

% old servo
% VODT = [2, 0.120, 0.125].*2;    %[V]  W/V
% tau = [0.5, 1.5, 0.5];         % 0.5 [s]

% new servo
VODT = [2, 0.11, 0.119].*1.3;    %[V]  W/V  
%VODT = [2, 0.11, 0.119].*1.3 01/07/2020
%VODT = [2, 0.11, 0.115].*1.3;
tau = [0.5, 1.5, 0.5];         % 0.5 [s] 

Vstart = [VODT0 VODT(1:length(VODT)-1)];
tstage = -tau.*log((VODT-VODTmin)./(Vstart-VODTmin));
tau = tau.*sign(tstage);
tstage=abs(tstage);
tODTevap = sum(tstage);
if length(VODT)~= length(tau)
    error('Length of VODT should equal length of tau');
end

if min(VODT)<=VODTmin
    error('VODT1 should > 0');
end
if max(VODT)> VODT0
    error('VODT1 should <= VODT0');
end

if tODTevap >= 20 %[s]
    error('Too long ODT evaporation time!');
end
disp(['ODT evap takes ',num2str(tODTevap),'s']);

for i=1:length(tau)
    if i==1
        s.add('ODT1', VODT0);
        s.add('TTLODT2',1);
        s.add('ODT2', 0.01);
    end
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        V1 = (Vstart(i)-VODTmin).*exp(-j.*dt./tau(i))+VODTmin;

%         disp(['V1=',num2str(V1),' ']);
%         s.addStep(dt)...
%         s.add('ODTtransf',V1);
        s.add('ODT1',V1);
        if i == 1
            V2 = VODT2*j/Nj;
            s.add('ODT2', V2);
        end
         %if i == 3
          % %  V3 = VODT2 + (0.818-VODT2)*j/Nj;
             %V2 = VODT2 - (VODT2-0.6)*j/Nj;
           %  s.add('ODT2', V3);
         %end
        s.wait(dt);
    end
end
% disp(['V1 = ',num2str(V1)]);


if(~exist('s1','var'))
    s.run();
end

end