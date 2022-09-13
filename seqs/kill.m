function s = kill(s1, f22to11, df, tkill)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
if(~exist('tkill','var'))
    tkill = 5e-3;%[s]
end

if(~exist('f22to11','var'))
    f22to11 = 8036e6;%8035e6;  
end

if(~exist('df','var'))
    df = 2e6;
end
%%%%-------------K------------
% %----Imaging pulse for removing leftover F=2 atoms-----
fKprobe = -760e6+50e6;
fKprobeRepump = (571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) + fKprobe;     % [Hz]reference to locking point of K39 master laser
fKRepump = abs(fKprobeRepump - 110e6) / s.C.KRepumpPLLScale;          % 110MHz is for compensating a +1 order AOM
AmpDDSKKill = 0.300;        % DDS amplitude for K kill pulse after GS molecule step
%%%%%%%%%%----Rb----------
fsyn = 4120.0e6*2; % [Hz] Valon synthesizer + frequency doubler                       %[Hz] energy difference between |22> and |11> at B0
fDDS0 = fsyn - f22to11;                     %[Hz] center DDS RF frequency, final output frequency from mixer is fsyn - fDDS;

dfdt = 4*4e6/8e-3;                              %[G] ARP frequency deviation
dt = df/dfdt;                                  %[s] ARP duration

fDDS2 = (fDDS0 + df/2);
fDDS1 = (fDDS0 - df/2);

s.add('Frequwave', fDDS1);
s.wait(1e-6);                              %wait for TTL uwave switch to open

if dt > tkill
    error('tkill need > dt');
end
s.add('TTLImagingShutter', 1);
s.add('AmpRbOPZeemanAOM', 0.15)...    %%don't exceed 0.3 V
    .add('Ampuwave', 0.4)...
    .add('AmpKOPRepumpAOM', AmpDDSKKill);
s.addStep(tkill)...
    .add('Frequwave', rampTo(fDDS2))...
    .add('FreqKMOTRepump',rampTo(fKRepump));

s.add('AmpKOPRepumpAOM', 0.0)...        %%don't exceed 0.3 V
    .add('AmpRbOPZeemanAOM', 0)...
    .add('Ampuwave',0)...
    .add('TTLImagingShutter', 0);

if(~exist('s1','var'))
    s.run();
end

end