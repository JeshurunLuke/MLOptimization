function s = ODTEvapPowerLaw(s1)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

VODT0 = 0.40;
VODT1 = 0.08;        %DAC value 0-1V, negative means off
VODTmin = 0.00; %Minimum ODT power
eta = 8.0;       %eta = U/kT
tau = 1.0;        %[s] evaporation time constant

if VODT1>=VODT0
    error('VODT1 should < VODT0');
end
if VODT1<=VODTmin
    error('VODT1 should > VODTmin');
end

% ODT evaporation duration
tODTevap = tau.*((VODT1./VODT0).^(-eta./(2.*(eta - 3))) - 1);

if tODTevap > 10
    error('Too long ODT evaporation time!');
end
disp(['ODT evap takes ',num2str(tODTevap),'s']);
disp(['ODT stops at ',num2str(VODT1),'V']);

%Start the power-law evaporation trajectory
Ni=300;
dt = tODTevap/Ni;
s.wait(dt);
for i = 1:Ni
    Vt = VODT0.*(1 + i.*dt./tau).^(-2.*(eta - 3)./eta);
    s.addStep(dt)...
     .add('ODT1',Vt);
end

%At the end of the evaporation, ramp the optical power back to VODT0
s.addStep(200e-3) ...
    .add('ODT1', rampTo(0.12));

if(~exist('s1','var'))
    s.run();
end

end