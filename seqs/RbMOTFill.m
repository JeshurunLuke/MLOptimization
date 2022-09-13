function s = RbMOTFill()

s = ExpSeq();

Det = - 25e6;%detuning for cooling beam, "-" means red detune

f = ((6.834682610 * 1e9 - 156.9470/2 * 1e6 - 266.6500*1e6) - Det) / s.C.RbPLLScale;
% Det is the detuning from the F = 2 -> F' = 3 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;


s.add('TTLMOTTelescopeShutter', 1);
s.add('TTLRbMOTShutter', 1);
s.add('FreqRbMOTTrap', f)
s.add('AmpRbRepumpAOM', 0.1200);

IMOT = 20.0;
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);
s.add('VBOP', -5.0);
s.add('VBShimZ', 0.0);
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);

%----MOT fill sequence---
IMOToff=-10;%[A]
t1=3;%[s] time to turn off MOT B field
% dt1=2;
%t2=2;%[s] time to turn on MOT B field
dt2=10;

VMOToff = - IMOToff/s.C.TransferCoilIV;
s.addStep(t1)...
    .add('VctrlCoilServo1',VMOToff)...
    .add('VBOP', 0.0)...
    .add('VBShimZ', 0.0)...
    .add('VBShimY', 0.0)...
    .add('VBShimX', 0.0)...
    .add('TTLRbMOTShutter', 0);

s.addStep(dt2)...
    .add('VctrlCoilServo1',VMOT)...
    .add('VBOP', -5.0)...
    .add('VBShimZ', 0.0)...
    .add('VBShimY', 0.0)...
    .add('VBShimX', 0.0)...
    .add('TTLRbMOTShutter', 1)...
    .add('TTLscope',1);

s.run();
end