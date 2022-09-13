function s = MakeKMOT(s1,x)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

DetTrap = - 19.*1e6;%was -19e6
DetRepump = - 0.*1e6;%was -20e6

fTrap = ((571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) - (80e6) + DetTrap) / s.C.KTrapPLLScale;
% DetTrap is the detuning from the F = 9/2 -> F' = 11/2 resonance;
fRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetRepump) / s.C.KRepumpPLLScale;
% DetRepump is the detuning from the F = 7/2 -> F' = 9/2 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

IMOT = 20.0; %[A]
VMOT = - IMOT/s.C.TransferCoilIV;

s.addStep(1e-3)...
    .add('TTLMOTShutters', 1)...
    .add('TTLKGMShutter', 0)...
    .add('FreqKMOTTrap', rampTo(fTrap))...
    .add('FreqKMOTRepump', rampTo(fRepump))...
    .add('AmpKMOTTrap',0.68)...
    .add('AmpKMOTRepump',0.68)...
    .add('FreqKRepumpAOM', 80e6)...
    .add('AmpKRepumpAOM', 0.15)...  % was 0.16 on 06/08/20 after increasing TA operating current; 
    .add('FreqKMOTAOM', 80e6)...
    .add('AmpKMOTAOM', 0.2)... %was 0.2 0.175
    .add('VctrlCoilServo1',VMOT)...
    .add('VBOP', -5.0)...%-5.0
    .add('VBShimZ', 0)...%1.5
    .add('VBShimY', 0.0)...
    .add('VBShimX', 0.0);

if(~exist('s1','var'))
    s.run();
end

end