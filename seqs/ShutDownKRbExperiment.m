function s = ShutDownKRbExperiment(s1)
if(~exist('s1','var'))
    % Initialize the sequence
    s = ExpSeq();
else
    s=s1;
end

% % Block YAG laser to save lifetime of Dye
% ThorlabsEll0ControlForward;
% Turn off ionization beam shutter
s.add('TTLionShutter', 0);
%Trigger the scope
s.addStep(10e-6)...
    .add('TTLscope', 1);
%Turn off UV LED
s.add('TTLMOTCCD', 0);

%Turn off all coils
s.add('VBOP', 0);
s.add('VBShimX', 0);
s.add('VBShimY', 0);
s.add('VBShimZ', 0);
s.add('Vquant1',0);
s.add('VctrlCoilServo1',1);
s.add('VctrlCoilServo2',1);
s.add('VctrlCoilServo3',1);
s.add('VctrlCoilServo4',0.5);
s.add('VctrlCoilServo5',0.5);
s.add('VctrlCoilServo6',0.5);

%Turn off all shutters
s.add('TTLMOTShutters', 0);
s.add('TTLOPShutter', 0);
s.add('TTLKGMShutter', 0);

%Turn off ODT switch
s.add('TTLODT1',0);
s.add('TTLODT2',0);

%Turn off the track trigger
s.add('TTLTrackStart',0);
s.add('TTLABLstage',0);

%Turn off the XLN3640 P/S
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);
s.add('TTLscope',0);

if(~exist('s1','var'))
    s.run();
end
end