function s = RbMolasses(s1,tMolas)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%% Rb Molasses Parameters
DetRbMolasses = -150e6;%was at -40e6; -150e6 11/20/2016
% VShimMolasses = [-2.5,0, 0, -.2];%[VBop,VBshimX,VBshimY,VBshimZ]
% VShimMolasses = [-1.5,-0.8, +0.8, -0.2];%[VBop,VBshimX,VBshimY,VBshimZ]
AmpRbRepumpMolasses = 0.225;%was 0.025 %11/20/2016
fRbRepump = 86e6;%was at 85MHz,86.5MHz from 11/20/2016, 85 MHz from 04/25/2017
s.add('FreqRbRepumpAOM', fRbRepump);

%% Coil parameters
VShimMolasses = [0, 0, 0.0, -0.5];%[VBop,VBshimX,VBshimY,VBshimZ]([-0.25, -4.0, -0.0, -0.2]Roughly optimized 02/23/16)
IMOT = -15;%negative means off

%%
if(~exist('tMolas','var'))
    tMolas = 20e-3; % [s]Molasses duration (Roughly optimized 02/23/16)
end

s.addStep(@SetRbMOTBeamsAndB,...
    1, DetRbMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, tMolas);

if(~exist('s1','var'))
    s.run();
end
end

