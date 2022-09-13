function s = testing(func, s1, varargin)

% s.findDriver('FPGABackend').setTimeResolution(10e-3);%set the time stepsize

f0=30e6;%[Hz] initial frequency
fb=0e6;%[Hz] trap bottom frequency

%%----------set parameters for different evap stages--------
% fcut=[22,15].*1e6;% [25,15,3].*1e6;[22,20].*1e6;
% tau = [5,5]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
% amp=[0.6,0.6]; %[V][0.7,0.8,0.8];[0.8,0.8,0.8];

% The following are for Ioffe coil evap
fcut=[22, 15].*1e6;% [25,15,3].*1e6;[22,20].*1e6;
tau = [4, 3]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
amp = [0.4, 0.15].*0.5; %[V][0.7,0.8,0.8];[0.8,0.8,0.8]; [0.4 0.15]

if min(fcut)<=fb
    error('fcut should > fb');
end
if max(fcut)>=f0
    error('fcut should < f0');
end

fstart=[f0 fcut(1:length(fcut)-1)];
% tstage=-tau.*log((fcut-fb)./(fstart-fb));
tstage=tau;

if sum(tstage)>=100
    error('Too long evaporation time!');
end
disp(fstart)
disp(['RF evap takes ',num2str(sum(tstage)),' s']);
disp(['RF stops at ',num2str(fcut(length(fcut))/1e6),' MHz']);

F = [];
T = [];
disp(tstage)

taustep = [0, tstage];

for i=1:length(tau)

    Nj=300;
    dt=tstage(i)/Nj;
    for j=1:Nj
%         f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
        f=fstart(i)-j*dt*(fstart(i)-fcut(i))/tau(i);
        F = [F, f]; %If speed problems aloocate
        T = [T, taustep(i) + j*dt];
%         disp(['f=',num2str(f/1e6),'MHz']);
   
    %ti = T(length(T));

    end
end
plot(T,F)

% s.add('FreqRFknife',2e6);
% s.add('AmpRFknife',0.9);
% s.wait(15);
%%------turn off RF knife------


% Make sure the RF evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"
func(1)


% s.addStep(@MakeRbMOT);
%pause(10)
s = 1

end