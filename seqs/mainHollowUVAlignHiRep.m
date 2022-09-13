function s = mainHollowUVAlignHiRep(x)

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
%% ------ STIARAP shutter timing control -----------
tSTIRAPShtrOffDelay = 0e-3;
tSTIRAPShtrOnDelay = 4e-3;
tSTIRAPShtrSkip = 4e-3;
tSTIRAPShtrMinOn = 4e-3;
% For more info see comments in TTLMgr
s.addOutputMgr('TTLSTIRAPShutter', @TTLMgr, ...
    tSTIRAPShtrOffDelay, ... % The time it takes to react to channel turning off 
    tSTIRAPShtrOnDelay, ... % The time it takes to react to channel turning on 
    tSTIRAPShtrSkip, ... % Minimum off time. Off interval shorter than this will be skipped.
    tSTIRAPShtrMinOn); % Minimum on time. On time shorter than this will be extended
%% ------ Ionization pulse timing control -----------
% using Thorlabs SH2
% tUVShtrOffDelay = 0.0e-3;
% tUVShtrOnDelay = 13.0e-3; %was 40e-3
% tUVShtrSkip = 40e-3;
% tUVShtrMinOn = 40e-3;
% using SRS475
tUVShtrOffDelay = 4e-3;
tUVShtrOnDelay = 4e-3; %was 40e-3
tUVShtrSkip = 4e-3;
tUVShtrMinOn = 4e-3;
% For more info see comments in TTLMgr
s.addOutputMgr('TTLionShutter', @TTLMgr, ...
    tUVShtrOffDelay, ... % The time it takes to react to channel turning off 
    tUVShtrOnDelay, ... % The time it takes to react to channel turning on 
    tUVShtrSkip, ... % Minimum off time. Off interval shorter than this will be skipped.
    tUVShtrMinOn); % Minimum on time. On time shorter than this will be extended
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
s.addStep(1e-3)... % Turn off K MOT for this purpose
    .add('AmpKMOTAOM', 0.0); % 0.2175 0.400, 0.27, 0.15
tMOTUV = 1.5;       %[s] old value 2 s
s.wait(tMOTUV);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
tMOTHold = 1.0;
s.wait(tMOTHold);
%% --------------Rb CMOT----------
tCMOT=20e-3;%[s]The time duration of CMOT
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT
%% --------------Rb Molasses + K Grey Molasses----------
if 1 %use Rb GM + K GM
    tMolas = 10e-3;%[s]The time duration of molasses
    s.addStep(@RbAndKGM,tMolas);%takes 20ms, for turning on Rb molasses only
else %use Rb BM + K GM
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
s.wait(500e-3); % 500e-3
%%--------- Load in transfer ODT--------------
VODTtransf1 = 2.0;          %1.6W/V see 5/25/2018
s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT,500e-3,VODTtransf1);%
trapID = 2;
%% -------Forward ODT transfer---------
Ratio4f = 2.4;
Pquic = 54.3 - 0.08;
PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
TransDist = 322.15;    % [mm] transfer distance of ODT
PScienceOffset = TransDist/Ratio4f; %316.4/2.727;
Vel1 = 350;           %velocity for stage 1
Vel2 = 200;         %velocity for stage 2, inactive if stageNum = 1
ARate = 800;        %700 [mm/s^2]
DRate = ARate;        %500 [mm/s^2]
stageNum = 1; % If stageNum > 1, put in PIntOffset;
ABLTrajPlotFlag = 0;    %0 mean not plot, 1 means plot
tODTFwdTrip = ABLTripTime(Ratio4f,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
disp(['tODTFwdTrip = ', num2str(tODTFwdTrip), ' s']);
% Trigger ABL forward
s.addStep(@ABLTransfer);
trapID = 3;
s.wait(tODTFwdTrip);
%% ------------Load from transfer ODT to H static ODT---
VODT1 = 2.5*1.3;    %ODT1 is H static ODT, (0.74 W/V, 6/25/2018)
tLoad = 250e-3;
s.addStep(@ODT2ODT, tLoad, VODT1);
trapID = 4;
%%--- Trigger ABL back--------------
s.addStep(@ABLTransfer);
%%%%-----Turn on quant field for ARPs--------%%%%%%%
VperA = -1/1.2;
Iquant = 4;%[A]
Vquant = Iquant*VperA;
s.addStep(100e-3)...
    .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G

s.add('TTLscope',1)
%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 30.0;     %[G] 19.84
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
s.addStep(tSciImgFld) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil))...
    .add('VctrlCoilServo6', rampTo(0.5));   %turn off bias field for lowb ARP 
s.wait(10e-3);

%% ---turn on V static ODT (for 300 nm UV alignment)-------
s.add('TTLscope',1);
VODT2 = 3.5;     %0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
s.add('TTLODT2',1);
s.addStep(100e-3)...
    .add('ODT1', rampTo(2.0))... 
    .add('ODT2', rampTo(VODT2));
s.wait(100e-3);
% trapID = 5;
% VODT1 = 0.125;

%% ---turn on V static ODT and evaporate (for 296 nm UV alignment)-------
% s.add('TTLscope',1);
% VODT2 = 0.818;     %0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
% s.addStep(@ODT1Evap, VODT1, VODT2);
% trapID = 5;
% VODT1 = 0.125;
% s.wait(0.5);
% s.addStep(@KpreKill);
% s.wait(20e-3);

%% ------Ramp down B field for ionization------------
BFR3 = 30;        %[G]
tFR3 = 10e-6;     %[s] 10e-6
IFR3 = BFR3./s.C.FeshbachGperA;
s.addStep(@fbCoilRampOn,IFR3,tFR3);
s.wait(10e-3);

%% ----- Ionization sequence-----------
s.add('TTLHVswitch1', 1);%turn on electrodes for settling down
s.wait(25e-3); %Extra wait between STIRAP and first UV pulse; the actual wait is 15.4 ms + this number

s.add('TTLscope', 1);
%% ----- Ionization sequence-----------
tIonUVExp = 15; % [s]  Please also change "edgeWaveBurst.m" correspondently.
if tIonUVExp == 0
    s.add('TTLionShutter', 0);
else
    s.addStep(tIonUVExp)...
        .add('TTLionShutter', 1)...
        .add('TTLbkgd', 1);           %trigger Agilent func gen.
end
s.wait(1e-6);

s.add('TTLionShutter', 0);
s.add('TTLbkgd', 0);
s.add('TTLHVswitch1', 0);

%% --------------TOF imaging-----------
TOFRb = 7.0e-3;           % TOFRb or TOFK needs to be bigger than texpcam/2+tid = 251us
TOFK = 5.0e-3;            % abs(TOFK-TOFRb)<= texpcam/2+tid = 251us
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
Bstatus = 0;            %0 means low B (~30G), 1 means high B (~550G);
if Bstatus
    s.addStep(@preimaging, 770e6, 0e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
else
    s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
end
%% ---------Turn off ODT---
s.add('ODTtransf',-1);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT1',0);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',0);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);       %enable this for normal operation

s.add('VctrlCoilServo6',0.5);         %turn off  quant field coil
s.add('VctrlCoilServo5',0.5);         %turn off  fastB field coil
s.addStep(@fbCoilRampOn, 0, 10e-3);           %turn off Feshbach coill
s.add('TTLuwaveampl',0);
s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
s.add('TTLionShutter', 0);
%%---------set memory map----------------------
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
m.Data(1).trapID = trapID;

if ~exist('VODTtransf1','var')
    VODTtransf1 = 0;
end
m.Data(1).VODTtransf1 = VODTtransf1;
if ~exist('VODT1','var')
    VODT1 = 0;
end
m.Data(1).VODT1 = VODT1;
if ~exist('VODT2','var')
    VODT2 = 0;
end
m.Data(1).VODT2 = VODT2;
%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);

%% -------------Turn things off at the end of a script-----------
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

end
