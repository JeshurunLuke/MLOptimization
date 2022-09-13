function s = KrfARP(s1)
%% this code is for ARP K atoms from |9/2, 9/2> to |9/2,-9/2>
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
%%======RF in Science chamber===
B0 = 25.8;            %[G] this value is only for estimation of fDDS0
gF92 = 2/9;         %g-factor for F=9/2
uB = 1.3996246e6;       %[Hz/G] Bohr Magneton
% fDDS0 = 10.1e6;                %10.5e6 gF92*(9/2-7/2)*uB*B0

% ARPrate = 1/4;%%ARP rate [MHz/ms]
fDDS0 = 8.1e6;      %8.1 center ARP frequency, should be estimated by gF92*(9/2-7/2)*uB*B0
df = 1.4e6;         %[Hz] ARP deviation 1.4
fDDS1 = fDDS0 + df/2;
fDDS2 = fDDS0 - df/2;

dfdt = 0.04*1e6/1e-3;  %[Hz/s] 0.04e9
dt = df/dfdt;          %[s] ARP duration

s.add('FreqKRF', fDDS1);
s.wait(1e-6);
s.addStep(dt)...
    .add('FreqKRF', rampTo(fDDS2))...
    .add('AmpKRF', 0.45);      %check calibration of RF Amp on 11/18/2019, 0.45<->32 dBm

s.wait(0.001e-3);
s.add('AmpKRF',0);

% %%======RF in Science chamber===
% B0 = 15.83;            %[G] this value is only for estimation of fDDS0
% gF92 = 2/9;         %g-factor for F=9/2
% uB = 1.3996246e6;       %[Hz/G] Bohr Magneton
% % fDDS0 = 10.1e6;                %10.5e6 gF92*(9/2-7/2)*uB*B0
% 
% % ARPrate = 1/4;%%ARP rate [MHz/ms]
% fDDS0 = 5.2e6;      %5.2 center ARP frequency, should be estimated by gF92*(9/2-7/2)*uB*B0
% df = 1e6;         %[Hz] ARP deviation
% fDDS1 = fDDS0 + df/2;
% fDDS2 = fDDS0 - df/2;
% 
% dfdt = 0.04e9;  %[Hz/s] 1e6/3.5e-3
% dt = df/dfdt;          %[s] ARP duration
% 
% s.add('FreqKRF', fDDS1);
% s.wait(1e-6);
% s.addStep(dt)...
%     .add('FreqKRF', rampTo(fDDS2))...
%     .add('AmpKRF', 1);      %was 0.6
% 
% s.wait(0.001e-3);
% s.add('AmpKRF',0);



if(~exist('s1','var'))
    s.run();
end

end