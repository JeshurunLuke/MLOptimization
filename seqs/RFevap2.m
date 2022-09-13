function s = RFevap2(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
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
fcut = [10, 5, 3, 2.3, 2.21].*1e6; %2.17
tau = [3.5, 4, 5, 5, 2]; %tau = [3.5, 4, 5, 5, 5];
amp = [0.15, 0.1, 0.15, 0.1, 0.05];%[V]

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
    error('fcut should < f0');
end

fstart=[f0 fcut(1:length(fcut)-1)];
tstage=-tau.*log((fcut-fb)./(fstart-fb));
% tstage=tau;

if sum(tstage)>=100
    error('Too long evaporation time!');
end
disp(['RF evap takes ',num2str(sum(tstage)),'s']);
disp(['RF stops at ',num2str(fcut(length(fcut))/1e6),'MHz']);

m = MemoryMap;
m.Data(1).RFcut = fcut(length(fcut))/1e6;

for i=1:length(tau)
    if i==1
        s.add('FreqRFknife',f0);
    end
    s.add('AmpRFknife',amp(i));
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
%         f=fstart(i)-j*dt*(fstart(i)-fcut(i))/tau(i);
%         disp(['f=',num2str(f/1e6),'MHz']);
        s.addStep(dt)...
         .add('FreqRFknife',f);
    end
end

%%------turn off RF knife------
s.add('FreqRFknife',0e6);
s.add('AmpRFknife',0.);

% Make sure the RF evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"
if sum(tau)<=tRetTrip
    s.wait(tRetTrip - sum(tau));
end

if(~exist('s1','var'))
    s.run();
end

end