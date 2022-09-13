function s = mainQUIC()

s = ExpSeq();

%% ------Add dummy pulse to trigger the NIDAQ----------
% s.addStep(1e-3)...
%     .add('XLN3640VP', linearRamp(0, 1))...
%     .add('Dummy1', linearRamp(0, 1));

%% ------Default camera triggers----------
s.add('TTLscope',0);
VPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
t1=2;%[s] old value 10 s; old value 2.5 s
s.wait(t1);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge

%% --------------Rb CMOT----------
tCMOT=50e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
tMolas=20e-3;%[s]The time duration of molasses
s.addStep(@Molasses,tMolas);%takes 20ms
% s.addStep(@RbMolasses,tMolas);%takes 20ms, for turning on Rb molasses only

%% --------------Optical pumping (OP)----------
tOP=4e-3;%[s]should>(ShutterDelay+Delay)
s.addStep(@OP,tOP);%

%% --------------Loading atoms into the transfer coil---------
tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);

% IWeakQtrap = 55; % Emperically determined filtering current
% tWeakQtrap = 10e-6;
% s.addStep(@TransferLoad,IWeakQtrap,tWeakQtrap);
% s.wait(200e-3);
%
% IQtrap=320.0;%[A}
% tQtrap=20e-3;%[s] 100e-3
% s.addStep(@TransferLoad,IQtrap,tQtrap);
% s.wait(10e-3);

% s.addStep(@TransferLoad,x,100e-3);
% s.wait(200e-3); %Hold the atoms in the QUIC trap for some time
% s.addStep(@TransferLoad,320,100e-3);

%% --------------Forward cart transfer----------
tTrackTrig = 1e-3; % min value 1 ms
tFwdTrip = 3409e-3; %updated from 3412e-3 on 05/14/2017; [s]1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
% s.addStep(@TrackTransfer,tTrackTrig);
s.addStep(@TrackTransfer,tFwdTrip);

%% -----------Loading and spin filtering in the transfer coil-------
% % tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
% % s.addStep(@Qtrap,tQtrap);
%
% IWeakQtrap = 55; % Emperically determined filtering current
% tWeakQtrap = 10e-6;
% tSpinFilter = x.*1e-3;
% s.addStep(@TransferLoad,IWeakQtrap,tWeakQtrap);
% s.wait(tSpinFilter);
%
% IQtrap=320.0;%[A}
% tQtrap=20.*1e-3;%[s] 100e-3
% s.addStep(@TransferLoad,IQtrap,tQtrap);
%
% s.wait(tFwdTrip - tTrackTrig - tWeakQtrap - tSpinFilter - tQtrap);

%% --------------Load from transfer coil into QUIC Quad-----------
s.addStep(@QUICLoad);
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time

%% --------------Backward cart transfer----------
s.addStep(@TrackTransfer,tTrackTrig);
% s.wait(4.5);
%% -----------Load into weak QUIC Quad and then back to strong-------
% s.addStep(@QUICLoad,2.75,0.0,100.*1e-3);
% s.wait(x); %Hold the atoms in the QUIC trap for some time
% s.addStep(@QUICLoad,20.0,0.0,100.*1e-3);
% s.wait(500e-3);
%% ------------Evap in QUIC Quad----------
% s.wait(500e-3);
s.addStep(@RFevap1);
s.wait(100e-3);

%% -----------Load into weak QUIC Quad and then back to strong-------
% s.addStep(@QUICLoad,x,0.0,100.*1e-3);
% s.wait(2); %Hold the atoms in the QUIC trap for some time
% s.addStep(@QUICLoad,20.0,0.0,100.*1e-3);
% s.wait(100e-3);

%% --------------Ramp on the Ioffe coil------------
s.addStep(@IoffeLoad);
% s.add('TTLscope',1); %trigger oscilloscope
s.wait(100e-3); %Hold the atoms in the QUIC trap for some time

% s.addStep(@QUICLoad,20.0,0.0,-1,500e-3);
% s.wait(100e-3);
%% --------------Evaporate inside the QUIC trap -------------
% s.add('TTLuwaveampl',0);    %u-wave amplifier enable
s.addStep(@RFevap2);
s.wait(500e-3); % 500e-3

%% --------------Variable hold----------
% tHold =10e-3;
% s.addStep(@preimaging);
% s.wait(tHold);
% s.add('TTLRbImagingShutter',0)...
%     .add('AmpRbOPZeemanAOM', 0.0);

%% --------------QUIC Trap kick 1--------------
% s.addStep(@QUICTrapOff,10e-6);
% s.wait(10e-6);
% s.addStep(@IoffeLoad,10e-6);
% s.wait(x.*1e-3);

%% --------------QUIC Trap kick 2--------------
% s.addStep(@QUICLoad,20,18.5,10e-6);
% s.wait(1e-3);
% s.addStep(@IoffeLoad,10e-6);
% s.wait(x.*1e-3);

%% -------------QUIC Trap Parametric Heating-----------
% tDrive = 1;
% AmpI = 0.7;
% Freq = x;
% s.addStep(@QUICParaHeat,tDrive,AmpI,Freq); % Apply sinusoidal drive for tDrive
% s.addStep(@IoffeLoad); % Restore the Ioffe configuration before TOF
% s.wait(500e-3);

%% -------------- Stern-Gerlach sequence --------------
% tSG = x.*1e-3; %Define the S-G kick duration
% s.addStep(@QUICLoad,20,0,0.1e-3);
% s.wait(tSG);

% %%--------------Temporary for testing u-wave-------
% VperA=1/0.54;%[V/A]Volt per amp
% IL2=3;  %[A] L2 is the large coil, IL2<=3A
% VL2=IL2*VperA;
% s.add('Vquant3',VL2);
% s.wait(20e-3);
% %%---------------------

%% --------------TOF imaging in evap chamber-----------
TOFRb = 10.*1e-3;% 15s; 10[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 5.*1e-3;%14s; 5[s]
m = MemoryMap;
m.Data(1).TOFRb=TOFRb;
m.Data(1).TOFK=TOFK;
% m.Data(1).flagCam=1;
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
s.addStep(@QuantFieldOn);   % turn on the imaging field at 15G, takes no time
s.wait(ShutterDelay);
% s.addStep(@Qtrapoff);      %turn off the transfer coil, takes 1 ms
s.addStep(@QUICTrapOff,1e-3);      %turn off the QUIC trap, takes 1 ms
s.add('TTLscope',1); %trigger oscilloscope
% s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
s.addStep(@imagingTOF, TOFRb, TOFK);%enable this for normal operation
% s.addStep(@imagingTOFuwave, TOFRb, TOFK);%temporary for testing u-wave

%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

s.run();
end