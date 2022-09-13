function s = RbCMOT(s1,tCMOT)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% % % CMOT Parameters
DetCMOT = -25e6;    %-35
ICMOT = 20;%20[A]

VShimCMOT = [-3.0, 0, 0, 0]; %[VBop,VBshimX,VBshimY,VBshimZ] was -3.0
% set repump (master) laser genreted repump light parameters
AmpRbRepumpCMOT = 0.2; %was 0.200 0.025, 7/16/2018
frepump = 86e6;%86e6;%
s.add('FreqRbRepumpAOM', frepump);

% VShimCMOT = [-1.3, 0, 0, 0]; %[VBop,VBshimX,VBshimY,VBshimZ](Roughly optimized 02/23/16)
% AmpRbRepumpCMOT = 0.09; % was at 0.09 for MOT
% frepump = 90e6;%80e6;%
% s.add('FreqRbRepumpAOM', frepump);
%
% %%%Old CMOT Parameters
% DetCMOT = -22e6;
% ICMOT = 30.0;
% VShimCMOT = [-1.5, 0, 0, 0.5]; %[VBop,VBshimX,VBshimY,VBshimZ](Roughly optimized 02/23/16)
% AmpRbRepumpCMOT = 0.010; %(Roughly optimized 02/23/16) was at 0.09 for MOT
% frepump=78.4735e6;
% s.add('FreqRbRepumpAOM', frepump);

if(~exist('tCMOT','var'))
    tCMOT = 50e-3; % CMOT duration (Roughly optimized 02/23/16)
end

%% Perform CMOT
s.add('AmpRbEOM', 0);
s.addStep(@SetRbMOTBeamsAndB,...
    1, DetCMOT, ICMOT, VShimCMOT, AmpRbRepumpCMOT, tCMOT);

if(~exist('s1','var'))
    s.run();
end
end

