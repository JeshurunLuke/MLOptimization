function s = mainODTload(x)

s = ExpSeq();

m = MemoryMap;
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
s.add('TTLKGMShutter',0);   %Close shutter

%% Set transfer ODT AOM power and frequency
% Turn Transfer ODT 90 MHz power ON
s.add('AmpTransfODTAOM', 0.6);
s.add('FreqTransfODTAOM',89.458e6);
% Turn Transfer ODT 60 MHz power ON
s.add('AmpTransfODTAOM2', 0.5);
s.add('FreqTransfODTAOM2',60e6);
% Keep Transfer ODT switch off before calling on it
s.add('TTLODTtransf',0);

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

%% --------------Rb CMOT----------
tCMOT=20e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT

%% --------------Rb Molasses + K Grey Molasses----------
if 1
    tMolas = 10e-3;%[s]The time duration of molasses
    s.addStep(@RbAndKGM,tMolas);%takes 20ms, for turning on Rb molasses only
else
    tMolas = 20e-3;%[s]The time duration of molasses
    s.addStep(@Molasses,tMolas);%takes 20ms , include K D1 gray molasses
    % s.addStep(@RbMolasses,tMolas);%takes 20ms, for turning on Rb molasses only
end

%% --------------Optical pumping (OP)----------
tOP=6e-3;%[s]should>(ShutterDelay+Delay)
s.addStep(@OP,tOP);%

%% --------------Loading atoms into the transfer coil---------
tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
s.addStep(@Qtrap,tQtrap);

%% --------------Forward cart transfer----------
tTrackTrig = 1e-3; % min value 1 ms
tFwdTrip = 3409e-3; %updated from 3412e-3 on 05/14/2017; [s]1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
s.addStep(@TrackTransfer,tFwdTrip);

%% --------------Load from transfer coil into QUIC Quad-----------
s.addStep(@QUICParallelLoad,20.0,0.0,500e-3);
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time

%% --------------Backward cart transfer----------
s.addStep(@TrackTransfer,tTrackTrig);

%% ------------Evap in QUIC Quad----------
s.addStep(@RFevap1);
% s.addStep(@uwaveEvap1);
s.wait(400e-3);

%% --------------Ramp on the Ioffe coil------------
s.addStep(@QUICParallelLoad,20.000,21.630,500e-3);%
trapID = 1;

s.wait(500e-3); %Hold the atoms in the QUIC trap for some time

%% --------------Evaporate inside the QUIC trap -------------
s.addStep(@RFevap2);
% s.addStep(@uwaveEvap3);
s.wait(500e-3); % 500e-319

%% --------- Load transfer ODT--------------
VODTtransf1 = 2.0;
s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
s.add('TTLscope',1);
s.addStep(@QUIC2ODT,500e-3,VODTtransf1);%
% s.addStep(200e-3) ...
%     .add('ODTtransf', rampTo(VODTtransf1));  %See table on 3 Mar 2018 for conversion details; this should give about 5 W
% s.wait(x.*1e-3);
% s.addStep(@QUICTrapOff, 150e-3);      %turn off the QUIC trap and turn on AG coil for quantization, takes 1 ms
% s.wait(25e-3);
% s.addStep(@QUICTrapOff1, x.*1e-3);      %turn off the QUIC trap and turn on AG coil for quantization
% s.addStep(100e-3)...
%     .add('ODT1',rampTo(2));
s.wait(500e-3);
trapID = 2;


%% ----Parametric heating measurement----
% tDrive = 5; %time for heating drive [s]
% AmpV = x; %Amplitude of heating drive [V]
% Freq = 965; %Frequency of heating drive [Hz]
% s.addStep(@ODTParaHeat, VODTtransf1, tDrive, AmpV, Freq);
% s.wait(500e-3);

%% ----evap in transfer ODT--------
% s.addStep(@ODTEvap, VODTtransf1);
% s.wait(500e-3);
% s.wait(x);

%% ---- Ramp off large quant coil and ramp on imaging coil --------
% Ifield1 = -4.8/10;%[A] B=2.2 G; -4.8/10
% VperA1=1/0.54;%[V/A]Volt per amp
% Vfield1 = Ifield1*VperA1;
% s.addStep(150e-3)...
%     .add('Vquant3', rampTo(0));
% s.wait(100e-3);

% % %% -------------Rb ARP-------------
% s.add('TTLscope',1);
% GperA = 15.83/4.8;                  %[G/A]
% VperA = -1/0.54;                       %[V/A]Volt per amp
% Imax = 5;                           %[A] max current
% Iarp = 4.8;                         %[A] B=15.83 G @4.8A
% Bkill = 2;                          %[G] B field for removing pulse
% Ikill = Bkill/GperA;                %[A]
% if Ikill > 5 || Iarp > 5
%     error('Quant2 coil current need < 5 A!');
% end
% Varp = Iarp*VperA;
% Vkill = Ikill*VperA;
% s.addStep(10e-3)...
%     .add('Vquant2', rampTo(Varp));
% s.add('TTLuwaveampl',1);
% s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
% s.wait(5e-3);
% fARP = 6868;            %6868[MHz]
% s.addStep(@RbevapARP, fARP);     %Rb ARP between |22> and |11> for imaging
% s.addStep(5e-3)...
%     .add('Vquant2', rampTo(Vkill));
% s.addStep(@Rbkill);             %blasting beam takes 12.8 ms
% s.addStep(5e-3)...
%     .add('Vquant2', rampTo(Varp));
% s.wait(10e-3);                  %wait for B field settle down
% s.addStep(@KrfARP);
% s.addStep(@RbevapARP, fARP);     %Rb ARP between |22> and |11> for imaging
% s.add('Vquant2',0);         %turn off the side imaging coil

%% --------------TOF imaging in evap chamber-----------
TOFRb = 5.0e-3;       % TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 1.5e-3;%
Bstatus = 0;            %0 means low B (~30G), 1 means high B (~550G);
s.addStep(@preimaging, 25.33e6, 0, 34.7e6, 0, Bstatus);          %K +9/2 imaging freq taken on 5/4/2018
% s.addStep(@preimaging, 25.33e6, 0, -15.8e6, 0, Bstatus); %for 15.8G (K at -9/2);  Taken on 7/31/2018

% For TOFRb = 10 ms, use 25.33 MHz; for For TOFRb = 6 ms, use 26.03 MHz;
% For TOFK = 6 ms, use 34.7 MHz
% s.add('Vquant2',0);         %turn off the small transfer quant field coil
% s.add('Vquant3',0);         %turn off the large transfer quant field coil
s.addStep(@QuantFieldOn);
% s.addStep(@Qtrapoff);      %turn off the transfer coil, takes 1 ms

% % %-------------
% s.addStep(@QUICTrapOff, 1e-3);      %turn off the QUIC trap, takes 1 ms
% s.addStep(@QuantFieldOn);
% s.add('TTLuwaveampl',0);

% ---------Turn off ODT---
s.add('ODT1',-1);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODTtransf',-1);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on

s.addStep(@imagingTOF, TOFRb, TOFK);%enable this for normal operation
%%---------set memory map----------------------
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
m.Data(1).trapID = trapID;
if ~exist('VODTtransf1','var')
    VODTtransf1 = 0;
end
%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);
% s.add('TTLKGMShutter',1);   %Open shutter
s.run();
end