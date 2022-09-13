function s = RbAndKGM(s1, tRbGM)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if (~exist('tRbGM','var'))
    tRbGM = 5e-3;
end

%% Rb gray Molasses Parameters
FreqRbRepumpGM = 834.3e6;%834.683
AmpRbRepumpGM = 0.2;%0.07
%AmpRbRepumpGM = 0.20
Gamma = 6.065e6;
Delta22 = 10*Gamma;
DetRbGMCool = Delta22 - 266.65e6;     %cooling laser detuning from F=2 --> F=3' transition
%% K gray molasses Parameters
 % We lock on the (F=1,2 crossover -> F'=2) peak, corresponding to laser
 % frequency 770.108 nm +78.55MHz.
 % We always divide by 2 because the shift is done through a double-pass AOM setup
DetKCoolMolasses = 24e6; %positive means blue detuned, was 14e6
%Was 24e6 1/6/2020
DetKRepumpMolasses = 14e6; %positive means blue detuned, 14e6
%Was 14e6 1/6/2020
FreqKCoolMolasses = (-20.8e6 - 57.75e6 + 571.5e6 + 211.9e6)/2  + DetKCoolMolasses/2; %double-pass AOM is +1 order
FreqKRepumpMolasses = (20.8e6 + 57.75e6  + (-571.5e6 + 1285.8e6) - 211.9e6)/2 - DetKRepumpMolasses/2; %double-pass AOM is -1 order
AmpKMolasses = 0.1150;%
AmpKRepumpMolasses = 0.285;
ShutterDelay = 2.8e-3;

%% Coil parameters
VShimMolasses = [1.0, -2.5, -2.5, 0];%[VBop,VBshimX,VBshimY,VBshimZ][1, -2.5, -2.5, 0] [-1, 0, 0.0, -0.5]
% VShimMolasses = [0, 0, 0, 0];%[VBop,VBshimX,VBshimY,VBshimZ][-1, 0, 0.0, -0.5]
IMOT = -15;%negative means off

%% Turn off Rb repump from master laser
AmpRbRepump = 0.0;

%% Set frequency and amplitude of Rb EOM
s.addStep(ShutterDelay)...
    .add('TTLKGMShutter',1)...
    .add('AmpKMOTAOM',0.000);

s.addStep(1e-6)...
    .add('FreqKGMCoolAOM',FreqKCoolMolasses)...
    .add('AmpKGMCoolAOM',AmpKMolasses)...
    .add('FreqKGMRepumpAOM',FreqKRepumpMolasses)...
    .add('AmpKGMRepumpAOM',AmpKRepumpMolasses)...
    .add('FreqRbEOM', FreqRbRepumpGM)...
    .add('AmpRbEOM', AmpRbRepumpGM);
    
s.addStep(@SetRbMOTBeamsAndB,...
    1, DetRbGMCool, IMOT, VShimMolasses, AmpRbRepump, tRbGM);

s.wait(1e-6);
s.add('AmpRbEOM', 0);       %turn off Rb grey molasses repump AOM

if(~exist('s1','var'))
    s.run();
end

end

