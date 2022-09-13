function s = mainRecapRoundTrip()

s = ExpSeq();

MOTShutterDelay = 2.8e-3;%[s]

%%---Choose species (for K recapture, set oscilloscope scale=10mV and offset=385mV)--
Rbrecap=1; %set to 1 for Rb recapture, 0 for K recapture
%%-------------------

%% ------Default camera triggers----------
s.add('TTLscope',0);

%% -----------------Rb MOT----------
if Rbrecap
    s.addStep(@MakeRbMOT);
else
    s.addStep(@MakeKMOT);
end

t1=2.0;%[s] old value 2.5 s
s.wait(t1);%wait for t1 at Rb MOT stage
% s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge
%s.add('TTLscope',1);

% --------------Rb CMOT----------
tCMOT=50e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
tMolas=20e-3;%[s]The time duration of molasses
s.addStep(@Molasses,tMolas);%takes 20ms
% s.addStep(@MolassesTest);%

% --------------Optical pumping (OP)----------
tOP=6e-3;%[s]should>(ShutterDelay+Delay)
s.addStep(@OP,tOP);%

% --------------Loading atoms into the transfer coil---------
tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);
s.wait(10e-3);

% IQtrap=320.0;%[A}
% tQtrap=100e-3;%[s] 100e-3
% s.addStep(@TransferLoad,IQtrap,tQtrap);
% s.wait(10e-3);

%% --------------Round trip transfer------------
% [Distance (mm) One-way time (ms)]
% [30 381]
% [50 538]
% [100 760]
% For transfering before the "kink", use transfer_variable_wait_2
% For transfering to and after the "kink", use transfer_variable_wait_4
tTrip = 381e-3; %[s]381 ms for 30 mm, 602ms for 100 mm, 1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
% s.addStep(@TrackTransfer,tTrackTrig);
s.addStep(@TrackTransfer,tTrip);
s.wait(100e-3);
s.addStep(@TrackTransfer,tTrip);

%% -------- Turn off MOT light -----------
% s.addStep(2.8e-3)...
%     .add('VctrlCoilServo1',0.5)...
%     .add('TTLRbMOTShutter', 0);
% % s.wait(40e-3); % Insert TOF here

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
s.wait(10e-3);

s.addStep(10e-6) ...
    .add('TTLscope',1); %trigger oscilloscope
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