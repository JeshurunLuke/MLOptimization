function s = RbGM(s1, tRbGM)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if (~exist('tRbGM','var'))
    tRbGM = 5e-3;
end

%% Rb Molasses Parameters
FreqRbRepumpGM = 834.3e6;%834.683
AmpRbRepumpGM = 0.20;%0.07
Gamma = 6.065e6;
Delta22 = 10*Gamma;
DetRbGMCool = Delta22 - 266.65e6;     %cooling laser detuning from F=2 --> F=3' transition
%% Coil parameters
VShimMolasses = [1, -2.5, -2.5, 0];%[VBop,VBshimX,VBshimY,VBshimZ][-1, 0, 0.0, -0.5]
% VShimMolasses = [0, 0, 0, 0];%[VBop,VBshimX,VBshimY,VBshimZ][-1, 0, 0.0, -0.5]
IMOT = -15;%negative means off

%% Turn off Rb repump from master laser
AmpRbRepump = 0.0;

%% Set frequency and amplitude of Rb EOM
s.add('FreqRbEOM', FreqRbRepumpGM);
s.add('AmpRbEOM', AmpRbRepumpGM);
s.addStep(@SetRbMOTBeamsAndB,...
    1, DetRbGMCool, IMOT, VShimMolasses, AmpRbRepump, tRbGM);
s.wait(1e-6);
s.add('AmpRbEOM', 0);       %turn off Rb grey molasses repump AOM

if(~exist('s1','var'))
    s.run();
end

end

