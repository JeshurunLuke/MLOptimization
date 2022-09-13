function s = mainQUIC(x)

s = ExpSeq();

%% -------Imaging shutter timing control-----
tImagingShtrOffDelay = 0e-3;
tImagingShtrOnDelay = 4e-3;
tImagingShtrSkip = 4e-3;
tImagingShtrMinOn = 4e-3;
% For more info see comments in TTLMgr
s.addOutputMgr('TTLImagingShutter', @TTLMgr, ...
    tImagingShtrOffDelay, ... % The time it takes to react to channel turning off 
    tImagingShtrOnDelay, ... % The time it takes to react to channel turning on 
    tImagingShtrSkip, ... % Minimum off time. Off interval shorter than this will be skipped.
    tImagingShtrMinOn); % Minimum on time. On time shorter than this will be extended
%% ------Default camera triggers----------
s.add('TTLscope',0);
VPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.add('TTLMOTCCD', 1);     % UV LED TTL, 0 - off, 1 - on
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
tMOTUV = 1.5;       %[s] old value 2 s
s.wait(tMOTUV);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
tMOTHold = 5.0;
s.wait(tMOTHold);
% s.add('TTLscope',1);

%% --------------Rb CMOT----------
tCMOT = 20e-3;%[s]was 50e-3 The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
if 1
    tMolas = 10e-3;%[s]The time duration of molasses
    s.addStep(@RbAndKGM,tMolas);%takes 20ms, for turning on Rb molasses only
%     s.addStep(@RbGM,tMolas);
else
    tMolas = 0.*20e-3;%[s]The time duration of molasses
    s.addStep(@Molasses,tMolas);%takes 20ms , include K D1 gray molasses
end

% tMolas=20e-3;%[s]The time duration of molasses
% tGM=6e-3;%[s]The time duration of molasses
% s.addStep(@Molasses,tMolas);%takes 20ms , include K D1 gray molasses
% s.addStep(@RbGM,tGM);%takes 20ms, for turning on Rb molasses only

    % s.addStep(@MolassesTest);%takes 20ms , include Rb D2 gray molasses
% s.addStep(@RbMolasses,tMolas);%takes 20ms, for turning on Rb molasses only

% s.addStep(5e-3)...
%     .add('VctrlCoilServo1', -1);


%% --------------Optical pumping (OP)----------
% tOP = x;%[s]should>(ShutterDelay+Delay)
tOP = 5e-3; %11/19/2019
s.addStep(@OP, tOP);%

%% --------------Loading atoms into the transfer coil---------
tQtrap = 10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);

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
% s.addStep(@QUICLoad);
% x = 1;
s.addStep(@QUICParallelLoad,20.0,0.0,500e-3);
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time

%% --------------Backward cart transfer----------
s.addStep(@TrackTransfer,tTrackTrig);
% s.wait(4.5);
%% -----------Load into weak QUIC Quad and then back to strong-------
% s.addStep(@QUICLoad,x,0.0,100.*1e-3);
% s.wait(500e-3); %Hold the atoms in the QUIC trap for some time
% s.addStep(@QUICLoad,20.0,0.0,100.*1e-3);
% s.wait(500e-3);
%% ------------Evap in QUIC Quad----------
% s.wait(500e-3);
s.addStep(@RFevap1);
% s.addStep(@uwaveEvap1);
% s.addStep(@HybridRFevap1);
s.wait(400e-3);
% s.wait(x);

%% -----------Load into weak QUIC Quad and then back to strong-------
% s.addStep(@QUICParallelLoad,3.0,0.0,100.*1e-3);
% s.wait(2); %Hold the atoms in the QUIC trap for some time
% s.addStep(@QUICParallelLoad,20.0,0.0,100.*1e-3);
% s.wait(100e-3);

%% --------------Ramp on the Ioffe coil------------
s.add('TTLscope',1);
s.addStep(@QUICParallelLoad,20,21.63,500e-3);%s.addStep(@QUICParallelLoad,20,21.63,500e-3)
% s.addStep(@QUICParallelLoad,20.23,21.86,500e-3);%s.addStep(@QUICParallelLoad,20,21.63,500e-3)
m = MemoryMap;
m.Data(1).trapID = 1;
% s.addStep(@QUICLoad);
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time
%% --------------Evaporate inside the QUIC trap -------------
s.addStep(@RFevap2);
% s.addStep(@uwaveEvap2);
% s.addStep(@uwaveEvap3);
s.wait(500e-3); % 500e-3
%% -------------- load into transfer ODT and back into QUIC ----------
% VODTtransf1 = 1.5;
% s.add('TTLscope',1);
% s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
% s.addStep(@QUIC2ODT,500e-3,VODTtransf1);%
% s.wait(500e-3);
% s.addStep(@ODT2QUIC,500e-3);%
% s.add('TTLODTtransf',0);

%% --------------- lower the bias field to compress the QUIC trap ------------------
% s.add('TTLscope',1); %trigger oscilloscope
% s.addStep(@QUICParallelLoad,20,20.83,500e-3);
% s.addStep(@QUICParallelParaHeat,20,20.83,1,0.025,x); %parametric heating for trapping fequency (IQuadCoil,IIoffeCoil,duration, amplitude, frequency)
% s.wait(500e-3);
% s.addStep(@QUICParallelLoad,20,21.63,500e-3);
% s.wait(500e-3);

%% --------------- Parametric heating in QUIC trap --------------------

% s.addStep(@QUICParallelParaHeat,1,0.025,x); %parametric heating for trapping fequency (duration, amplitude, frequency)

%% --------------TOF imaging in evap chamber-----------
TOFRb = 20.*1e-3;% 15 ms; 10[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 10.*1e-3;%14 ms; 5[s]
% m = MemoryMap;
m.Data(1).TOFRb=TOFRb;
m.Data(1).TOFK=TOFK;
% m.Data(1).flagCam=1;
Bstatus = 0;            %0 means low B (~30G), 1 means high B (~550G);
s.addStep(@preimaging, 27.48e6, 0*6.1e6, 33.4e6, 0.*6.1e6, Bstatus);  %27.0 MHz for 25 ms, 2uK cloud; 25.4MHz for 15ms, 26.05 MHz for 25 ms, 27.48*1e6 for 35ms, 0*6.1e6, 32e6, 0.*6.1e6); set up imaging frequency, open up imaging
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no timeshutter, takes no time
% s.addStep(@QuantFieldOn);   % turn on the imaging field at 15G, takes no time
% s.addStep(@Qtrapoff);      %turn off the transfer coil, takes 1 ms
s.addStep(@QUICTrapOff,1e-3);      %turn off the QUIC trap, takes 1 ms
s.wait(10e-6);
% s.add('TTLscope',1); %trigger oscilloscope
s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);%enable this for normal operation
% s.addStep(@imagingTOFuwave, TOFRb, TOFK);%temporary for testing u-wave
% s.add('Vquant1', 0);%turn off the imaging quantization field

% %% --------------Backward cart transfer----------
% s.addStep(@TrackTransfer,tTrackTrig);
% s.wait(2.5);
s.add('TTLuwaveampl',0);

%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
s.add('XLN3640VP',0.0);

% s.run();
end