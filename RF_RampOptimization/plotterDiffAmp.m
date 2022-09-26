function s = plotterDiffAmp(s1)

% s.findDriver('FPGABackend').setTimeResolution(10e-3);%set the time stepsize


f0 = 20e6;%[Hz] initial frequency
% f1 = 15e6;%[Hz] 1st stage end frequency
% f2 = 5.*1e6;%[Hz] 2nd stage end frequency
% f3 = x.*1e6;%[Hz] 3rd stage end frequency
fb = 1.785e6;%1.75 [Hz] located for new trap geometry on 01/06/2017. old trap bottom frequency 0.66e6

% % %----------set parameters for different evap stages--------
% fcut = [10, 5, 3, 2.3, 2.0].*1e6;
% tau = [6, 5, 5, 4, 5];%[11,(f1 - f2)./cutrate,(f2 - f3)./cutrate]; %[s][8,11,10];
% amp = [0.55, 0.6, 0.5, 0.4, 0.4];%[V][0.7,0.8,0.8];[0.8,0.8,0.8];

% % % The following are for Ioffe coil evap

%Input Fcut (length = 5) tTotal (scalar) amp (length = 5) A (length = 15)
%--> 26

%fcut = [10, 5, 3, 2.3, 2.21].*1e6; %2.17

fileloc  = "N:\KRbLab\M_loop\MLoopParam\param.mat";


fcut = cell2mat(struct2cell(load(fileloc, 'fcut'))).*1e6;

tTotal = cell2mat(struct2cell(load(fileloc, 'tTotal')));
tau = tTotal/length(fcut)*ones(1, length(fcut));

amp = cell2mat(struct2cell(load(fileloc, 'amp')));
A = cell2mat(struct2cell(load(fileloc, 'A')));

% fcut = [10, 5, 3, 2.3, 2.24].*1e6; %2.17
% tau = [3.5, 4, 5, 5, 2]; %tau = [3.5, 4, 5, 5, 5];
% amp = 1.25.*[0.15, 0.1, 0.15, 0.1, 0.05];%[V]

%amp = 1.25.*[0.15, 0.1, 0.15, 0.1, 0.075./1.5];%[V] 11/19/2019
%1.5.*[0.15, 0.1, 0.15, 0.1, 0.075./1.5];%[V]

% % The following are for Ioffe coil evap
% fcut = [10].*1e6;
% tau = [3.5];
% amp = [0.15];%[V]

% % The following are for Ioffe coil evap (updated on 05/07/2019)
% fcut = [10, 5, 3, 2.3, 2.06].*1e6;
% tau = [3.5, 4, 5, 5, 5];
% amp = [0.2, 0.1, 0.2, 0.2, 0.075];%[V]


if min(fcut)<= fb
    
    error('fcut should > fb');
end


if max(fcut)>=f0
    disp(max(fcut))

    error('fcut should < f0');
end

fstart=[f0 fcut(1:length(fcut))];
F = []
T = []
set = 0;
taustep = [0, tau];

for i=1:length(tau)

    %if i==1
    %    s.add('FreqRFknife',f0);
    %end
    %s.add('AmpRFknife',amp(i));
    Nj=300;
    dt=tau(i)/Nj;
    A2 = A(1 + set);
    A3 = A(2 + set);
    A4 = A(3 + set);
    
   % disp(tau(i))
    for j=1:Nj
        %f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
        f = fstart(i) + (fstart(i+1) - fstart(i)).*j.*dt/tau(i) + A2.*j.*dt.*(j.*dt - tau(i)) + A3.*j.*dt.*(j.*dt-tau(i)).*(j.*dt + 0.5*tau(i)) + A4.*j.*dt.*(j.*dt + 2/3*tau(i)).*(j.*dt + 1/3*tau(i));
        F = [F, f]; %If speed problems aloocate
        T = [T, taustep(i) + j*dt];
    end
    set = set + 3;
end
plot(T, F)
%disp(min(F)/1E6)
%plot(T, F)
%%------turn off RF knife------

% Make sure the RF evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"






s = 1;
end