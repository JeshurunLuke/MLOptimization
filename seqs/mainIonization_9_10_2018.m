function s = mainIonization_9_10_2018(x)

s = ExpSeq();

%% ------ Ioniation pulse timing control -----------
tIonUVShutterDelay = 40e-3;
tIonUVOffset = 85e-3;
tIonUVDelay = 40e-3;
if tIonUVDelay < 40e-3
    error('tUVDelay must be >= tUVShutterDelay!')
elseif tIonUVDelay > 10
    error('UV exposure too long!')
end
% s.wait(tIonUVOffset + (100e-3 - mod(tIonUVDelay - tIonUVShutterDelay, 100e-3)));  % choose this time to control the timing of the first UV pulse relative to molecule making time

numIonUVPulses = 1; % 0 ---> N pulses

if numIonUVPulses == 0
    tIonUVExp = 10e-3;
elseif numIonUVPulses < 0
    error('numIonUVPulses must be >= 0')
else
    tIonUVExp = (numIonUVPulses - 1).*100e-3 + 70e-3;         % [s] time the Rb cloud is exposed to the ionization laser
end

%% ------Default camera triggers----------
s.add('TTLscope',0);
VPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);
s.add('TTLKGMShutter',0);   %Close shutter

%%
% Turn Transfer ODT 60 MHz power ON
s.add('AmpTransfODTAOM2', 0.5);
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

% %%--------- Load in transfer ODT--------------
VODTtransf1 = 1.5;          %1.6W/V see 5/25/2018
s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT,500e-3,VODTtransf1);%
trapID = 2;
VODT = VODTtransf1;         %for memoryMap
s.wait(500e-3);
%% -------------Rb lowb ARP in evap chamber-------------
% s.add('TTLscope',1);
GperA = 15.83/4.8;                  %[G/A]
VperA = -1/0.54;                       %[V/A]Volt per amp
Imax = 5;                           %[A] max current
Iarp = 4.8;                         %[A] B=15.83 G @4.8A
Bkill = 2;                          %[G] B field for removing pulse
Ikill = Bkill/GperA;                %[A]
if Ikill > 5 || Iarp > 5
    error('Quant2 coil current need < 5 A!');
end
Varp = Iarp*VperA;
Vkill = Ikill*VperA;
s.addStep(10e-3)...
    .add('Vquant2', rampTo(Varp));
s.add('TTLuwaveampl',1);
s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
s.wait(5e-3);
fARP = 6868;            %6868[MHz]
s.addStep(@RbevapARP, fARP);     %Rb ARP between |22> and |11> for imaging
s.addStep(5e-3)...
    .add('Vquant2', rampTo(Vkill));
s.addStep(@Rbkill);             %blasting beam takes 12.8 ms
s.addStep(5e-3)...
    .add('Vquant2', rampTo(Varp));
s.wait(10e-3);                  %wait for B field settle down
% s.addStep(@RbevapARP, fARP);     %Rb ARP between |22> and |11> for imaging
s.addStep(@KrfARP);
Ifield = -0.25;%1.2 0.5; was at 0.75A [A] (calculated B/I=1.9G/A at evap chamb)
VperA=1/0.54;%[V/A]Volt per amp
Vfield = Ifield*VperA;
s.addStep(10e-3)...
    .add('Vquant2',0)...         %turn off the large transfer quant field coil
    .add('Vquant3', rampTo(Vfield));
s.add('TTLuwaveampl',0);
s.add('TTLValon', 1);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;

%% -------Forward ODT transfer---------
Ratio4f = 2.4;
Pquic = 55.0;
PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
TransDist = 324;      % [mm] transfer distance of ODT
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

% s.add('TTLscope',1);
%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 30.0;     %[G] 19.84
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
s.addStep(tSciImgFld) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil))...
    .add('Vquant3', rampTo(0));
s.wait(200e-3);

%% ------------Load from transfer ODT to H static ODT---
VODT1 = 2.5; %ODT1 is H static ODT, (0.74 W/V, 6/25/2018)
tLoad = 250e-3;

s.addStep(@ODT2ODT, tLoad, VODT1);
trapID = 4;
VODT = VODT1;
s.wait(0.2);

BFR1 = 550;        %[G]
tFR1 = 10e-3;     %[s]
IFR1 = BFR1./s.C.FeshbachGperAHB;     %use FeshbachGperAHB for high B
s.addStep(@fbCoilRampOn,IFR1,tFR1);
s.wait(200e-3);
%% ---turn on V static ODT and Evaporate-------
VODT2 = 2.5;     %2.5                     %ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
s.addStep(@ODT1Evap, VODT1, VODT2);
trapID = 5;
VODT = 0.15;
s.wait(0.5);
s.addStep(@KpreKill);
s.wait(20e-3);

%% ------Ramp down across Feshbach resonance---------------
BFR2 = 545.5;       %[G] 545.5
tFR2 = 3e-3;        % 3e-3 %[s]
IFR2 = BFR2./s.C.FeshbachGperAHB;
s.addStep(@fbCoilRampOn,IFR2,tFR2);

%% ------Ramp down kill field for kill unpaired Rb---------------
BFR21 = 544.1;        % [G] was at 544.5 G
tFR21 = 0.1e-3;     %0.1e-3 [s]
IFR21 = BFR21./s.C.FeshbachGperAHB;
s.addStep(@fbCoilRampOn,IFR21,tFR21);
s.wait(0.650e-3);
fARPKill = 8036.25*1e6; %8036.25 8037.75e6; %8037.50; 8036e6; for 2 ms; 8038.75 for 1 ms
dfKill = 1e6;
s.add('TTLscope',1);
s.addStep(@RbARPKill, fARPKill, dfKill, 0.5e-3);
s.wait(1e-6);
% s.wait(1); % for Rb atoms to thermalize after RbARPKill

%% -------- STIRAP roundtrip with 4 us wait ----------
% t_STIRAP = 35e-6;       %[s] 20us for roundtrip STIRAP; 35 us for one-way STIRAP
% AmpDDS690 = 0.385;         %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% s.add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690);
% s.add('TTLscope',1)...
%     .add('TTLSTIRAPTrig',1);
% s.wait(t_STIRAP);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0);
% s.add('TTLSTIRAPTrig',0);

%% -------- STIRAP roundtrip with controlled wait ----------
AmpDDS690 = 0;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
AmpDDSKKill = 0.3;        % DDS amplitude for K kill pulse after GS molecule step
% AmpDDS690 = 0;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% AmpDDS970 = 0;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% AmpDDSKKill = 0.0;

t_STIRAP_fwd = 20e-6; %[s]
t_STIRAP_bk = 15e-6; %[s]
t_STIRAP_wait = 40e-6; %[s]
t_STIRAP_wait_min = 39e-6; %[s]

if t_STIRAP_wait < t_STIRAP_wait_min
    error('t_STIRAP_wait needs to be >= t_STIRAP_wait_min')
end

s.add('AmpStirapAOM970', AmpDDS970)...
    .add('AmpStirapAOM690', AmpDDS690);
s.add('TTLscope',1)...
    .add('TTLSTIRAPTrig',1);
s.wait(t_STIRAP_fwd);
s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
    .add('AmpStirapAOM690', 0.0)...
    .add('AmpKOPRepumpAOM', AmpDDSKKill);
s.wait(t_STIRAP_bk);
s.add('TTLscope',0)...
    .add('TTLSTIRAPTrig',0);

s.wait(t_STIRAP_wait - t_STIRAP_wait_min + 1.5e-6);

s.add('TTLSTIRAPTrig',1);
s.wait(t_STIRAP_fwd);
s.add('AmpStirapAOM970', 0)...
    .add('AmpStirapAOM690', 0)...
    .add('AmpKOPRepumpAOM', 0.0)...
    .add('TTLKImagingShutter', 0);
s.wait(t_STIRAP_bk);
s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
    .add('AmpStirapAOM690', 0.0);
s.add('TTLSTIRAPTrig',0);

%% ------Ramp up for imaging-------------
BFR3 = 30;        %[G]
tFR3 = 5e-3;     %[s] 10e-6
IFR3 = BFR3./s.C.FeshbachGperA;
s.addStep(@fbCoilRampOn,IFR3,tFR3);
s.wait(200e-6);

% BFR3 = 550;        %[G]
% tFR3 = 0.1e-3;     %[s]
% IFR3 = BFR3./s.C.FeshbachGperAHB;
% s.addStep(@fbCoilRampOn,IFR3,tFR3);

%% ----- Ionization sequence-----------
% % % repRate = 10; % [Hz] Rep rate of the ionization laser
% tIonExpTot = 1;         % [s] was 15s, time the Rb cloud is exposed to the ionization laser
% tIonScopeTrigStart = 0.5; % [s] time the scope start triggering
% tScopeLogicOn = 101e-3; % [s] duration of the scope logic sigmal
%
% ionStart = s.curTime;
% % s.add('TTLscope',1)
% s.add('TTLIonLogic', 1);                 %
% s.add('TTLionShutter', 1);               % Open the shutter to allow UV light in
% % s.add('TTLHVswitch1', 1);
% s.wait(tIonScopeTrigStart);
% s.wait(tScopeLogicOn);
% s.wait(tIonExpTot - tIonScopeTrigStart - tScopeLogicOn);
% s.add('TTLionShutter',0);
% s.add('TTLIonLogic',0);
% ionEnd = s.curTime;

%% ----- Ionization sequence-----------
dt0 = 1e-6;
s.addStep(dt0)...
    .add('TTLIonLogic', 1); % tells the MCP to start looking
ionStart = s.curTime - dt0; % UV pulse on edge
s.wait(tIonUVExp);
s.add('TTLIonLogic',0);
ionEnd = s.curTime;

% s.addStep(tIonShutterDelay)...
s.add('TTLionShutter', 0);

%% --------------TOF imaging-----------
TOFRb = 1.0e-3;           % TOFRb or TOFK needs to be bigger than texpcam/2+tid = 251us
TOFK = 2.0e-3;            % abs(TOFK-TOFRb)<= texpcam/2+tid = 251us
ShutterDelay = 2.8e-3;  % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
Bstatus = 1;            %0 means low B (~30G), 1 means high B (~550G);
if Bstatus
    s.addStep(@preimaging, 770e6, 0e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
else
    s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
end
% s.wait(20e-3);
% s.add('Vquant3',0);         %turn off the large transfer quant field coil
% s.wait(ShutterDelay);

%% --------high B Rb ARP for imaging---------------
if Bstatus
    fARP = 8048.7;  %8048.7;                %[MHz] ARP center frequency
    s.addStep(@RbHighbARP, fARP);           % Rb ARP between |22> and |11>
else
    fARP = 6897.2; %6897.9;           %[MHz]
    s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11>
end

% s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);%enable this for in situ
% imaging
%% ---------Turn off ODT---
s.add('ODTtransf',0);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT1',0);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',0);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);       %enable this for normal operation

% Trigger ABL back
tODTRetTrip = tODTFwdTrip;
s.addStep(@ABLTransfer);
s.wait(tODTRetTrip);
s.wait(500e-3);

s.addStep(@fbCoilRampOn, 0, 10e-3);           %turn off Feshbach coill
s.add('TTLuwaveampl',0);
s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;

%%---------set memory map----------------------
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
m.Data(1).trapID = trapID;
m.Data(1).VODT = VODT;
%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);


s.add('TTLscanDyeFreq',0);       %auto trigger the dye laser to jump frequency, TTL low means trigger
%% ------------Generate a background 10Hz TTL ----------------
s.waitAll();
tIonUVOffset = mod(ionStart, 100e-3);  % choose this time to set UV pulse on edge at ionStart
% Make sure we don't start this before time 0.
seqlen = s.totalTime() - tIonUVOffset - 0.1;     %was s.totalTime() - 0.1;
    function background10Hz(s, len)
        period = 0.1; %0.1
        onTime = 0.010;
        while s.totalTime() < len
            cycleStart = s.totalTime();
            % Open Ionization shutter
            if (cycleStart >= ionStart-tIonShutterDelay) && (cycleStart < ionStart)
                s.addBackground();
                s.addStep(tIonShutterDelay)...
                    .add('TTLionShutter', 1);
            end
            % Add anything that is to be synced with the ionization pulses
            if cycleStart > ionStart && cycleStart < ionEnd
                s.addBackground(@IonSyncProc); %% Shorter than 100ms
            end
            % Close Ionization shutter
            if (cycleStart >= ionEnd)
                s.addStep(tIonShutterDelay)...
                    .add('TTLionShutter', 0);
            end
            s.addStep(onTime) ...
                .add('TTLbkgd', 1);
            s.addStep(period - onTime) ...
                .add('TTLbkgd', 0);
        end
    end
s.addBackground(-seqlen, @background10Hz, seqlen);

end
