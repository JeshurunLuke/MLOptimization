function s = testing(func, s1, varargin)

% s.findDriver('FPGABackend').setTimeResolution(10e-3);%set the time stepsize

f0=30e6;%[Hz] initial frequency
fb=0e6;%[Hz] trap bottom frequency

%%----------set parameters for different evap stages--------
% fcut=[22,15].*1e6;% [25,15,3].*1e6;[22,20].*1e6;
% tau = [5,5]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
% amp=[0.6,0.6]; %[V][0.7,0.8,0.8];[0.8,0.8,0.8];


fileloc  = "N:\KRbLab\M_loop\MLoopParam\param.mat";


fcut = [ 1.03478867e+01,  4.86194169e+00,  2.80130600e+00, 2.14186189e+00,  1.78600000e+00].*1e6;

tTotal = 16;
tau = tTotal/length(fcut)*ones(1, length(fcut));
fstart=[f0 fcut(1:length(fcut))];

A = [-7.42330534e-02,  -1.74433037e-01, -1.29652921e-01, 1.93075997e-01, -7.73862501e-02, -3.10299594e-01,   6.03091415e-03, 1.62581735e-02,  1.69806449e-01, -1.72119801e-01, -1.83837111e-01, -1.89036102e-01, 6.14841391e-02,  -2.53644384e-01,   2.53557260e-01]; 

% fcut = [10, 5, 3, 2.3, 2.24].*1e6; %2.17
% tau = [3.5, 4, 5, 5, 2]; %tau = [3.5, 4, 5, 5, 5];
% amp = 1.25.*[0.15, 0.1, 0.15, 0.1, 0.05];%[V]
if sum(tau)>=100
    error('Too long evaporation time!');
end
disp(fstart)
disp(['RF evap takes ',num2str(sum(tau)),' s']);
disp(['RF stops at ',num2str(fcut(length(fcut))/1e6),' MHz']);

FWC = [];
T = [];
FWOC = [];
disp(tau)

taustep = [0, tau];
disp(taustep)
set = 0;
t = 0;
for i=1:length(tau)

    Nj=300;
    dt=tau(i)/Nj;
    A2 = A(1 + set);
    A3 = A(2 + set);
    A4 = A(3 + set);
    
   % disp(tau(i))
    for j=1:Nj
        %f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
        fWC = fstart(i) + (fstart(i+1) - fstart(i)).*j.*dt/tau(i) + A2.*j.*dt.*(j.*dt - tau(i)) + A3.*j.*dt.*(j.*dt-tau(i)).*(j.*dt + 0.5*tau(i)) + A4.*j.*dt.*(j.*dt + 2/3*tau(i)).*(j.*dt + 1/3*tau(i));
        fWOC = fstart(i) + (fstart(i+1) - fstart(i)).*j.*dt/tau(i);
        t = t + dt;
        FWC = [FWC, fWC]; %If speed problems aloocate
        FWOC = [FWOC, fWOC];
        T = [T, t];
%         disp(['f=',num2str(f/1e6),'MHz']);
   
    %ti = T(length(T));

    end
    set = set + 3;
    disp(t)

end
title('Evap Ramp')
plot(T,FWC, "r-","Linewidth",2);
hold on
plot(T, FWOC, "b-","Linewidth",0.5);
legend('W/ Expansion','W/O Expansion')
xlabel('Frequencies (Hz)') 
ylabel('Time (sec)') 
% s.add('FreqRFknife',2e6);
% s.add('AmpRFknife',0.9);
% s.wait(15);
%%------turn off RF knife------


% Make sure the RF evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"



% s.addStep(@MakeRbMOT);
%pause(10)
s = 1

end