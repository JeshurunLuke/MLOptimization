function s = RbevapARP(s1, fARP)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% %%%========u wave ARP |22> to |11> in Science chamber===
%%constant frequency parameter
fHP = 6834.682e6; % [Hz] hyperfine splitting frequency
fsyn = 3533.25e6*2; % [Hz] Valon synthesizer + frequency doubler
uB = 1.3996246e6;       %[Hz/G] Bohr Magneton

%%----------set parameters for a B field--------
B0 = 15.83; %[G]
gF22 = 1/2;
gF11 = -1/2;
% f22to11 = fHP + (gF22*2-gF11*1)*uB*B0;      %[Hz] energy difference between |22> and |11> at B0
f22to11 = fARP*1e6;                         %[Hz] energy difference between |22> and |11> at B0
fDDS0 = fsyn - f22to11;                     %[Hz] center DDS RF frequency, final output frequency from mixer is fsyn - fDDS;

% dfdt = 0.1e9;
df = 2e6;                                      %[G] ARP frequency deviation
dt = 20e-3;                                  %[s] ARP duration

fDDS1 = (fDDS0 + df/2);
fDDS2 = (fDDS0 - df/2);

s.add('Frequwave', fDDS1);
s.wait(1e-6);                              %wait for TTL uwave switch to open
s.addStep(dt)...
    .add('Frequwave', rampTo(fDDS2))...
    .add('Ampuwave',1);
s.wait(0.001e-3);
s.add('Ampuwave',0);


if(~exist('s1','var'))
    s.run();
end

end