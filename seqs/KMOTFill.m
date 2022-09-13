function s = KMOTFill()

s = ExpSeq();

DetTrap = -19e6;%was -19e6 -29e6
DetRepump = 0;% was 0  -21e6

fTrap = ((571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) - (80e6) + DetTrap) / s.C.KTrapPLLScale;
% DetTrap is the detuning from the F = 9/2 -> F' = 11/2 resonance;
fRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetRepump) / s.C.KRepumpPLLScale;
% DetRepump is the detuning from the F = 7/2 -> F' = 9/2 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

s.add('TTLMOTTelescopeShutter', 1);
s.add('TTLscope',0);
s.add('TTLKGMShutter', 0);
s.add('FreqKMOTTrap', fTrap)
s.add('FreqKMOTRepump', fRepump)
s.add('FreqKRepumpAOM', 80e6);
s.add('AmpKRepumpAOM', 0.120);
s.add('FreqKMOTAOM', 80e6);
s.add('AmpKMOTAOM',0.400);

IMOT = 20.0;
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);

s.add('VBOP', -2.5);
s.add('VBShimZ', 0.0);
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);

%----MOT fill sequence---
IMOToff=-10;%[A]
% t1=2;%[s] time to turn off MOT B field
dt1=3;
%t2=2;%[s] time to turn on MOT B field
dt2=4;

% s.wait(t1);
VMOToff = - IMOToff/s.C.TransferCoilIV;
s.addStep(dt1)...% wait a bit to make sure that MOT is completely off
    .add('VctrlCoilServo1',VMOToff);
s.addStep(dt2)...
    .add('VctrlCoilServo1',VMOT)...
    .add('TTLscope',1);

s.run();
end