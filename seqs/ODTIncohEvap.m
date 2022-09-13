function s = ODTIncohEvap(s1, x)
%%%%%%%%%%%%%%%%%%%%%
%%%reduce ODT power by exponential decay P(t)=P0*exp(-t/tau1) with t=0 to
%%%t1 (t1 satisfies P0*exp(-t1/tau1)=P1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

PODT0 = 5; % [W]
% Initial conditions
PODTmax = 8; % [W] Set point of power of laser (max 20 W)
PODTmin = 0.00; %  [W] Minimum power of laser
% Evap cut powers
PODT = [x, 5]; % [W]
tau = [2, 4]; % [s]

% Read calibration file
folderpath = 'D:\experiment-control\matlab_new\Calibration files';
filename = '\2_13_18_Incoherent_ODT_AOM_diffraction_efficiency_calibration.txt';
filepath = [folderpath,filename];
AOMCal = csvread(filepath);
EODTCal = AOMCal(:,2);
VODTCal = AOMCal(:,1);

EODT0 = PODT0./PODTmax;

% VODTmin = 0;
%
% a = (1/0.35)^2;
% VODT = sqrt(PODT./a);

Pstart = [PODT0 PODT(1:length(PODT)-1)];
tstage = -tau.*log((PODT-PODTmin)./(Pstart-PODTmin));
tau = tau.*sign(tstage);
tstage=abs(tstage);
tODTevap = sum(tstage);

if length(PODT)~= length(tau)
    error('Length of PODT should equal length of tau');
end

% Check for errors
if min(PODT)<=PODTmin
    error('PODT should > 0');
end
if max(PODT)> PODTmax*0.7
    error('Maximum AOM efficiency is 70%. PODT should <= PODT0*0.7');
end
if tODTevap >= 100 %[s]
    error('Too long ODT evaporation time!');
end
disp(['ODT evap takes ',num2str(tODTevap),'s']);

Vtmp = zeros(300,1);
% Do the cut
for i=1:length(tau)
    if i==1
        VODT0 = VODTCal(find(abs(EODTCal - EODT0) == min(abs(EODTCal - EODT0))));
        s.add('AmpODTincohAOM',VODT0);
    end
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        P1 = ((Pstart(i)-PODTmin)).*exp(-j.*dt./tau(i))+(PODTmin);
        E1 = P1./PODTmax;
        V1 = VODTCal(find(abs(EODTCal - E1) == min(abs(EODTCal - E1))));
        Vtmp(j) = V1;
        s.add('AmpODTincohAOM',V1);
        s.wait(dt);
    end
end

if(~exist('s1','var'))
    s.run();
end

end