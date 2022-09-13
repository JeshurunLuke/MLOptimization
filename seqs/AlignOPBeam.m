function s = AlignOPBeam()

s = ExpSeq();

DetMOT = - 10e6;
DetOPZeeman = 0e6;

fMOT = ((6.834682610 * 1e9 - 156.9470/2 * 1e6 - 266.6500*1e6) - DetMOT) / s.C.RbPLLScale;
% Det is the detuning from the F = 2 -> F' = 3 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

s.add('TTLMOTTelescopeShutter', 1);
s.add('FreqRbMOTTrap', fMOT)
s.add('AmpRbRepumpAOM', 0.090);

IMOT = 200.0;
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);
s.add('VBOP', 0.0);
s.add('VBShimZ', 0.0);
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);



s.run();
end