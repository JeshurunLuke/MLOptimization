function s = MakeRbMOT(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s=s1;
end

DetCooling = -25e6;% -23e6;

f = ((6.834682610 * 1e9 - 156.9470/2 * 1e6 - 266.6500*1e6) - DetCooling) / s.C.RbPLLScale;
% Det is the detuning from the F = 2 -> F' = 3 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

% s.add('TTLscope',1);
s.add('TTLMOTShutters', 1);
s.add('FreqRbMOTTrap', f)...
    .add('AmpRbMOTTrap',1.0);
% set repump (master) laser genreted repump light parameters
frepump = 78.4735e6;
s.add('FreqRbRepumpAOM', frepump)...
    .add('AmpRbRepumpAOM', 0.0); % was 0.075
% set EOM generated repump light parameters
DetRepump = -5.*1e6;
AmpRbRepumpMOT = 0.20; %0.2 
%Was AmpRbRepumpMOT = 0.1 on 3/1/2020;
FreqRbRepumpMOT = 834.683*1e6 - DetCooling - 266.6500*1e6 + DetRepump;
s.add('FreqRbEOM', FreqRbRepumpMOT);
s.add('AmpRbEOM', AmpRbRepumpMOT);


IMOT = 20.0;%[A]
VMOT = - IMOT/s.C.TransferCoilIV;

s.add('VctrlCoilServo1',VMOT);
s.add('VBOP', -5.0);%-5
s.add('VBShimZ', 0);%0.0 
s.add('VBShimY', 0);
s.add('VBShimX', 0);

% s.wait(0.5)
% s.add('TTLscope',0);

if(~exist('s1','var'))
    s.run();
end

end

% Old parameters
% For MOT beam total power = 120 mW
% IMOT = 15.0;
% s.add('VBOP', -4.0);
% s.add('VBShimZ', 1.5);
% s.add('VBShimY', 0.0);
% s.add('VBShimX', 0.0);

% For MOT beam total power = 250 mW
% IMOT = 25.0;
% s.add('VBOP', -9.0);
% s.add('VBShimZ', 2.5);
% s.add('VBShimY', -0.0);
% s.add('VBShimX', 0.0);