function s = mainHighB(x)

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
%% ------ STIRAP shutter timing control -----------
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
s.add('TTLHVswitch1', 0);   %Turn HV switch low for E=0

%% Set transfer ODT AOM power and frequency
% Turn Transfer ODT 90 MHz power ON
s.add('AmpTransfODTAOM', 0.6);
s.add('FreqTransfODTAOM',89.458e6);
% Turn Transfer ODT 60 MHz power ON
s.add('AmpTransfODTAOM2', 0.5);
s.add('FreqTransfODTAOM2',60e6);
% Keep Transfer ODT switch off before calling on it
s.add('TTLODTtransf',0);

s.add('TTL2GHzRF',1);
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
tCMOT=20e-3;%[s]The time duration of CMOT 20e-3
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT
%% --------------Rb Molasses + K Grey Molasses----------
if 1 %use Rb GM + K GM
    tMolas = 10e-3;%[s]The time duration of molasses 10e-3
    s.addStep(@RbAndKGM,tMolas);
%     s.addStep(@RbGM,tMolas);
else %use Rb BM + K GM
%     tMolas = 10e-3;%[s]The time duration of molasses
%     s.addStep(@RbAndKGM,tMolas);
    tMolas = 20e-3;%[s]The time duration of molasses
    s.addStep(@Molasses,tMolas);%takes 20ms , include K D1 gray molasses
%     s.addStep(@RbMolasses,tMolas);%takes 20ms, for turning on Rb molasses only
end
%% --------------Optical pumping (OP)----------
tOP=5e-3;%[s]should>(ShutterDelay+Delay)
%Was tOP = 6e-3 on 3/1/2020
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
s.wait(10e-3);
% %%--------- Load in transfer ODT--------------
VODTtransf1 = 2.0;               %1.6W/V see 5/25/2018
%VODTtransf1 = 2.0 01/07/2020
s.add('TTLODTtransf',1);        %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT, 500e-3, VODTtransf1); %OPTIMIZE
trapID = 2;
%% -------Forward ODT transfer---------
Ratio4f = 2.4;
Pquic = 54.3 - 0.08;
PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
TransDist = 322.15;      % [mm] transfer distance of ODT 322.15
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
if 1
VODT1 = 2.5*1.3;    %ODT1 is H static ODT, (0.64W/V, 11/18/2019)(0.68 W/V, 6/25/2018) (0.74 W/V, 6/25/2018)
%VODT1 = 2.5*1.3; 01/07/2020
tLoad = 250e-3;
%s.add('TTLscope',1);
s.addStep(@ODT2ODT, tLoad, VODT1);
trapID = 4;
end
%%--- Trigger ABL back--------------
s.addStep(@ABLTransfer);
%%%%-----Turn on quant field for ARPs--------%%%%%%%
if 1
    VperA = -1/1.2;
    Iquant = 4;%[A]
    Vquant = Iquant*VperA;
    s.addStep(200e-3)... % was 100e-3, changed to 200e-3 on 02/23/2020
        .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
end
%% -----lowb ARP----------------
if 1
    s.add('TTLuwaveampl',1);   %
    s.add('TTLValon', 0);     %trigger Valon for preparing 3533.25MHz, 0 = lowB ARP, 1 = HighB ARP;
    s.wait(10e-3);
    fARP = 6888.7;           %[MHz]6889
    s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11> for imaging
    Bkill = 2;                          %[G] B field for removing pulse
    VperA = -1/1.2;
    Ikill = 4/25.8*Bkill;%[A]
    Vkill = Ikill*VperA;
    s.addStep(5e-3)...
        .add('VctrlCoilServo6', rampTo(Vkill));        %large transfer quant field coil, -1V => 1.2A => 25.8G
    s.addStep(@Rbkill);             %blasting beam takes 12.8 ms
    s.addStep(20e-3)...
        .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
    s.wait(5e-3);
    s.addStep(@KrfARP);
    %s.add('TTLscope',1);
    % s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11> for imaging
end
s.add('TTLValon', 1);     %trigger Valon for preparing 4120MHz, 0 = lowB ARP, 1 = HighB ARP;
% s.wait(500e-3);
%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 30.0;     %[G] 19.84
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
%tSciImgFld = 10e-3 on 3/1/2020; 
VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
s.addStep(tSciImgFld) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil))...
    .add('VctrlCoilServo6', rampTo(0.5));   %turn off bias field for lowb ARP 
s.wait(10e-3);
%% ----Ramp to high B-----------------------
if 1
    fprintf('Turning On: %f\n', s.curTime);
BFR1 = 550;        %[G]
tFR1 = 10e-3;     %[s]
IFR1 = BFR1./s.C.FeshbachGperAHB;     %use FeshbachGperAHB for high B
s.addStep(@fbCoilRampOn,IFR1,tFR1);
s.wait(100e-3);
s.add('TTL2GHzRF',0); %trigger Keithley multimeter to monitor FB coil current
%s.add('TTLscope',1);
s.wait(100e-3);
end

%% ---turn on V static ODT at high power but no evaporation (for alignmnet) -------
if 0
s.add('TTLscope',1);
VODT2 = 3.5;     %0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
s.add('TTLODT2',1);
s.addStep(100e-3)...
    .add('ODT1', rampTo(2.0))... 
    .add('ODT2', rampTo(VODT2));
s.wait(100e-3);
% trapID = 5;
% VODT1 = 0.125;
end

%% ---turn on V static ODT and Evaporate-------
if 1
    s.add('TTLscope',1);
    VODT2 = 0.4;     %0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
    s.addStep(@ODT1Evap, VODT1, VODT2);
    trapID = 5;
    VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);    %This is only important for calculating right Temperature
    %s.wait(0.5);
    s.addStep(@KpreKill);
    s.wait(20e-3);
%     s.wait(x);
%         s.add('TTLscope',1);
end

%% ---------Feshbach ramp---------------
if 1    %1 means enable Feshbach ramp, 0 means disable
    Bcorrection = 1.48;%1.5;  %1.2 3/12/2019, 1.5
    %% ------Ramp down across Feshbach resonance---------------
    BFR2 = 545.5-Bcorrection;       %[G] 545.5
    SperG2 = 250e-6;      %Inverse ramp rate [s/G], 250 us/G
    % Use fast B coil for ramp
    BFB2 = BFR1 - BFR2;
    tFR2 = (BFR1-BFR2)*SperG2;        % 3e-3 %[s]
    IFB2 = BFB2./s.C.FastBCoilGperA;
%     s.add('TTLscope',1);
    s.addStep(@fastBCoilRampOn,IFB2,tFR2);
    %% ------Ramp down kill field for kill unpaired Rb---------------
    BFR21 = 544.1-Bcorrection;        % [G] was at 544.5 G
    tFR21 = 0.1e-3;     %0.1e-3 [s]
    % Use fast B coil for ramp
    BFB21 = BFR1 - BFR21;
    IFB21 = BFB21./s.C.FastBCoilGperA;
    s.addStep(@fastBCoilRampOn,IFB21,tFR21);
    s.wait(0.2e-3); %0.2e-3
    fARPKill = (8038.4)*1e6;%8037.1e6;  8036e6; for 2 ms; 8038.75 for 1 ms
    dfKill = 1.0e6;
    s.addStep(@RbARPKill, fARPKill, dfKill, 0.75e-3);     %
    s.wait(1e-6);
end
% 
% ----- Pulse on 970 nm light ----------
% t_970_pulse = 10*1e-6; %[s]
% s.add('TTLscope',1);
% s.addStep(t_970_pulse)...
%     .add('TTLSTIRAPShutter', 1)...
%     .add('AmpStirapAOM970', 0.050*1.5)...
%     .add('AmpStirapAOM690', 0.3*0)...
%     .add('FreqStirapAOM690', 79.4e6);
% s.add('AmpStirapAOM970', 0.0)...
%     .add('AmpStirapAOM690', 0.0)...
%     .add('TTLSTIRAPShutter', 0);

% % % % -------- STIRAP roundtrip with 4 us wait ----------
% % % t_STIRAP = 35e-6;       %[s] 20us for roundtrip STIRAP; 35 us for one-way STIRAP
% % % AmpDDS690 = 0.385;         %0.3x1.2833=0.385 [V] max power of 690nm
% laser, 4.45 mWm
% % % AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % % s.add('AmpStirapAOM970', AmpDDS970)...
% % %     .add('AmpStirapAOM690', AmpDDS690);
% % % s.add('TTLscope',1)...
% % %     .add('TTLSTIRAPTrig',1);
% % % s.wait(t_STIRAP);
% % % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% % %     .add('AmpStirapAOM690', 0.0);
% % % s.add('TTLSTIRAPTrig',0);

%% -------- STIRAP roundtrip with controlled wait ----------
if 1    % 1- enable STIRAP, 0- disable
    AmpDDS970 = 0.475;      % 0.475; 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
    AmpDDS690 = 0.300;        %0.300; 0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
    AmpDDSKKill = 0.300;        % DDS amplitude for K kill pulse after GS molecule step
    
    FreqDDS970_1 = 80.0e6;
    FreqDDS690_1 = 80.0e6;
%         FreqDDS970_2 = 80.0e6;
    FreqDDS690_2 = 79.14e6;    %79.2e6;
    
    dtSTIRAPramp = 4e-6;
    t_STIRAP_fwd = 7e-6 + dtSTIRAPramp; %[s]
    t_STIRAP_GS = 8e-6;%[s]
    t_STIRAP_bk = t_STIRAP_fwd; %[s]
    t_STIRAP_wait = 10e-3;%10e-3; %[s] wait time between FW and BK STIRAP
%     t_STIRAP_wait = 10e-3+100*1e-3;%10e-3; %[s] wait time between FW and BK STIRAP
    t_kill = 5e-3;
    %%-----------Forward STIRAP-----------
    s.add('FreqStirapAOM970', FreqDDS970_1)...
        .add('FreqStirapAOM690', FreqDDS690_1);
    s.add('TTLSTIRAPTrig',1)...
        .add('TTLSTIRAPShutter', 1);
    s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
        .add('AmpStirapAOM970', AmpDDS970)...
        .add('AmpStirapAOM690', AmpDDS690);
    s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
        .add('AmpStirapAOM690', 0.0)...
        .add('TTLSTIRAPTrig',0)...
        .add('TTLSTIRAPShutter',0);
    %%---------removing pulse---------------
    fARPKill = (8033.25)*1e6;%8037.1e6; %8036.00 8036.25 8037.75e6; %8037.50; 8036e6; for 2 ms; 8038.75 for 1 ms
    dfKill = 3.0e6;
    s.addStep(@kill, fARPKill, dfKill, t_kill);
        
    %% ------drive to |N = 1, mN> state-----
%     if 0
%         s.wait(25e-3);  %add 25ms for B field settling
% %         s.add('TTLODT1',0)...
% %             .add('TTLODT2',0);
% %         s.wait(5e-6);
%         dt = 29e-6;     %104e-6;     %41e-6; pi for |1,1> %29e-6 pi for |1,-1> 
%         s.addStep(dt)...
%             .add('TTL2GHzRF', 1)...
%             .add('TTLscope',1);
%         s.add('TTL2GHzRF',0);
%         %         if 1
%         %             s.add('TTLHVswitch1', 1);
%         %             s.wait(1e-6);
%         %             s.add('TTLODT1',0)...
%         %                 .add('TTLODT2',0);
%         %         end
%         %         s.wait(143e-6);
%     end
%     
    %%%%
%     s.add('TTLscope',1);
    if 0
        %% ------Ramp fastB off -------------
        BFR3 = 550;        %[G] 550
        tFR3 = 0.1e-3;     %[s]
        BFB3 = BFR1 - BFR3;        %[G]
        IFB3 = BFB3./s.C.FastBCoilGperA;
        s.addStep(@fastBCoilRampOn,IFB3,tFR3);
        s.add('TTLHVswitch1', 1);
        
        %% ------Ramp down B field------------
        BFR3 = 30;        %[G]  5
        tFR3 = 10e-6;     %[s]  10e-6
        IFR3 = BFR3./s.C.FeshbachGperA;
        s.addStep(@fbCoilRampOn,IFR3,tFR3);
        s.wait(50e-3);
        
        %%%%------drive N=1-------
        dt = 81e-6;     %104e-6; 68e-6; 34e-6   %41e-6; pi for |1,1> %29e-6 pi for |1,-1>
        s.add('TTLODT1', 0)...
            .add('TTLODT2', 0);
        s.add('TTLscope',1);
        s.wait(5e-6);
        s.addStep(dt)...
            .add('TTL2GHzRF', 1);
        s.add('TTL2GHzRF',0);
        s.wait(1e-6);
%         s.add('TTLscope',1);
        s.add('TTLODT1',1)...
            .add('TTLODT2',1);      
%         s.wait(x*1e-3);
%         s.add('TTLODT1',0)...
%             .add('TTLODT2',0);
%         s.wait(1e-6); 
%         s.addStep(dt)...
%             .add('TTL2GHzRF', 1);
%         s.add('TTL2GHzRF',0);         
%         s.add('TTLODT1',1)...
%             .add('TTLODT2',1);

        s.add('TTLHVswitch1', 0);       
        %% ------Ramp up B field for backward STIRAP------------
        s.addStep(@fastBCoilRampOn,IFB21,tFR21);    %Ramp fastB on
        s.addStep(@fbCoilRampOn,IFR1,tFR1);         %Ramp FB coil on
        s.wait(65e-3);
    end
    
    
    % %% ------drive N = 1 backward-----
    % if 0
%     %         s.add('TTLODT1',1)...
%     %             .add('TTLODT2',1)...
%     %             .add('TTLHVswitch1', 0);
%     s.wait(1e-6);
%     dt = 15e-6;     %104e-6;     %41e-6;0.2e-3;
%     s.addStep(dt)...
%         .add('TTL2GHzRF', 1);
%     s.add('TTL2GHzRF',0);
%     %         s.wait(x*1e-6);
% %     s.wait(x*1e-6);
%     dt = 15e-6;     %104e-6;     %41e-6;0.2e-3;
%     s.addStep(dt)...
%         .add('TTL2GHzRF', 1);
%     s.add('TTL2GHzRF',0);
% end
    
    
    
%     if 0        %for achieve hotter temp
%         VODT1 = 0.115.*2.*1.3;
%         VODT2 = 0.818;
%         dtRamp = 30e-3;
%         tHold = 0.1;
%         s.addStep(dtRamp)...
%             .add('ODT1', rampTo(VODT1*0.52))...
%             .add('ODT2', rampTo(VODT2*0.52));
%         s.wait(tHold);
%         s.addStep(dtRamp)...
%             .add('ODT1', rampTo(VODT1))...
%             .add('ODT2', rampTo(VODT2));
%     end
    
    %%-----------hold at GS KRb-------------
    s.wait(t_STIRAP_wait+1e-6);
    %%-----------Test ODT off effect---------
%     s.addStep(t_STIRAP_wait)...
%         .add('TTLbkgd',x);
%     s.add('TTLbkgd',0)
    %%%------add UV pulse sequence--------
%     if 0
%         tIonUVExp = 100e-3; % [s]  Please also change "edgeWaveBurst.m" correspondently.
%         s.addStep(tIonUVExp)...
%             .add('TTLHVswitch1', 1)...
%             .add('TTLionShutter', 1);
%         s.add('TTLionShutter', 0);
%         s.add('TTLHVswitch1', 0);
%         
%         %         tIonUVExp = 0.5;    % [s]  Please also change "edgeWaveBurst.m" correspondently.
%         %         if 0
%         %             s.addStep(@UVexposure, tIonUVExp);
%         %         else
%         %             s.wait(tIonUVExp);
%         %         end
%     end
%      s.wait(x);
    if 0
        VODT1 = 0.119.*1.3;
        VODT2 = 0.400; % 0.818; make sure this matches what's currently used in the experiment
%         dtRamp = 30e-3;
%         s.addStep(dtRamp)...
%             .add('ODT1', rampTo(VODT1))...
%             .add('ODT2', rampTo(VODT2));
        
        tIonUVExp = x; % x [s]  Please also change "edgeWaveBurst.m" correspondently.
%         f = (1/3000)/(1/3000 - 4e-6);
        f = 2;
        %f = 2;
        if tIonUVExp == 0
            s.add('TTLionShutter', 0);
        else
            s.addStep(tIonUVExp)...
                .add('TTLHVswitch1',1)...
                .add('TTLionShutter', 1)...
                .add('TTLbkgd', 1)...           %trigger func gen.
                .add('ODT1',f*VODT1)...
                .add('ODT2',f*VODT2);
            %s.addStep(tIonUVExp)...
                %.add('TTLHVswitch1',1)...
                %.add('TTLionShutter', 0)...
                %.add('TTLbkgd', 1)...           %trigger func gen.
                %.add('ODT1',f*VODT1)...
                %.add('ODT2',f*VODT2);
        end
        s.add('TTLscope',1);
        s.wait(1e-6);
        s.add('TTLionShutter', 0);
        s.add('TTLbkgd', 0);
        s.add('TTLHVswitch1',0);
        s.addStep(10e-6)...
            .add('ODT1', rampTo(VODT1))...
            .add('ODT2', rampTo(VODT2));
    end
    
    if 0
        
        VODT1 = 0.115.*1.3;
        VODT2 = 0.818;
        
        tIonUVExp = x;
        repRate = 7000;
        numCycle = tIonUVExp.*repRate;
        tOn = 41e-6;
        tUVTrig = 71e-6 - tOn;
        tOff = 72e-6;
        LL = 0;
        %     numCycle = x.*3000;
        %     tOn = 167e-6;
        %     tOff = 167e-6;
        %     LL = 0;
        %     dtRamp = 25e-3;
        
        %     s.addStep(dtRamp)...
        %         .add('ODT1', rampTo(VODT1))...
        %         .add('ODT2', rampTo(VODT2));
        s.add('TTLionShutter', 1);
        for i = 1:numCycle
            s.addStep(tOn)...
                .add('ODT1',(2-LL)*VODT1)...
                .add('ODT2',(2-LL)*VODT2);
            s.addStep(tUVTrig)...
                .add('TTLbkgd',1);
            s.addStep(tOff)...
                .add('ODT1',LL*VODT1)...
                .add('ODT2',LL*VODT2)...
                .add('TTLbkgd',0);
        end
        %     for i = 1:numCycle
        %         s.addStep(tOn)...
        %             .add('ODT1',LL*VODT1)...
        %             .add('ODT2',LL*VODT2)...
        %             .add('TTLbkgd',0);
        %         s.addStep(tOff)...
        %             .add('ODT1',(2-LL)*VODT1)...
        %             .add('ODT2',(2-LL)*VODT2)...
        %             .add('TTLbkgd',0);
        %     end
        
        s.addStep(10e-6)...
            .add('ODT1', rampTo(VODT1))...
            .add('ODT2', rampTo(VODT2));
        s.add('TTLionShutter', 0);
        
        %         s.addStep(dtRamp)...
        %             .add('ODT1', rampTo(VODT1))...
        %             .add('ODT2', rampTo(VODT2));
        
        s.wait(1e-3);
        
    end
    %%-----------Backbard STIRAP-----------
    s.add('FreqStirapAOM970', FreqDDS970_1)...
        .add('FreqStirapAOM690', FreqDDS690_2);
    s.addStep(t_STIRAP_fwd)...
        .add('TTLSTIRAPTrig', 1)...
        .add('TTLSTIRAPShutter', 1);
    s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
        .add('AmpStirapAOM970', AmpDDS970)...
        .add('AmpStirapAOM690', AmpDDS690);
    s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
        .add('AmpStirapAOM690', 0.0)...
        .add('TTLSTIRAPTrig',0)...
        .add('TTLSTIRAPShutter', 0); % Turn off STIRAP shutters
end
% %%-----------2nd Roundtrip STIRAP-----------
% s.wait(5e-6); 
% s.add('FreqStirapAOM970', FreqDDS970_1)...
%     .add('FreqStirapAOM690', FreqDDS690_2);
% s.add('TTLSTIRAPTrig',1)...
%     .add('TTLSTIRAPShutter', 1)...
%     .add('TTLscope',1);
% tTotal = t_STIRAP_fwd+t_STIRAP_GS+t_STIRAP_bk;
% tparI = x*1e-6;
% if tparI > tTotal
%     error('x need to be smaller than tTotal!');
% end
% s.addStep(tparI)...
%     .add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0)...
%     .add('TTLSTIRAPTrig',0)...
%     .add('TTLSTIRAPShutter',0);
% %%-----------------------------------------

% if x > 1
%% -------- 2nd STIRAP roundtrip ----------
% % FreqDDS970_2 = 80.0e6;
% % FreqDDS690_2 = 80.0e6; %79.4
% 
% dtSTIRAPramp = 4e-6;
% t_STIRAP_fwd = 7e-6 + dtSTIRAPramp; %[s]
% t_STIRAP_GS = 8e-6;%[s]
% t_STIRAP_bk = t_STIRAP_fwd; %[s]
% t_STIRAP_wait2 = 24e-6; %[s] wait time between FW and BK STIRAP
% t_STIRAP_wait_min = 24e-6; %[s]
% 
% if t_STIRAP_wait < t_STIRAP_wait_min
%     error('t_STIRAP_wait needs to be >= t_STIRAP_wait_min')
% end
% s.add('TTLscope',1);
% %%-----------Forward STIRAP-----------
% s.add('FreqStirapAOM970', FreqDDS970_1)...
%     .add('FreqStirapAOM690', FreqDDS690_2);
% s.add('TTLSTIRAPTrig',1);
% s.add('TTLSTIRAPShutter',1);
% s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
%     .add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0)...
%     .add('TTLSTIRAPTrig',0);
% s.addStep(t_STIRAP_bk)...
%     .add('AmpKOPRepumpAOM', 0);
% s.add('TTLscope',0);
% s.add('AmpKOPRepumpAOM', 0.0);
% %%-----------hold at GS KRb-------------
% s.wait(t_STIRAP_wait2 - t_STIRAP_wait_min + 1.5e-6);
% %%-----------Backbard STIRAP-----------
% s.add('FreqStirapAOM970', FreqDDS970_1)...
%     .add('FreqStirapAOM690', FreqDDS690_2);
% s.addStep(t_STIRAP_fwd)...
%     .add('TTLSTIRAPTrig', 1);
% s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
%     .add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690)...
%     .add('TTLImagingShutter', 0);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0);
% s.add('TTLSTIRAPTrig',0);
% s.add('TTLSTIRAPShutter',0);
%end

%% -----------2nd Roundtrip STIRAP-----------
if 0
    s.wait(5e-6);
    s.add('FreqStirapAOM970', FreqDDS970_1)...
        .add('FreqStirapAOM690', FreqDDS690_2);
    s.add('TTLSTIRAPTrig',1)...
        .add('TTLSTIRAPShutter', 1)...
        .add('TTLscope',1);
    tTotal = t_STIRAP_fwd+t_STIRAP_GS+t_STIRAP_bk;
    s.addStep(t_STIRAP_fwd+t_STIRAP_GS+t_STIRAP_bk)...
        .add('AmpStirapAOM970', AmpDDS970)...
        .add('AmpStirapAOM690', AmpDDS690);
    s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
        .add('AmpStirapAOM690', 0.0)...
        .add('TTLSTIRAPTrig',0)...
        .add('TTLSTIRAPShutter',0);
end
%%-----------------------------------------

%% ------Ramp up for imaging-------------
if 1
    BFR3 = 550;        %[G]
    tFR3 = 0.1e-3;     %[s]
    BFB3 = BFR1 - BFR3;        %[G]
    IFB3 = BFB3./s.C.FastBCoilGperA;
    s.addStep(@fastBCoilRampOn,IFB3,tFR3);
    s.wait(10e-3); % 10e-3
end

% s.wait(2000.*1e-3);

% %%----trap frequency measurement---------
% s.add('TTLODT2',0);
% s.wait(4e-3);
% s.add('TTLODT2',1);
% s.wait(x*1e-3);

%% --------------TOF imaging-----------
TOFRb = 2.5e-3;     %2.5 (optimizing 11/25/2019) 10     %1.5 7 TOFRb or TOFK needs to be bigger than texpcam/2+tid = 251us
TOFK = 3e-3;      %3.0  (optimizing 11/25/2019)   7  %2 5 abs(TOFK-TOFRb)<= texpcam/2+tid = 251us
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
Bstatus = 1;            %0 means low B (~30G), 1 means high B (~550G);
if Bstatus
    s.addStep(@preimaging, 770e6, 0*6.1e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
else
%     s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
    s.addStep(@preimaging, 42.4e6, 0, 51.4e6, 0, Bstatus); %for 30G (K at +9/2, 51.4e6);  Taken on 7/26/2018
end
%% --------high B Rb ARP for imaging---------------
if 1
    if Bstatus
        fARP = 8048.7;                %8048.7 [MHz] ARP center frequency
        s.addStep(@RbHighbARP, fARP);           % Rb ARP between |22> and |11>
    else
        fARP = 6897.2; %6897.9;           %[MHz]
        s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11>
    end
end
%% ---------Turn off ODT---
s.add('ODTtransf',-1);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT1',0);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',0);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
% s.wait(5e-3);
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);       %enable this for normal operation
% s.add('ODT2',0);%DAC value 0-1V, negative means off
% s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
% s.addStep(@ABLTransfer);

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
s.addStep(@MakeKMOT);
%% -------------Turn things off at the end of a script-----------
VPS = 0.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

% s.run();
end