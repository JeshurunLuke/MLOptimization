function s = HybridRFevap2(s1, tevap2, tBramp, fcut1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tevap2','var'))
    tevap2 = 1;%[s]
end

if(~exist('tBramp','var'))
    tBramp = tevap2 + 2;%[s]
end

%%constant frequency parameter
fHP = 6834.682e6; % [Hz] hyperfine splitting frequency
fsyn = 3533.25e6*2; % [Hz] Valon synthesizer + frequency doubler

%%Dynamic frequency offset
f00 = fcut1*1e6*3;%[Hz] initial frequency offset from fHP,factor of 3 due to 3 times bigger Bohr magneton
fbb = 0e6;%[Hz] trap bottom frequency offset from fHP

%%Dynamic frequency
f0 = fsyn-fHP-f00;%[Hz] initial frequency
fb = fsyn-fHP-fbb;%[Hz] trap bottom frequency

fcut0 = [3.2*3].*1e6;% [25,15,3].*1e6;[22,20].*1e6;
fcut = fsyn-fHP-fcut0;
tau = [tevap2]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
amp=[0.55]; %[V][0.7,0.8,0.8];

IBleeder0 = 7.5;      %[A] 7.5 A corresponds to 80 G/cm
VBleeder0 = - IBleeder0/s.C.QUICCoilIV;
IBleeder = 2.15;      %[A] 2.2 A corresponds to 30 G/cm
VBleeder = - IBleeder/s.C.QUICCoilIV;

if tBramp <= tevap2
    error('tBramp should be > tevap2');
end

fstart=[f0 fcut(1:length(fcut)-1)];
tstage=tau;

if sum(tBramp)>=100
    error('Too long evaporation time!');
end
disp(['RF evap takes ',num2str(sum(tstage)),' s']);
disp(['RF stops at ',num2str(fcut(length(fcut))/1e6),' MHz']);
s.add('TTLuwaveampl', 1);
for i=1:length(tau)
    if i==1
        s.add('Frequwave',f0);
    end
    s.add('Ampuwave',amp(i));
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        f = fstart(i)-j*dt*(fstart(i)-fcut(i))/tau(i);
        VBleederj = VBleeder0 -j*dt*(VBleeder0-VBleeder)/tBramp;
        s.addStep(dt)...
         .add('Frequwave', f)...
         .add('VctrlCoilServo2', VBleederj);
    end
end
s.addStep(tBramp-tevap2)...
    .add('VctrlCoilServo2', rampTo(VBleeder));

%%------turn off RF knife------
s.add('Frequwave',0e6);
s.add('Ampuwave',0.);
s.add('TTLuwaveampl',0);

if(~exist('s1','var'))
    s.run();
end

end