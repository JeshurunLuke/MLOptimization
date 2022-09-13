function s = MakeRbMolasses()

s = ExpSeq();

% Make Rb MOT

s.addStep(@MakeRbMOT);
s.wait(2.0);

DetMolasses = -150e6;
VShimMolasses = [-1, 0, 0.0, -0.2];%[-0.25, -4.0, -0.0, -0.20]; [VBop,VBshimX,VBshimY,VBshimZ](Roughly optimized 02/23/16)
AmpRbRepumpMolasses = 0.030;
IMOT = - 15;%negative means off
tMolasses = 3.0;
MOTShutterDelay = 2.8e-3;

s.addStep(MOTShutterDelay) ...
    .add('TTLMOTShutters', 1) ...
    .add('TTLscope',1);

s.addStep(@SetRbMOTBeamsAndB,...
    1, DetMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, tMolasses);

% Make Rb MOT again

s.addStep(@MakeRbMOT);
s.wait(2.0);

s.run();
end

% Parameter backup (02/23/16)
% s.add('VctrlCoilServo1',VMOT);
% s.add('VBOP', -0.25);
% s.add('VBShimX', -4.0);
% s.add('VBShimY', -2.5);
% s.add('VBShimZ', -0.100);

