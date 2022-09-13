function s = mainRecapture()

s = ExpSeq();

MOTShutterDelay = 2.8e-3;%[s]

%%---Choose species (for K recapture, set oscilloscope scale=10mV and offset=385mV)--
Rbrecap = 1; %set to 1 for Rb recapture, 0 for K recapture
%%-------------------

%% ------Default camera triggers----------
s.add('TTLscope',0);

%% -----------------Rb MOT----------
% if Rbrecap
%     s.addStep(@MakeRbMOT);
% else
%     s.addStep(@MakeKMOT);
% end
% 
% t1=3.0;%[s] old value 2.5 s
% s.wait(t1);%wait for t1 at Rb MOT stage
% % s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge
% s.add('TTLscope',1);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.add('TTLMOTCCD', 1);     % UV LED TTL, 0 - off, 1 - on
if Rbrecap
    s.addStep(@MakeRbMOT);
else
    s.addStep(@MakeKMOT);
end
tMOTUV = 1.5;       %[s] old value 2 s
s.wait(tMOTUV);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
tMOTHold = 5.0;
s.wait(tMOTHold);
s.add('TTLscope',1);

%% --------------Rb CMOT----------
tCMOT=50e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
if 1
    tMolas = 10e-3;%[s]The time duration of molasses
    s.addStep(@RbAndKGM,tMolas);%takes 20ms, for turning on Rb molasses only
%     s.addStep(@RbGM,tMolas);
else
    tMolas = 20e-3;%[s]The time duration of molasses
    s.addStep(@Molasses,tMolas);%takes 20ms , include K D1 gray molasses
end

% tMolas = 50e-3;%[s]The time duration of molasses
% s.addStep(@Molasses,tMolas);%takes 20ms

%% --------------Optical pumping (OP)----------
tOP=6e-3;%[s]should>(ShutterDelay+Delay)
s.addStep(@OP,tOP);%

%% --------------Loading atoms into the transfer coil---------
% IQtrap=320.0;%[A}
% tQtrap=100e-3;%[s] 100e-3
% s.addStep(@TransferLoad,IQtrap,tQtrap);
tQtrap = 10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);
s.wait(100e-3);


%% -------------Fluorescence imaging with MOT configuration-----------
s.addStep(1e-6)...
    .add('VctrlCoilServo1',-20.0/s.C.TransferCoilIV);
% s.wait(5e-3);
s.addStep(2.8e-3) ...
    .add('TTLMOTShutters', Rbrecap)... % for K only recapture, use 0
    .add('TTLKGMShutter', 0);

if Rbrecap
    s.addStep(@MakeRbMOT);
else
    s.addStep(@MakeKMOT);
end
s.wait(100e-3);

s.addStep(10e-6) ...
    .add('TTLscope',0); %trigger oscilloscope
%     .add('TTLMOTCCD', 0); % trigger Thorlab camera%recapture into MOT for imaging

s.addStep(1e-6) ...
    .add('TTLMOTShutters', 0);%turn down both Rb and K MOT beams

s.wait(0e-3);
t3=0.5;
s.wait(t3);
s.add('TTLscope',0);
%% --------------Rb MOT-----------
if Rbrecap
    s.addStep(@MakeRbMOT);
else
    s.addStep(@MakeKMOT);
end

s.run();
end