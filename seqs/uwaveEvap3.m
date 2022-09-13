function s = uwaveEvap3(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
% s.findDriver('FPGABackend').setTimeResolution(10e-3);%set the time stepsize

%%constant frequency parameter
fHP = 6834.682e6; % [Hz] hyperfine splitting frequency
fsyn = 3533.25e6*2; % [Hz] Valon synthesizer + frequency doubler

%%Dynamic frequency offset
f00 = 20e6*3;%[Hz] initial frequency offset from fHP,factor of 3 due to 3 times bigger Bohr magneton
fbb = 1.785e6*3;%1.70e6*3;%[Hz] trap bottom frequency offset from fHP
fbb21 = 1.8e6*2; %1.785e6*2;

%%Dynamic frequency
f0 = fsyn-fHP-f00;%[Hz] initial frequency
fb = fsyn-fHP-fbb;%[Hz] trap bottom frequency
fb21 = fsyn-fHP-fbb21;%[Hz] trap bottom frequency for |21> -> |11>

%%----------set parameters for different evap stages--------
% fcut0 = [10*3, 6*3, 3.0*3, 2.0*3].*1e6;% [10*3, 6*3, 2.3*3, 1.80*3].*1e6;
% fcut = fsyn-fHP-fcut0;
% tau = [6, 4, 4, 4]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
% amp=[0.5, 0.5, 0.4, 0.4]; %[V][0.7,0.8,0.8];[0.8,0.8,0.8];

fcut0 = [10*3, 6*3, 3.0*3, 2.0*3].*1e6;% [10*3, 6*3, 2.3*3, 1.80*3].*1e6;
fcut = fsyn-fHP-fcut0;
tau = [13, 10, 5, 4]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
amp=[0.7, 0.5, 0.4, 0.4]; %[V][0.7,0.8,0.8];[0.8,0.8,0.8];

m = MemoryMap;
m.Data(1).RFcut = fcut0(length(fcut0))/1e6/3;

fstart=[f0 fcut(1:length(fcut)-1)];
tstage=-tau.*log((fcut-fb)./(fstart-fb));
% tstage=tau;

if sum(tstage)>=100
    error('Too long evaporation time!');
end
disp(['uwave evap takes ',num2str(sum(tstage)),' s']);
disp(['uwave stops at ',num2str((fsyn-fcut(length(fcut)))/1e6),' MHz']);

% Enable the uwave TTL switch
s.addStep(10e-3)...
    .add('TTLuwaveampl',1)...
    .add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;


for i=1:length(tau)
    if i==1
        s.add('Frequwave',f0);
    end
    s.add('Ampuwave',amp(i));
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
        s.addStep(dt*(1-0.2))...
            .add('Frequwave',f);
        s.addStep(dt*0.2)...
            .add('Frequwave',fb21);        %clean up |21>
    end
end

%%------turn off u-wave knife------
s.add('Frequwave',0e6);
s.add('Ampuwave',0.);
s.add('TTLuwaveampl',0);

% Make sure the u-wave evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"
if sum(tau)<=tRetTrip
    s.wait(tRetTrip - sum(tau));
end


if(~exist('s1','var'))
    s.run();
end

end