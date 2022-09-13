function s = mainODTtransfer(x)

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
tMOTUV = 2.0;       %[s] old value 2 s
s.wait(tMOTUV);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
tMOTHold = 6.0;
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
% s.addStep(@TrackTransfer,tTrackTrig);
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

% %%--------- Load in transfer ODT--------------
VODTtransf1 = 2.0;          %1.6W/V see 5/25/2018, was 1.5 V
s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT, 500e-3, VODTtransf1);%
trapID = 2;
%% -------Forward ODT transfer---------
Ratio4f = 2.4;
Pquic = 54.3 - 0.08;
PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
TransDist = 322.15;      % [mm] transfer distance of ODT
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
%
% %% ---------- Ramp large coil during transfer to maintain quanziation -------------
% Ifield1 = 0; %0.1
% Ifield2 = 0; %0.2
% VperA=1/0.54;   %[V/A]Volt per amp
% Vfield1 = Ifield1*VperA;
% Vfield2 = Ifield2*VperA;
% tBturn = 50/100*tODTFwdTrip;
%
% s.addStep(tBturn)...
%     .add('Vquant3', rampTo(Vfield1));
% s.wait(1e-6);
% s.addStep(tODTFwdTrip-tBturn)...
%     .add('Vquant3', rampTo(Vfield2));
% s.wait(1e-6);
s.wait(tODTFwdTrip);

%% ------------Load from transfer ODT to H static ODT---
VODT1 = 2.5*1.3; %ODT1 is H static ODT, (0.74 W/V, 6/25/2018)
tLoad = 250e-3;
s.addStep(@ODT2ODT, tLoad, VODT1);
trapID = 4;
% %%--- Trigger ABL back--------------
% s.addStep(@ABLTransfer);
%% -----Turn on quant field for ARPs--------%%%%%%%
if 0
    VperA = -1/1.2;
    Iquant = 4;%[A]
    Vquant = Iquant*VperA;
    s.addStep(200e-3)...
        .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
end
s.add('TTLscope',1);
% -----lowb ARP----------------
if 0
    s.add('TTLuwaveampl',1);   %
    s.add('TTLValon', 0);     %trigger Valon for preparing 3533.25MHz, 0 = lowB ARP, 1 = HighB ARP;
    s.wait(10e-3);
    fARP = 6888.7;                      %[MHz]6889
    s.addStep(@RbuwaveARP, fARP);       %Rb ARP between |22> and |11> for imaging
    Bkill = 2;                          %[G] B field for removing pulse
    VperA = -1/1.2;
    Ikill = 4/25.8*Bkill;%[A]
    Vkill = Ikill*VperA;
    s.addStep(5e-3)...
        .add('VctrlCoilServo6', rampTo(Vkill));        %large transfer quant field coil, -1V => 1.2A => 25.8G
    s.addStep(@Rbkill);                 %blasting beam takes 12.8 ms
    s.addStep(20e-3)...
        .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
    s.wait(5e-3);
    s.addStep(@KrfARP);
%     s.addStep(@RbuwaveARP, fARP);       %Rb ARP between |22> and |11> for imaging
end
s.add('TTLuwaveampl',0);
% %% ----Set ODT power in science chamber--------
% VODTtransf3 = 1.5;
% s.addStep(100e-3)...
%     .add('ODTtransf',rampTo(VODTtransf3));
% s.wait(100e-3);

% % ----evap in transfer ODT--------
% s.addStep(@ODTEvap,VODTtransf1);
% s.wait(500e-3);
% s.wait(x);

% % % %%-----lowB ARP--------
% Bkill = 2;        %[G]
% Ikill = Bkill./s.C.FeshbachGperA;
% s.add('TTLuwaveampl',1);
% s.wait(5e-3);
% s.addStep(@lowbARPs, ISciImgFld, Ikill, x);        %Rb lowB ARP + kill + K lowB ARP

% %%%==============================
% s.add('Frequwave', f1);
% s.addStep(4e-3)...
%     .add('Frequwave', rampTo(f2))...
%     .add('Ampuwave',0.4);
% s.wait(0.001e-3);
% s.add('Ampuwave',0);

% % % %% ----Parametric heating measurement----
% tDrive = 1; %time for heating drive [s]
% AmpV = 0.015; %Amplitude of heating drive [V]
% Freq = x; %Frequency of heating drive [Hz]
% s.addStep(@ODTParaHeat, 1.25, tDrive, AmpV, Freq);
% s.wait(1000e-3);

%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 30.0;     %[G] 19.84
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
s.addStep(tSciImgFld) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil))...
    .add('VctrlCoilServo6', rampTo(0.5));   %turn off bias field for lowb ARP 

s.wait(0.2);

% % %% --------------TOF imaging-----------
TOFRb = 3.0e-3;% TOFRb or TOFK needs to be bigger than texpcam200/2+tid=105.6us
TOFK = 1.5e-3;
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
Bstatus = 0;            %0 means low B (~30G), 1 means high B (~550G);
s.addStep(@preimaging, 42.4e6, 0, 51.4e6, 0, Bstatus); %for 30G (K at +9/2, 51.4e6);  Taken on 7/26/2018
% s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
% s.add('Vquant2',0);         %turn off the small transfer quant field coil
s.add('VctrlCoilServo6',0.5);         %turn off the large transfer quant field coil
% %-------------
s.addStep(@QUICTrapOff, 1e-3);      %turn off the QUIC trap, takes 1 ms
s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
%% ---------Turn off ODT---
s.add('ODTtransf',0);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT1',-1);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',-1);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);%enable this for normal operation

% Trigger ABL back
tODTRetTrip = tODTFwdTrip;
s.addStep(@ABLTransfer);
s.wait(tODTRetTrip);
s.wait(500e-3);

% % s.add('Vquant3',0);

s.add('TTLuwaveampl',0);
s.addStep(@fbCoilRampOn,0,10e-3);           %turn off Feshbach coill
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
    VODT1 = 0;op
end
m.Data(1).VODT1 = VODT1;
if ~exist('VODT2','var')
    VODT2 = 0;
end
m.Data(1).VODT2 = VODT2;
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