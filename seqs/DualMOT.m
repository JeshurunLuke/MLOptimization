function s = DualMOT()

s = ExpSeq();
%%%------------MOT coil setting-----------
IMOT = 20.0;% [A] 20A means 10G/cm
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);
s.add('VBOP', -4.0);
s.add('VBShimZ', 0.0);
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);

%%%----------------------Rb MOT setting----------------
Det = - 22e6;%detuning for cooling beam, "-" means red detune
f = ((6.834682610 * 1e9 - 156.9470/2 * 1e6 - 266.6500*1e6) - Det) / s.C.RbPLLScale;
% Det is the detuning from the F = 2 -> F' = 3 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

s.add('TTLMOTTelescopeShutter', 1);
s.add('TTLRbMOTShutter', 1);
s.add('FreqRbMOTTrap', f)
s.add('AmpRbRepumpAOM', 0.090);

%%%----------------------K MOT setting----------------
DetTrap = - 19e6;%was -19e6
DetRepump = 0e6;%was 0

fTrap = ((571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) - (80e6) + DetTrap) / s.C.KTrapPLLScale;
% DetTrap is the detuning from the F = 9/2 -> F' = 11/2 resonance;
fRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetRepump) / s.C.KRepumpPLLScale;
% DetRepump is the detuning from the F = 7/2 -> F' = 9/2 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

s.add('TTLMOTTelescopeShutter', 1);%MOT table shutter for both species
s.add('TTLKMOTShutter', 1);
s.add('FreqKMOTTrap', fTrap)
s.add('FreqKMOTRepump', fRepump)
s.add('FreqKRepumpAOM', 80e6);
s.add('AmpKRepumpAOM', 0.120);
s.add('FreqKMOTAOM', 80e6);
s.add('AmpKMOTAOM',0.400);

%%------------run--------
s.run();
end

