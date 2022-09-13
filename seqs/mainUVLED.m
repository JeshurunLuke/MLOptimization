function s = mainUVLED(tUVExposure, uv_light)

s = ExpSeq();

% MOTShutterDelay = 2.8e-3;%[s]

%%---Choose species (for K recapture, set oscilloscope scale=10mV and offset=385mV)--
Rbrecap=1; %set to 1 for Rb recapture, 0 for K recapture

%% ------Default camera triggers----------
s.add('TTLscope',0);

%%---MOT off---
s.addStep(1) ...
    .add('TTLMOTTelescopeShutter', 0);

%%---UV LED exposure---
s.add('TTLMOTCCD', uv_light); % This is the UV LED TTL
% tUVExposure = 2;
s.wait(tUVExposure);

%% -----------------Rb MOT----------
s.add('TTLscope', 1);
if Rbrecap
    s.addStep(@MakeRbMOT);
else
    s.addStep(@MakeKMOT);
end

% s.wait(tUVLEDdelay); % wait extra time for vacuum recovery
s.add('TTLMOTCCD', 0);
s.wait(3);

%
% t1=3.0;%[s] old value 2.5 s
% s.wait(t1);%wait for t1 at Rb MOT stage
% s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge
% %s.add('TTLscope',1);


%% --------------Rb CMOT----------
% tCMOT=50e-3;%[s]The time duration of CMOT
% s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
% tMolas=20e-3;%[s]The time duration of molasses
% s.addStep(@Molasses,tMolas);%takes 20ms

%% --------------Optical pumping (OP)----------
% tOP=4e-3;%[s]should>(ShutterDelay+Delay)
% s.addStep(@OP,tOP);%

%% --------------Loading atoms into the transfer coil---------
% IQtrap=320.0;%[A]
% tQtrap=100e-3;%[s] 100e-3
% s.addStep(@TransferLoad,IQtrap,tQtrap);
% s.wait(10e-3);


%% -------------Fluorescence imaging with MOT configuration-----------
% s.addStep(1e-6)...
%     .add('VctrlCoilServo1',-20.0/s.C.TransferCoilIV);
% % s.wait(5e-3);
% s.addStep(2.8e-3) ...
%     .add('TTLMOTTelescopeShutter', 1) ...
%     .add('TTLRbMOTShutter', Rbrecap)... % for K only recapture, use 0
%     .add('TTLKGMShutter', 0);
%
% if Rbrecap
%     s.addStep(@MakeRbMOT);
% else
%     s.addStep(@MakeKMOT);
% end
% s.wait(100e-3);
%
% s.addStep(10e-6) ...
%     .add('TTLscope',1) ... %trigger oscilloscope
%     .add('TTLMOTCCD', 0); % trigger Thorlab camera%recapture into MOT for imaging
%
% s.addStep(1e-6) ...
%     .add('TTLMOTTelescopeShutter', 0);%turn down both Rb and K MOT beams
%
% s.addStep(1e-6) ...
%      .add('TTLUVLED', 1);
% s.wait(duration);
% s.addStep(1e-6) ...
%      .add('TTLUVLED', 0);
%
% s.wait(x);

% --------------Rb MOT-----------
% if Rbrecap
%     s.addStep(@MakeRbMOT);
% else
%     s.addStep(@MakeKMOT);
% end

s.run();
end