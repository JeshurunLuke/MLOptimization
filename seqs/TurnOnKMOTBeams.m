function s = TurnOnKMOTBeams(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

DetTrap = - 19e6;%was -19e6
DetRepump = 0e6;%was 0

fTrap = ((571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) - (80e6) + DetTrap) / s.C.KTrapPLLScale;
% DetTrap is the detuning from the F = 9/2 -> F' = 11/2 resonance;
fRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetRepump) / s.C.KRepumpPLLScale;
% DetRepump is the detuning from the F = 7/2 -> F' = 9/2 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

s.add('TTLMOTTelescopeShutter', 1);
s.add('TTLKMOTShutter', 1);
s.add('FreqKMOTTrap', fTrap)
s.add('FreqKMOTRepump', fRepump)
s.add('FreqKRepumpAOM', 80e6);
s.add('AmpKRepumpAOM', 0.120);
s.add('FreqKMOTAOM', 80e6);
s.add('AmpKMOTAOM',0.400);

IMOT = -20.0; %[A]
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);
s.add('VBOP', -0.0);%-6.5
s.add('VBShimZ', 0.0);%1.5
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);

if(~exist('s1','var'))
    s.run();
end

end