function s = mainQtrap(x)

s = ExpSeq();

MOTShutterDelay = 2.8e-3;

%% ------Default camera triggers----------
s.add('TTLscope',0);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.addStep(@MakeRbMOT);
t1=4.0;%[s] old value 2.5 s
s.wait(t1);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge

%% --------------Rb CMOT----------
tCMOT=50e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses----------
tMolas=20e-3;%[s]The time duration of molasses
s.addStep(@RbMolasses,tMolas);%takes 20ms

%% --------------Optical pumping (OP)----------
tOP=4e-3;%[s]should>(ShutterDelay+Delay)
s.addStep(@OP,tOP);%

%% --------------Qtrap----------
tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);

%% --------------Forward cart transfer----------
tFwdTrip = 3409e-3;%[s]1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
s.addStep(@TrackTransfer,tFwdTrip);

% %% ------------Evap in Qtrap----------
s.wait(400e-3);
s.addStep(@RFevap1);
s.wait(400e-3);

%% --------------TOF imaging in evap chamber-----------
TOFRb=5.0e-3;%[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK=0.5e-3;%[s]
% m = MemoryMap;
% m.Data(1).flagCam=1;
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
s.wait(ShutterDelay);
s.addStep(@Qtrapoff);      %turn off the trap, takes no time
% s.add('TTLscope',1); %trigger oscilloscope
% s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
s.addStep(@imagingTOF, TOFRb, TOFK);
%
%% --------------Backward cart transfer----------
tTrackTrig = 20e-3;
s.addStep(@TrackTransfer,tTrackTrig);

%% -------------Fluorescence imaging with MOT configuration-----------
s.addStep(1e-6)...
    .add('VctrlCoilServo1',-20.0/s.C.TransferCoilIV);
% s.wait(5e-3);
s.addStep(1.5e-3) ...
    .add('TTLMOTTelescopeShutter', 1) ...
    .add('TTLRbMOTShutter', 1);

s.addStep(@MakeRbMOT);

s.addStep(10e-6) ...
    .add('TTLscope',1) ... %trigger oscilloscope
    .add('TTLMOTCCD', 0); % trigger Thorlab camera%recapture into MOT for imaging
% s.addStep(@SetRbMOTBeamsAndB,...
%     1,1, -23e6, 0, [0,0,0,0], 0.09, 1e-6);
%s.wait(MOTShutterDelay-1.5e-3);

s.addStep(1e-6) ...
    .add('TTLMOTTelescopeShutter', 0);%turn down both Rb and K MOT beams

s.wait(0e-3);
t3=0.1;
s.wait(t3);

%% --------------Rb MOT-----------
s.addStep(@MakeRbMOT);

s.run();
end