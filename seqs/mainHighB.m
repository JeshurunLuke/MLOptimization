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
s.add('FreqTransfODTAOM',81.613e6);
% Turn Transfer ODT 60 MHz power ON
%s.add('AmpTransfODTAOM2', 0.5);
%s.add('FreqTransfODTAOM2',60e6);
% Keep Transfer ODT switch off before calling on it
s.add('TTLODTtransf',0);

% s.add('TTL2GHzRF',0);
%% -----------------Rb MOT----------
% disp('MOT stage...');
s.add('TTLMOTCCD', 1);     % UV LED TTL, 0 - off, 1 - on
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
tMOTUV = 1;       %[s] old value 1.5 s
s.wait(tMOTUV);%wait for t1 at Rb MOT stage
s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
tMOTHold = 5.0;
s.wait(tMOTHold);
%% --------------Rb CMOT----------
tCMOT=5e-3;%[s]The time duration of CMOT 5e-3 20e-3
s.addStep(@RbCMOT,tCMOT); %run Rb CMOT
%% --------------Rb Molasses + K Grey Molasses----------
if 1 %use Rb GM + K GM
    tMolas = 8e-3;%[s]The time duration of molasses 10e-3
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
% tOP=4e-3;%[s]should>(ShutterDelay+Delay), was 5e-3 Oct 21 2021
% %Was tOP = 6e-3 on 3/1/2020
% s.addStep(@OP,tOP);%
tRbOP = 1.8*1e-3; %11/19/2019, 5e-3
tKOP = 1.6*1e-3;
s.addStep(@OP, tRbOP,tKOP);%

%% --------------Loading atoms into the transfer coil---------
tQtrap=3e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
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
s.addStep(@QUICParallelLoad,20.000,21.630,500e-3);% 21.63A
trapID = 1;
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time
%% --------------Evaporate inside the QUIC trap -------------
s.addStep(@RFevap2);
% s.addStep(@RFevap2MachineT);
% s.addStep(@uwaveEvap3);
s.wait(10e-3);
% %%--------- Load in transfer ODT--------------
VODTtransf1 = 3.8;  %3.8, 1.3, 1.25, 2, 3.5, 2.8,3.0            
%VODTtransf1 = 2.0 01/07/2020
%s.add('TTLscope',1);
s.add('TTLODTtransf',1);        %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT, 300e-3, VODTtransf1); % was 500e-3
s.addStep(@QUICTrapOff,1e-3); %turn off the QUIC trap, takes 1 ms, creats 2.2G quant field in QUIC
trapID = 2;


%% -------Forward ODT transfer---------
if 0
    Ratio4f = 2.4;
    Pquic = 53.7; %0.08 (53.92, 54.22)
    PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
    TransDist = 323.6;      % [mm] transfer distance of ODT 322.15, 322.5 on 6/15/2021 323 on 9/1/2021
    PScienceOffset = TransDist/Ratio4f; %316.4/2.727;
    Vel1 = 350;           %velocity for stage 1 was 350
    Vel2 = 200;         %velocity for stage 2, inactive if stageNum = 1
    ARate = 800;        %800 [mm/s^2]
    DRate = ARate;        %500 [mm/s^2]
    stageNum = 1; % If stageNum > 1, put in PIntOffset;
    ABLTrajPlotFlag = 0;    %0 mean not plot, 1 means plot
    tODTFwdTrip = ABLTripTime(Ratio4f,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
    disp(['tODTFwdTrip = ', num2str(tODTFwdTrip), ' s']);
    % Trigger ABL forward
    s.addStep(@ABLTransfer);
    trapID = 3;
    s.wait(tODTFwdTrip);    
end

%% ---------- Forward ODT transfer LBZ's test code, ramp the TODT power down to maintain the same trapping freq
if 1
    Ratio4f = 2.4;
    Pquic = 53.92; %0.08 (53.92, 54.22)
    PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
    TransDist = 323.5;      % [mm] transfer distance of ODT 322.15, 322.5 on 6/15/2021 323 on 9/1/2021
    PScienceOffset = TransDist/Ratio4f; %316.4/2.727;
    Vel1 = 400;           %velocity for stage 1
    Vel2 = 200;         %velocity for stage 2, inactive if stageNum = 1
    ARate = 500;        %800 [mm/s^2]
    DRate = 500;        %500 [mm/s^2]
    stageNum = 1; % If stageNum > 1, put in PIntOffset;
    ABLTrajPlotFlag = 0;    %0 mean not plot, 1 means plot
    tODTFwdTrip = ABLTripTime(Ratio4f,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
    disp(['tODTFwdTrip = ', num2str(tODTFwdTrip), ' s']);
    % Trigger ABL forward
    s.addStep(@ABLTransfer);
    trapID = 3;
    
    newTODTPWR = 0.7; %0.7, 1 0.4 ramp from 3.2 to 1.7
    s.addStep(tODTFwdTrip) ...
    .add('ODTtransf',rampTo(newTODTPWR));
    
%     s.wait(x*1e-3);
end

%%---------Forward ODT Transfer Test------------%%
if 0
   Pquic = 53.94;
   TransDist = 322.9; % [mm] 323.7 transfer distance of ODT
   BQUIC = 22; %[G] BQUIC typically <= 22 G
   BScience = 0; % [G] BScience typically <= 25.8 G
   %BFB = 10; % [G] BFB typically <= 30 G
   VTransODT = 3.2;
   s.addStep(@TransODTMove,Pquic,TransDist,BQUIC,BScience,VTransODT);
   trapID = 3;
end

%% ------------Load from transfer ODT to H static ODT---
if 1
    VODT1 = 4;    %2.5*1.3, ODT1 is H static ODT, (0.6W/V, 8/15/2022)(0.64W/V, 11/18/2019)(0.68 W/V, 6/25/2018) (0.74 W/V, 6/25/2018)
    %VODT1 = 2.5*1.3; 01/07/2020
    tLoad = 200e-3; %200e-3
    % s.add('TTLscope',1);
    s.addStep(@ODT2ODT, tLoad, VODT1);
    trapID = 4;    
end

%%--- Trigger ABL back--------------
if 1
    s.wait(50e-3);
    s.addStep(@ABLTransfer);
end



%%%%-----Turn on quant field for ARPs--------%%%%%%%
if 1
    VperA = -1/1.2;
    Iquant = 4;%[A]
    Vquant = Iquant*VperA;
%     s.add('TTLscope',1);
    s.addStep(250e-3)... % was 100e-3, changed to 200e-3 on 02/23/2020
        .add('VctrlCoilServo6', rampTo(Vquant))...      %large transfer quant field coil, -1V => 1.2A => 25.8G
        .add('Vquant1', rampTo(0)); %turn off the QUIC quant field
end

% VODT1 = 0.5;
% s.addStep(100e-3)...
%     .add('ODT1', rampTo(VODT1));
%% -----lowb ARP----------------
if 1
%     s.add('TTLuwaveampl',1);   %
%     s.add('TTLValon', 0);     %trigger Valon for preparing 3533.25MHz, 0 = lowB ARP, 1 = HighB ARP;
    s.wait(10e-3); % was 10e-3
    fARP = (6888.975);     %0.4      %[MHz]6889
    s.addStep(@RbuwaveARP, fARP); %0.5, Rb ARP between |22> and |11> for imaging, set ampARP at 0.5 for molecule making!
%     s.addStep(@RbuwaveARP20, fARP,0.35);
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
    s.add('TTLscope',1);

    %s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11> for imaging
end



% s.add('TTLValon', 1);     %trigger Valon for preparing 4120MHz, 0 = lowB ARP, 1 = HighB ARP;
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
    %.add('Vquant1', rampTo(0)); %turn off the QUIC quant field
s.wait(10e-3);
%% ----Ramp to high B-----------------------
if 1
    fprintf('Turning On: %f\n', s.curTime);
    BFR1 = 550;        %[G]
    tFR1 = (10).*1e-3;     %[s] it was 10e-3
    IFR1 = BFR1./s.C.FeshbachGperAHB;     %use FeshbachGperAHB for high B
    s.addStep(@fbCoilRampOn,IFR1,tFR1);
    s.wait(100e-3);
    % s.add('TTL2GHzRF',0); %trigger Keithley multimeter to monitor FB coil current
    s.wait(100*1e-3);
end

%% ---turn on V static ODT at high power but no evaporation (for alignment) -------
if 0
    %s.add('TTLscope',1);
    VODT2 = 3;     %3, 0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
    VODT1 = 0.5; 
%     s.wait(x*1e-3+1e-6);
    s.add('TTLODT2',1);
    s.addStep(100e-3)...
        .add('ODT1', rampTo(VODT1))...
        .add('ODT2', rampTo(VODT2));
    s.wait(20e-3);
    % trapID = 5;
    % VODT1 = 0.125;
end

%% ------Ramp up fast B coil for ODT evap-------------
if 0
    tFR0 = 1e-3;     %[s]
    BFB0 = 1;        %[G]
    IFB0 = BFB0./s.C.FastBCoilGperA;
    s.addStep(@fastBCoilRampOn,IFB0,tFR0);
    s.wait(2e-3); % 10e-3
end

% VODT1 = 0.5;
% s.addStep(100e-3)...
%     .add('ODT1', rampTo(VODT1));


%% ---turn on V static ODT and Evaporate-------
if 1
    %s.add('TTLscope',1);  
    VODT2 = 0.4;     %0.4, 0.818; ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
    s.addStep(@ODT1Evap, VODT1, VODT2); 
    trapID = 5;
    VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);    %This is only important for calculating right Temperature
    %VODT1 = x.*(0.119.*1.3);
    %s.wait(0.5);
    s.addStep(@KpreKill);
    s.wait(20e-3); %20e-3
    %s.wait(x + 1e-6);
    
%     VODT2 = 0.4;
%     VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
%     s.addStep(50e-3*abs(1-x)+1e-6)...
%        .add('ODT2', rampTo(x.*VODT2))...
%        .add('ODT1', rampTo(x.*VODT1));
%     
%     VODT2 = 1.2;
%     VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
%     s.wait(50e-3);
%     s.addStep(50e-3)...
%        .add('ODT2', rampTo(VODT2))...
%        .add('ODT1', rampTo(VODT1));
%     
end

%% -- parametric heating to measure the trapping freq of Rb atoms --
if 0
    s.add('TTLscope',1);
%     freq = x;
%     ncycle = 360;
%     t_heat = 1./freq.^2*ncycle;
%     t_heat = 1./freq.*ncycle/10;

    VODT2 = 0.4;  
    VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);  
    
%     s.add('ODT1',4*VODT1)
    s.add('ODT2',3);
    s.wait(12e-3);
%     s.add('ODT1',VODT1);
    s.add('ODT2',VODT2);
    s.wait(x.*1e-3+0.5e-6);
    
%     s.addStep(@ODTParaHeat,VODT1,t_heat,0.08*VODT1,freq); %ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)   
%      s.addStep(@ODTParaHeat,VODT2,t_heat,0.2*VODT2,freq);
%     % Ramp down ODT intensity to spill out hot atoms
%     VODT2 = 0.4;
%     VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
%     s.addStep(25e-3)...
%         .add('ODT2', rampTo(0.6.*VODT2))...
%         .add('ODT1', rampTo(0.6.*VODT1));
end

%% ------Ramp down fast B coil after ODT evap-------------
if 0
    tFR0 = 1e-3;     %[s]
    BFB01 = 1;        %[G]
    IFB01 = BFB01./s.C.FastBCoilGperA;
    s.addStep(@fastBCoilRampOn,IFB01,tFR0);
    s.wait(2e-3); % 10e-3
end

%% --- Rb HighB ARP for Rydberg excitations
if 0  
    fARP = 8048.7+0.4-0.125;                %8048.7 [MHz] ARP center frequency
    %fARP = 8048.7 on 12/10/2020; 
    s.add('TTLRbHighARP',1);
    s.addStep(@RbHighbARP, fARP);           % Rb ARP between |22> and |11>
    s.add('TTLRbHighARP',0);
    s.wait(5e-3);
end

if 0
    s.add('TTLRydShutter',1);
    s.wait(4.5e-3);
    tblast = 50e-6; %shine Rydberg light onto atoms for variable time
    s.add('TTLscope',1);
    s.addStep(tblast)...
        .add('TTLHVswitch1', 1);
        %.add('TTLscope',1);
    s.add('TTLHVswitch1', 0);
    s.add('TTLRydShutter',0);
end

%VODT1 = x.*(0.119.*1.3);
%dtRamp = 50e-3;
%s.addStep(dtRamp)...
%    .add('ODT1', rampTo(VODT1))...
%    .add('ODT2', rampTo(VODT2));

%% ---------Feshbach ramp---------------
if 1 %1 means enable Feshbach ramp, 0 means disable
    Bcorrection = 1.48;%1.48,1.5;  %1.2 3/12/2019, 1.5
    %% ------Ramp down across Feshbach resonance---------------
    BFR2 = 545.5-Bcorrection;       %[G] 545.5
    SperG2 = (0.4*250).*1e-6;      %Inverse ramp rate [s/G], (0.2*250).*1e-6, 250 us/G, (0.5*250).*1e-6 10/21/2021
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
    s.wait(0.26e-3); %0.2e-3
    fARPKill = (8037.9+0.55)*1e6; %0.55 0.3 8038.4*1e6 on 12/08/2020; 8037.1e6;  8036e6; for 2 ms; 8038.75 for 1 ms
    dfKill =1.0e6;
    %dfKill = 1.0e6; %1.0e6 on 12/08/2020
    uwaveAmpKill = 0.85; %0.85 0.4 nominal value, 0.85 for better molecule condition
    s.addStep(@RbARPKill, fARPKill, dfKill, (0.75)*1e-3, uwaveAmpKill);  %  0.75e-3 
    s.wait(0*1e-3+1e-6);
end
% 
% %%----- Pulse on 970 nm light ----------
% t_970_pulse = 10*1e-6; %[s]
% s.add('TTLscope',1);
% s.add('FreqStirapAOM970',80e6)...
%         .add('FreqStirapAOM690', 79.4e6)...
%         .add('TTLSTIRAPShutter', 1);
% s.addStep(t_970_pulse)...   
%     .add('AmpStirapAOM970', 0.06)... %0.075
%     .add('AmpStirapAOM690', 0.4); %0.4
% s.add('AmpStirapAOM970', 0.0)...
%     .add('AmpStirapAOM690', 0.0)...
%     .add('TTLSTIRAPShutter', 0);

% % % -------- STIRAP roundtrip with 4 us wait ----------
% % t_STIRAP = 35e-6;       %[s] 20us for roundtrip STIRAP; 35 us for one-way STIRAP
% % AmpDDS690 = 0.385;         %0.3x1.2833=0.385 [V] max power of 690nm
% laser, 4.45 mWm
% % AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % s.add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690);
% % s.add('TTLscope',1)...
% %     .add('TTLSTIRAPTrig',1);
% % s.wait(t_STIRAP);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0);
% % s.add('TTLSTIRAPTrig',0);

%% -------- STIRAP roundtrip with controlled wait ----------
if 1 % 1- enable STIRAP, 0- disable
    AmpDDS970 = 0.5;   %0.5 0.4  %0.8*0.475; 0.475; 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
    AmpDDS690 = 0.3; % 0.3 0.23  0.3     % 0.24 on 6/15/2021, 0.300; 0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
    %AmpDDSKKill = 0.300;        % DDS amplitude for K kill pulse after GS molecule step
    
    FreqDDS970_1 = 80.0e6;
    FreqDDS690_1 = 80.0e6;
%         FreqDDS970_2 = 80.0e6;
    %FreqDDS690_2 = x.*1e6;    %79.2e6;
    FreqDDS690_2 = (79.14).*1e6;    %79.2e6;
    
    dtSTIRAPramp = 4e-6;
    t_STIRAP_fwd = 7e-6 + dtSTIRAPramp; %[s]
    t_STIRAP_GS = 8e-6;%[s]
    t_STIRAP_bk = t_STIRAP_fwd; %[s]
    t_STIRAP_wait = (5).*1e-3;%10e-3; %[s] wait time between FW and BK STIRAP
    %t_STIRAP_wait = 10e-3; %normally 10e-3 on 12/07/2020; %[s] wait time between FW and BK STIRAP
    t_kill = 5e-3; %5e-3 on 6/16/2021
    uwaveamp_kill = 0.6; %0.6 DDS amplitude for uwave {1,1} to {2,2} ARP to remove Rb atoms
    OPamp_kill = 0.006; % 0.2, 0.18, 0.15, DDS amplitude for Rb OP AOM which controls light power for Rb atom removal
    %%-----------Forward STIRAP-----------
%     s.add('TTLscope',1);
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
    fARPKill = (8033.65)*1e6;%8032.9, 8032.65,8038.9 8037.1e6; %8036.00 8036.25 8037.75e6; %8037.50; 8036e6; for 2 ms; 8038.75 for 1 ms
    %fARPKill = (7633.33 + x)*1e6;
    dfKill = 2.0e6;
    s.addStep(@kill, fARPKill, dfKill, t_kill, uwaveamp_kill, OPamp_kill);
     
    
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
        
    % N=1 microwave |0,0,-4,1/2> to |1,0,-4,1/2>   
    if 0
        dt1 = 245*1e-6;  % pi pulse length, Valon freq 2228.104 MHz, att = 0
        s.add('TTLODT1',0);
        s.add('TTLODT2',0);
        s.add('ODT1', 0);
        s.add('ODT2', 0);
        s.wait(10e-6);
        
        % pi pulse of up leg, N=0 to N=1
        s.addStep(1*dt1)...
            .add('TTLkrbValon2',1);
        s.add('TTLkrbValon2',0);
        s.wait(1e-6);
        
        s.add('TTLODT1',1);
            s.add('TTLODT2',1);
            s.add('ODT1', VODT1);
            s.add('ODT2', VODT2);
    end
    

    % -- parametric heating to measure the trapping freq of KRb Molecules --
    if 0
        freq = x;
        ncycle = 360^2/20;
    %     t_heat = 1./freq.^2*ncycle;
%         t_heat = 1./freq.^2.*ncycle;
        VODT2 = 0.4;
        VODT1 = (0.119.*1.3);
        t_heat = 40e-3;
%         s.addStep(@ODTParaHeat,VODT1,t_heat,0.2*VODT1,freq); %ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)   
        s.addStep(@ODTParaHeat,VODT2,t_heat,0.4*VODT2,freq); %ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)   

        % Ramp down ODT intensity to spill out hot atoms
        VODT2 = 0.4;
        VODT1 = (0.119.*1.3);
        s.addStep(15e-3)...
            .add('ODT2', rampTo(0.8.*VODT2))...
            .add('ODT1', rampTo(0.8.*VODT1));
    end
    
    % -- slosh measurement to measure the trapping freq of KRb Molecules --
    if 0
        %         VODT2 = 0.4;
        %         VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
        
%         VODT2 = 0.4;
%         VODT1 = (0.119.*1.3);
%         s.addStep(25e-3)...
%             .add('ODT2', rampTo(1.5.*VODT2))...
%             .add('ODT1', rampTo(1.5.*VODT1));
%         
%         s.add('ODT2',0.*VODT2);
%         s.wait(1e-3);
%         s.add('ODT2',1.5*VODT2);
%         s.wait(x.*1e-3+0.5e-6);
%         
        
        s.add('TTLODT2',0);
        s.wait(8e-3);
        s.add('TTLODT2',1);
        s.wait(x.*1e-3+0.5e-6);
        
    end

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
%         s.add('TTLscope',1);
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
    %s.wait(100.*1e-3);
    if 0
        VODT1 = 0.5*(0.125/(0.115*1.3))*(0.119.*1.3);
        VODT2 = 0.5*0.400; % 0.818; make sure this matches what's currently used in the experiment
        dtRamp = 30e-3;
        s.addStep(dtRamp)...
            .add('ODT1', rampTo(VODT1))...
            .add('ODT2', rampTo(VODT2));
        s.wait(5.*1e-3);
        VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
        VODT2 = 0.400; % 0.818; make sure this matches what's currently used in the experiment
        dtRamp = 30e-3;
        s.addStep(dtRamp)...
            .add('ODT1', rampTo(VODT1))...
            .add('ODT2', rampTo(VODT2));
    end
    
    if 0
        VODT1 = (0.125/(0.115*1.3))*(0.119.*1.3);
        VODT2 = 0.400; % 0.818; make sure this matches what's currently used in the experiment
%         dtRamp = 30e-3;
%         s.addStep(dtRamp)...
%             .add('ODT1', rampTo(VODT1))...
%             .add('ODT2', rampTo(VODT2));
        
        tIonUVExp = 80.*1e-3; % x [s]  Please also change "edgeWaveBurst.m" correspondently.
%         f = (1/3000)/(1/3000 - 4e-6);
        f = 4;
        %f = 2;
        s.add('TTLscope',1);
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
    
    %%-----------hold at GS KRb-------------
    s.wait(t_STIRAP_wait+1e-6);
    %s.wait(1e-6);
    %s.wait(x.*1e-3);
    %%-----------KRb + Rb system measurements || Rydberg laser test------------
    if 0
        BfieldrampFlag = 1;
        EfieldFlag = 0;
%         s.add('TTLscope',1);
        if BfieldrampFlag
            %% ------Ramp fastB off -------------
            BFR3 = 550;        %[G] 550
            tFR3 = 0.1e-3;     %[s]
            BFB3 = BFR1 - BFR3;        %[G]
            IFB3 = BFB3./s.C.FastBCoilGperA;
            s.addStep(@fastBCoilRampOn,IFB3,tFR3);
            
            %% ------Turn on electric field----------
            if EfieldFlag
                s.add('TTLHVswitch1', 1);%turn on electrodes for settling down
            end
            
            %% ------Ramp down Feshbach field------------
            BFR3 = 30;        %[G]  5
            tFR3 = 30.*1e-3;     %[s]  10e-6
            IFR3 = BFR3./s.C.FeshbachGperA;
            %For high field use FeshbachGperAHB, for low field use FeshbachGperA
            s.addStep(@fbCoilRampOn,IFR3,tFR3);
            s.wait(10e-3);
        end
        
        % turn on Rydberg light
        if 0
            s.add('TTLRydShutter',1);
            s.wait(5e-3);
            tblast = 50e-6; %shine Rydberg light onto atoms for variable time
            s.add('TTLscope',1);
            s.addStep(tblast)...
                .add('TTLHVswitch1', 1);
            %.add('TTLscope',1);
            s.add('TTLHVswitch1', 0);
            s.add('TTLRydShutter',0);
        end
        
        %%-----Transfer KRb to different hyperfine state--------
        if 0
            dt1 = 39.0*1e-6;     % pi for |0,0,-4,1/2> to |1,0,-4,3/2>
            VODT1 = (0.119.*1.3);
            s.wait(15e-3);
            
            s.add('TTLODT1',0);
            s.add('TTLODT2',0);
            s.add('ODT1', 0);
            s.add('ODT2', 0);
            s.wait(10e-6);
            
            % pi pulse for up leg
            s.addStep(dt1)...
                .add('TTLkrbValon1',1);
            s.add('TTLkrbValon1',0);
            s.wait(1e-6);
            
            s.add('TTLODT1',1);
            s.add('TTLODT2',1);
            s.add('ODT1', VODT1);
            s.add('ODT2', VODT2);
            s.wait(1e-3);
        end
        
        %Hold the atoms and molecules for some time
%         t_AtomMolecule = 1.*1e-3;
%         s.wait(t_AtomMolecule + 1e-6);
        
        if BfieldrampFlag
            %% ------Ramp up B field for backward STIRAP------------
            s.addStep(@fastBCoilRampOn,IFB21,tFR21);    %Ramp fastB on
            if EfieldFlag
                s.add('TTLHVswitch1', 0);%turn off electrodes
            end
            s.addStep(@fbCoilRampOn,IFR1,tFR3);         %Ramp FB coil on
            s.wait(75e-3); %wait a bit for the fields to settle a little
        end
        
        %if BfieldrampFlag
        %    %% ------Ramp down B field for low field imaging of atoms------------
        %    BFR3 = 550;        %[G] 550
        %    tFR3 = 0.1e-3;     %[s]
        %    BFB3 = BFR1 - BFR3;        %[G]
        %    IFB3 = BFB3./s.C.FastBCoilGperA;
        %    s.addStep(@fastBCoilRampOn,IFB3,tFR3);
        %    %s.addStep(@fastBCoilRampOn,IFB21,tFR21);    %Ramp fastB on
        %    BFR3 = 30;        %[G]  5
        %    tFR3 = 1e-3;     %[s]  10e-6
        %    IFR3 = BFR3./s.C.FeshbachGperA;
        %    %For high field use FeshbachGperAHB, for low field use FeshbachGperA
        %    s.addStep(@fbCoilRampOn,IFR3,tFR3);
        %    %s.addStep(@fbCoilRampOn,IFR1,tFR3);         %Ramp FB coil on
        %    s.add('TTLValon', 0);
        %    s.wait(20e-3); %wait a bit for the fields to settle a little
        %end
        
        
        %%----Remove the remaining Rb atoms to just image molecules----
        if 0
            if BfieldrampFlag
                fARPKillAM = (8032.25 - 2.625).*1e6; 
            else
                fARPKillAM = (8032.25 - 0.3).*1e6;
            end
            dfKillAM = 1.0e6;
            t_killAM = 1e-3;
            s.addStep(@killAtomMolecule, fARPKillAM, dfKillAM, t_killAM);
        end
        
        %if BfieldrampFlag
        %    s.wait(10e-3);
        %end
        
        %to image only atoms turn off backward STIRAP below and turn off
        %the atom removal above
    end
    
    
    
    %%-------Wait and then remove excess atoms before backward STIRAP-------
    if 0
        AMwait = x.*1e-3;
        s.wait(AMwait + 1e-6);
        fARPKillAM = (8032.25 - 0.625).*1e6;
        dfKillAM = 1.0e6;
        t_killAM = 1e-3;
        s.addStep(@killAtomMolecule, fARPKillAM, dfKillAM, t_killAM);
    end
    
    t_AtomMolecule = 0.*1e-3;
    s.wait(t_AtomMolecule + 1e-6);
    %%-----------Backward STIRAP-----------
    if 0
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
% %%-----------Backward STIRAP-----------
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

%% ------Ramp up fast B coil for imaging-------------
if 1
    BFR3 = 550;        %[G]
    tFR3 = 0.1e-3;     %[s]
    BFB3 = BFR1 - BFR3;        %[G]
    IFB3 = BFB3./s.C.FastBCoilGperA;
    s.addStep(@fastBCoilRampOn,IFB3,tFR3);
    s.wait(10e-3); % 10e-3
end

% s.wait(2000.*1e-3);
%s.wait(20e-3);
% %%----trap frequency measurement---------
% s.add('TTLODT2',0);
% s.wait(4e-3);
% s.add('TTLODT2',1);
% s.wait(x*1e-3);
%s.add('TTLscope',1); 

% % ramp down Feshbach coil
% B_target = 10;%57+8; % [G] target B field of the ramp
% 
% t_ramp = 20.*1e-3;     %[s]
% t_AtomMolecule = 5*1e-3 +50*1e-3; %
% step_Field = s.addBackground(t_ramp + t_AtomMolecule).add('VctrlCoilServo4',FeshbachCompensateRamp(B_target,t_ramp));
% %             s.wait(t_ramp + t_AtomMolecule);
% s.wait(t_ramp +10e-3);
% 
% s.waitFor(step_Field);

% parametric heating
if 0
    freq = x;
    ncycle = 360^2/20;
    %     t_heat = 1./freq.^2*ncycle;
    %         t_heat = 1./freq.^2.*ncycle;
    VODT2 = 0.4;
    VODT1 = (0.119.*1.3);
    t_heat = 40e-3;
    s.addStep(@ODTParaHeat,VODT1,t_heat,0.2*VODT1,freq); %ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)
%     s.addStep(@ODTParaHeat,VODT2,t_heat,0.4*VODT2,freq); %ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)
    
    % Ramp down ODT intensity to spill out hot atoms
    VODT2 = 0.4;
    VODT1 = (0.119.*1.3);
    s.addStep(15e-3)...
        .add('ODT2', rampTo(0.8.*VODT2))...
        .add('ODT1', rampTo(0.8.*VODT1));
end
% %%Ramp up Feshbach field
% BFR31 = 550;        %[G]  5
% tFR3 = 5e-3;     %[s]  5e-3; 10e-6
% IFR3 = BFR31./s.C.FeshbachGperAHB;
% %For high field use FeshbachGperAHB, for low field use FeshbachGperA
% s.addStep(@fbCoilRampOn,IFR3,tFR3);
% s.wait(200e-3); %70ms, need to wait for 90ms to remove atoms
% slosh
if 0
%     VODT2 = 0.4;
%     VODT1 = (0.119.*1.3);     
    s.wait(300e-3)
    s.add('TTLODT2',0);
    s.wait(1e-3);
    s.add('TTLODT2',1);
    s.wait(x.*1e-3+0.5e-6);
end

if 0
    %% ------Ramp down B field for low B imaging------------
    BCompensation = 9.22; % when we ramp from 550G to 30G, 11.15
    TimeConstantFeshbach = 16.66e-3; %12.66e-3
    Bstable = 30; % target B field of the ramp
    BFR3 = Bstable - BCompensation;        %[G] 30 on 1/25/2021; 5
    tFR3 = 10.*1e-3;     %[s] 30e-3 on 1/25/2021; 10e-6
    IFR3 = BFR3./s.C.FeshbachGperA;
    %% ------Ramp fastB coil on first------------- start correction 2ms after the ramp down
    BfastBCompensation = 4.77;
    IFB3 = BfastBCompensation./s.C.FastBCoilGperA;
    s.addBackground(@fastBCoilRampOn,IFB3,tFR3); % Ramp fast B on for compensation
    
    s.addStep(@fbCoilRampOn,IFR3,tFR3); % Initial overshoot for Feshbach
    
    
    tFRStep = 0.25*1e-3;  % step of each linear ramp

    for i=1:200
        BFR3new = Bstable - BCompensation*exp(-i*tFRStep/TimeConstantFeshbach);
        IFR3new = BFR3new./s.C.FeshbachGperA;
        s.addBackground((i-1)*tFRStep + (i-1) * 0.5e-6,@fbCoilRampOn,IFR3new,tFRStep);
    end
    
   
    %% ------Ramp fastB coil for short time scale B field compensation-------------
    
    
    
    s.wait(10e-3);
end

%% Feshbach coil ramp with compensation by YXLiu
if 0
    B_target = 30; % [G] target B field of the ramp
    t_ramp = 10.*1e-3;     %[s] 
    s.addBackground(20e-3).add('VctrlCoilServo4',FeshbachCompensateRamp(B_target,t_ramp));
    
%     %% ----------- FastB compensation ------------ %%
%     BfastBCompensation = 3.34;
%     FastBcompensationdelay = 2e-3;
%     IFB3 = BfastBCompensation./s.C.FastBCoilGperA;
%     s.addBackground(@fastBCoilRampOn,IFB3,t_ramp); % Ramp fast B on for compensation
%     
%     tFBStep = 0.25*1e-3;  % step of each linear ramp
%     FastBTimeConstant = 1.5e-3;
%     FastBRampdownTime = 8e-3;
%     for i=1:32
%         if i == 32
%             IFB3new = 0;
%         end
%         BFB3new = BfastBCompensation*exp(-i*tFBStep/FastBTimeConstant);
%         IFB3new = BFB3new./s.C.FastBCoilGperA;
%         s.addBackground(t_ramp+FastBcompensationdelay+(i-1)*tFBStep + (i-1) * 0.5e-6,@fastBCoilRampOn,IFB3new,tFBStep);
%     end
    
    
    %% ------FastB compensation over ------------- %%
    s.wait(t_ramp+11e-3);
end 



%% --------------TOF imaging-----------
TOFRb = 1*1e-3;     %3 2.5 (optimizing 11/25/2019) 10     %1.5 7 TOFRb or TOFK needs to be bigger than texpcam/2+tid = 251us
TOFK = 1.5*1e-3;      %1.5 3.0  (optimizing 11/25/2019)   7  %2 5 abs(TOFK-TOFRb)<= texpcam/2+tid = 251us
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
Bstatus = 1;            %0 means low B (~30G), 1 means high B (~550G);
if Bstatus
    %s.addStep(@preimaging, 770e6, 0*6.1e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
    s.addStep(@preimaging, (770.42-0.79).*1e6, 0*6.1e6, (-761.96-1-4).*1e6, 0, Bstatus);
else
%     s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
    s.addStep(@preimaging, (42.4 + 0.4 ).*1e6, 0, (51.4 - 1 ).*1e6, 0, Bstatus); %for 30G (K at +9/2, 51.4e6);  Taken on 7/26/2018
%    s.addStep(@preimaging, (47.5 - 1.87).*1e6, 0, 51.4e6, 0, Bstatus); %for 30G (K at +9/2, 51.4e6);  Taken on 7/26/2018
end


%% --------Rb RF for B field characterization --------
if 0
    fARP = 6897.2+3.25; %6897.2;           %[MHz]
        %fARP = 6897.2 - 13 - 3.5; %for Rb Atom KRb molecule project   
    s.wait(5e-3); 
    s.addStep(@RbUwavePi1,fARP);
    s.wait(50e-3);
end




%% --------Rb ARP for imaging---------------
if 0
    if Bstatus
        fARP = 8048.7;                %8048.7 [MHz] ARP center frequency
        %fARP = 8048.7 on 12/10/2020; 
        s.addStep(@RbHighbARP, fARP);           % Rb ARP between |22> and |11>
%         s.addStep(@RbuwaveARP20, fARP, 0.5); 
    else
        s.wait(5e-3);
        fARP = 6897.2+1.25+0.75-0.75; %6897.2;           %[MHz]
        %fARP = 6897.2 - 13 - 3.5; %for Rb Atom KRb molecule project           %[MHz]
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

doubleshotRb = 0; % sets if we take Rb & K (0) shadow images in rapid succession or two Rb images (1)
% NOTE: YOU MUST CHANGE CAMERA SETTINGS TO USE THIS TO USE:
% main_PCO_pixelfly_usb_v1_ScienceChamber_doubleshotRb

if doubleshotRb
    s.addStep(@imagingTOFdoubleRb, TOFRb, TOFK, Bstatus);
elseif doubleshotRb == 0
    s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);
end

%enable this for normal operation
% s.add('ODT2',0);%DAC value 0-1V, negative means off
% s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
% s.addStep(@ABLTransfer);

s.add('VctrlCoilServo6',0.5);         %turn off  quant field coil
s.add('VctrlCoilServo5',0.5);         %turn off  fastB field coil
s.addStep(@fbCoilRampOn, 0, 10e-3);           %turn off Feshbach coill
% s.add('TTLuwaveampl',0);
s.add('TTLValon', 0); 
s.add('TTLRbHighARP',0);%trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
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