function s = Qtrap(s1,tQtrap)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Qtrap Parameters

IQtrap = 320;%20[A]=10G/cm=>60A=30G/cm, Value in Use=320
VMOT = - IQtrap/s.C.TransferCoilIV;
VShim = [0, 0.0, 0.0, 0]; %[VBop,VBshimX,VBshimY,VBshimZ](Roughly optimized 02/23/16)
if(~exist('tQtrap','var'))
    tQtrap = 400e-3; % [s]Molasses duration (Roughly optimized 02/23/16)
end

s.addStep(tQtrap)...
    .add('VBOP', VShim(1)) ...
    .add('VBShimX', VShim(2)) ...
    .add('VBShimY', VShim(3)) ...
    .add('VBShimZ', VShim(4)) ...
    .add('VctrlCoilServo1', VMOT);%rampTo(VMOT)

if(~exist('s1','var'))
    s.run();
end
end

