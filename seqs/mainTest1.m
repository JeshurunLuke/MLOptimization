function s = mainTest1(x)

s = ExpSeq();
% 
% %% ------Default camera triggers----------
% s.add('TTLscope',0);
% VPS = 20.0; %set the QUIC trap P/S voltage
% s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);
% s.add('TTLKGMShutter',0);   %Close shutter
% s.add('TTLHVswitch1', 0);   %Turn HV switch low for E=0
% 
% %% Set transfer ODT AOM power and frequency
% % Turn Transfer ODT 90 MHz power ON
% s.add('AmpTransfODTAOM', 0.6);
% s.add('FreqTransfODTAOM',89.458e6);
% % Turn Transfer ODT 60 MHz power ON
% s.add('AmpTransfODTAOM2', 0.5);
% s.add('FreqTransfODTAOM2',60e6);
% % Keep Transfer ODT switch off before calling on it
% s.add('TTLODTtransf',0);
% %% -----------------Rb MOT----------
% % disp('MOT stage...');
% s.add('TTLMOTCCD', 1);     % UV LED TTL, 0 - off, 1 - on
% s.addStep(@MakeRbMOT);
% s.addStep(@MakeKMOT);
% tMOTUV = 1.5;       %[s] old value 2 s
% s.wait(tMOTUV);%wait for t1 at Rb MOT stage
% s.add('TTLMOTCCD', 0);     % UV LED TTL, 0 - off, 1 - on
% tMOTHold = 5.0;
% s.wait(tMOTHold);
% %% --------------Rb CMOT----------
% tCMOT=50e-3;%[s]The time duration of CMOT
% s.addStep(@RbCMOT,tCMOT); %run Rb CMOT
% %% --------------Rb Molasses + K Grey Molasses----------
% tMolas=20e-3;%[s]The time duration of molasses
% s.addStep(@Molasses,tMolas);%takes 20ms
% % s.addStep(@RbMolasses,tMolas);%takes 20ms, for turning on Rb molasses only
% %% --------------Optical pumping (OP)----------
% tOP=6e-3;%[s]should>(ShutterDelay+Delay)
% s.addStep(@OP,tOP);%
% %% --------------Loading atoms into the transfer coil---------
% tQtrap=10e-3;%[s] Qtap time; changed on 11/02/16, was 1e-3 before
% s.addStep(@Qtrap,tQtrap);
% 
% %% --------------Forward cart transfer----------
% tTrackTrig = 1e-3; % min value 1 ms
% tFwdTrip = 3409e-3; %updated from 3412e-3 on 05/14/2017; [s]1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
% s.addStep(@TrackTransfer,tFwdTrip);
% %% --------------Load from transfer coil into QUIC Quad-----------
% s.addStep(@QUICParallelLoad,20.0,0.0,500e-3);
% s.wait(500e-3); %Hold the atoms in the QUIC trap for some time
% %% --------------Backward cart transfer----------
% s.addStep(@TrackTransfer,tTrackTrig);
% %% ------------Evap in QUIC Quad----------
% s.addStep(@RFevap1);
% % s.addStep(@uwaveEvap1);
% s.wait(400e-3);
% 
% %% --------------Ramp on the Ioffe coil------------
% s.addStep(@QUICParallelLoad,20.000,21.630,500e-3);%
% trapID = 1;
% s.wait(500e-3); %Hold the atoms in the QUIC trap for some time
% %% --------------Evaporate inside the QUIC trap -------------
% s.addStep(@RFevap2);
% % s.addStep(@uwaveEvap3);
% s.wait(500e-3);
% % %%--------- Load in transfer ODT--------------
% VODTtransf1 = 2.0;              %1.6W/V see 5/25/2018
% s.add('TTLODTtransf',1);        %TTL switch ON/off ODT, 1 means on
% s.addStep(@QUIC2ODT, 500e-3, VODTtransf1);
% trapID = 2;
% %% -------Forward ODT transfer---------
% Ratio4f = 2.4;
% Pquic = 54.3;
% PIntOffset = 0./Ratio4f; % If stageNum > 1, put in PIntOffset;
% TransDist = 322.15;      % [mm] transfer distance of ODT
% PScienceOffset = TransDist/Ratio4f; %316.4/2.727;
% Vel1 = 350;           %velocity for stage 1
% Vel2 = 200;         %velocity for stage 2, inactive if stageNum = 1
% ARate = 800;        %700 [mm/s^2]
% DRate = ARate;        %500 [mm/s^2]
% stageNum = 1; % If stageNum > 1, put in PIntOffset;
% ABLTrajPlotFlag = 0;    %0 mean not plot, 1 means plot
% tODTFwdTrip = ABLTripTime(Ratio4f,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
% disp(['tODTFwdTrip = ', num2str(tODTFwdTrip), ' s']);
% % Trigger ABL forward
% s.addStep(@ABLTransfer);
% trapID = 3;
% s.wait(tODTFwdTrip);
% % %% ------------Load from transfer ODT to H static ODT---
% % VODT1 = 2.5;    %ODT1 is H static ODT, (0.74 W/V, 6/25/2018)
% % tLoad = 250e-3;
% % s.addStep(@ODT2ODT, tLoad, VODT1);
% % trapID = 4;
% 
% 
% %%%%-----Turn on quant field for ARPs--------%%%%%%%
% VperA = -1/1.2;
% Iquant = 4;%[A]
% Vquant = Iquant*VperA;
% s.addStep(100e-3)...
%     .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
% %% -----lowb ARP----------------
% s.add('TTLuwaveampl',1);   % 
% s.add('TTLValon', 0);     %trigger Valon for preparing 3533.25MHz, 0 = lowB ARP, 1 = HighB ARP;
% s.wait(10e-3);
% fARP = 6888.7;           %[MHz]6889
% s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11> for imaging
% Bkill = 2;                          %[G] B field for removing pulse
% VperA = -1/1.2;
% Ikill = 4/25.8*Bkill;%[A]
% Vkill = Ikill*VperA;
% s.addStep(5e-3)...
%     .add('VctrlCoilServo6', rampTo(Vkill));        %large transfer quant field coil, -1V => 1.2A => 25.8G
% s.addStep(@Rbkill);             %blasting beam takes 12.8 ms
% s.addStep(20e-3)...
%     .add('VctrlCoilServo6', rampTo(Vquant));        %large transfer quant field coil, -1V => 1.2A => 25.8G
% s.wait(5e-3);
% s.addStep(@KrfARP);
% % s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11> for imaging
% s.add('TTLValon', 1);     %trigger Valon for preparing 3533.25MHz, 0 = lowB ARP, 1 = HighB ARP;
% %% ==== Science chamber imaging Feshbach coil parameters
% BSciImgFld = 30.0;     %[G] 19.84
% ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
% tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
% VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
% s.addStep(tSciImgFld) ...
%     .add('VctrlCoilServo4', rampTo(VfbCoil))...
%     .add('VctrlCoilServo6', rampTo(0.5));   %turn off bias field for lowb ARP 
% s.wait(10e-3);
% %% ----Ramp to high B-----------------------
% BFR1 = 550;        %[G]
% tFR1 = 10e-3;     %[s]
% IFR1 = BFR1./s.C.FeshbachGperAHB;     %use FeshbachGperAHB for high B
% s.addStep(@fbCoilRampOn,IFR1,tFR1);
% s.wait(200e-3);
% s.add('TTLscope',1);
% % %% ---turn on V static ODT and Evaporate-------
% % VODT2 = 1.0;     %ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
% % s.addStep(@ODT1Evap, VODT1, VODT2);
% % trapID = 5;
% % VODT1 = 0.125;
% % s.wait(0.5);
% s.addStep(@KpreKill);
% s.wait(20e-3);
% % % ----evap in transfer ODT--------
% VODT2 = 0;     %ODT2 is V static ODT, Tested Maximum ~4W (1W/V, 5/25/2018)
% s.addStep(@ODTtranfEvap,VODTtransf1, VODT2);
% s.wait(500e-3);
% VODTtransf1 = 0.5;

% %%---------TimeAvaraged trap----------
% f0 = 89.458e6;
% df = 10e6;
% Freq = 100e3;
% tDrive = 200e-3;
% s.add('TTLODT2',1);
% s.add('ODT2', 0.01);
% s.addStep(tDrive) ...
%     .add('FreqTransfODTAOM', @(t) df.*sin(t.*2.*pi.*Freq) + f0)...
%     .add('ODT2', rampTo(VODT2));
% s.wait(1e-6);
% s.add('FreqTransfODTAOM', f0);

% Bcorrection = 1;
% %% ------Ramp down across Feshbach resonance---------------
% BFR2 = 545.5-Bcorrection;       %[G] 545.5
% SperG2 = 250e-6;      %Inverse ramp rate [s/G], 250
% 
% % % Use Feshbach coil for ramp
% % IFR2 = BFR2./s.C.FeshbachGperAHB;
% % s.add('TTLscope',1);
% % s.addStep(@fbCoilRampOn,IFR2,tFR2);
% 
% % Use fast B coil for ramp
% BFB2 = BFR1 - BFR2;
% tFR2 = (BFR1-BFR2)*SperG2;        % 3e-3 %[s]
% IFB2 = BFB2./s.C.FastBCoilGperA;
% s.addStep(@fastBCoilRampOn,IFB2,tFR2);
% 
% %% ------Ramp down kill field for kill unpaired Rb---------------
% BFR21 = 544.1-Bcorrection;        % [G] was at 544.5 G
% tFR21 = 0.1e-3;     %0.1e-3 [s]
% 
% % % Use Feshbach coil for ramp
% % IFR21 = BFR21./s.C.FeshbachGperAHB;
% % s.addStep(@fbCoilRampOn,IFR21,tFR21);
% 
% % Use fast B coil for ramp
% BFB21 = BFR1 - BFR21;
% IFB21 = BFB21./s.C.FastBCoilGperA;
% s.addStep(@fastBCoilRampOn,IFB21,tFR21);
% 
% s.wait(0.2e-3); %0.2e-3
% fARPKill = 8037e6; %8036.00 8036.25 8037.75e6; %8037.50; 8036e6; for 2 ms; 8038.75 for 1 ms
% dfKill = 1.0e6;
% s.addStep(@RbARPKill, fARPKill, dfKill, 0.75*1e-3);
% s.wait(1e-6);
% 
% %% ----- Pulse on 970 nm light ----------
% % t_970_pulse = 10*1e-6; %[s]
% % s.add('TTLscope',1);
% % s.addStep(t_970_pulse)...
% %     .add('AmpStirapAOM970', 0.03)...
% %     .add('AmpStirapAOM690', 0.0);
% % s.add('AmpStirapAOM970', 0.0)...
% %     .add('AmpStirapAOM690', 0.0);
% 
% % % -------- STIRAP roundtrip with 4 us wait ----------
% % t_STIRAP = 35e-6;       %[s] 20us for roundtrip STIRAP; 35 us for one-way STIRAP
% % AmpDDS690 = 0.385;         %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% % AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % s.add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690);
% % s.add('TTLscope',1)...
% %     .add('TTLSTIRAPTrig',1);
% % s.wait(t_STIRAP);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0);
% % s.add('TTLSTIRAPTrig',0);
% 
% %% -------- STIRAP roundtrip with controlled wait ----------
% % AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % AmpDDS690 = 0.300;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% % AmpDDSKKill = 0.300;        % DDS amplitude for K kill pulse after GS molecule step
% % % AmpDDS970 = 0;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % % AmpDDS690 = 0.0;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% % % AmpDDSKKill = 0.0;
% % 
% % FreqDDS970_1 = 80.0e6;
% % FreqDDS690_1 = 80.0e6;
% % FreqDDS970_2 = 80.0e6;
% % FreqDDS690_2 = 79.736e6;
% % 
% % t_STIRAP_fwd = 16e-6; %[s]
% % t_STIRAP_GS = 8e-6;%[s]
% % t_STIRAP_bk = 16e-6; %[s]
% % t_STIRAP_wait = 40e-6; %[s]
% % t_STIRAP_wait_min = 39e-6; %[s]
% % 
% % if t_STIRAP_wait < t_STIRAP_wait_min
% %     error('t_STIRAP_wait needs to be >= t_STIRAP_wait_min')
% % end
% % s.add('TTLscope',1);
% % s.add('FreqStirapAOM970', FreqDDS970_1)...
% %     .add('FreqStirapAOM690', FreqDDS690_1);
% % s.add('TTLSTIRAPTrig',1);
% % s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
% %     .add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0)...
% %     .add('TTLSTIRAPTrig',0);
% % s.addStep(t_STIRAP_bk)...
% %     .add('AmpKOPRepumpAOM', AmpDDSKKill);
% % s.add('TTLscope',0);
% % % s.wait(50e-6);
% % s.add('AmpKOPRepumpAOM', 0.0);
% % 
% % % s.wait(x - 100e-6);
% % 
% % s.wait(t_STIRAP_wait - t_STIRAP_wait_min + 1.5e-6);
% % s.add('FreqStirapAOM970', FreqDDS970_1)...
% %     .add('FreqStirapAOM690', FreqDDS690_1);
% % s.addStep(t_STIRAP_fwd)...
% %     .add('TTLSTIRAPTrig', 1);
% % s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
% %     .add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690)...
% %     .add('TTLKImagingShutter', 0);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0);
% % s.add('TTLSTIRAPTrig',0);
% 
% %% Another STIRAP roundtrip
% 
% % if x
% % 
% % s.wait(500e-6);
% % 
% % s.add('FreqStirapAOM970', FreqDDS970_2)...
% %     .add('FreqStirapAOM690', FreqDDS690_2);
% % s.add('TTLSTIRAPTrig',1);
% % s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
% %     .add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0)...
% %     .add('TTLSTIRAPTrig',0);
% % s.addStep(t_STIRAP_bk)...
% %     .add('AmpKOPRepumpAOM', AmpDDSKKill);
% % s.add('TTLscope',0);
% % % s.wait(50e-6);
% % s.add('AmpKOPRepumpAOM', 0.0);
% % 
% % % s.wait(x - 100e-6);
% % 
% % s.wait(t_STIRAP_wait - t_STIRAP_wait_min + 1.5e-6);
% % s.add('FreqStirapAOM970', FreqDDS970_2)...
% %     .add('FreqStirapAOM690', FreqDDS690_2);
% % s.addStep(t_STIRAP_fwd)...
% %     .add('TTLSTIRAPTrig', 1);
% % s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
% %     .add('AmpStirapAOM970', AmpDDS970)...
% %     .add('AmpStirapAOM690', AmpDDS690)...
% %     .add('TTLKImagingShutter', 0);
% % s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
% %     .add('AmpStirapAOM690', 0.0);
% % s.add('TTLSTIRAPTrig',0);
% % 
% % end
% 
% %% ------Ramp up for imaging-------------
% BFR3 = 550;        %[G]
% tFR3 = 0.1e-3;     %[s]
% % % % Use Feshbach coil for ramp
% % % IFR3 = BFR3./s.C.FeshbachGperAHB;
% % % s.addStep(@fbCoilRampOn,IFR3,tFR3);
% % % Use fast B coil for ramp
% BFB3 = BFR1 - BFR3;        %[G]
% IFB3 = BFB3./s.C.FastBCoilGperA;
% s.addStep(@fastBCoilRampOn,IFB3,tFR3);
% s.wait(10e-3);

% %% ----Parametric heating measurement----
% tDrive = 1; %time for heating drive [s]
% AmpV = 0.02; %Amplitude of heating drive [V]
% Freq = x; %Frequency of heating drive [Hz]
% s.addStep(@ODTParaHeat, 0.4, tDrive, AmpV, Freq);
% s.wait(100e-3);

% 
% %% --------------TOF imaging-----------
% TOFRb = 7.0e-3;           % TOFRb or TOFK needs to be bigger than texpcam/2+tid = 251us
% TOFK = 5.0e-3;            % abs(TOFK-TOFRb)<= texpcam/2+tid = 251us
% ShutterDelay = 2.8e-3;  % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% % s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
% Bstatus = 1;            %0 means low B (~30G), 1 means high B (~550G);
% if Bstatus
%     s.addStep(@preimaging, 770e6, 0e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
% else
% %     s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
%     s.addStep(@preimaging, 42.4e6, 0, 51.4e6, 0, Bstatus); %for 30G (K at +9/2, 51.4e6);  Taken on 7/26/2018
% end
% % s.wait(ShutterDelay);
% % %% --------high B Rb ARP for imaging---------------
% if Bstatus
%     fARP = 8048.7;                %[MHz] ARP center frequency
%     s.addStep(@RbHighbARP, fARP);           % Rb ARP between |22> and |11>
% else
%     fARP = 6897.2; %6897.9;           %[MHz]
%     s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11>
% end
% %% ---------Turn off ODT---
% s.add('ODTtransf',0);%DAC value 0-1V, negative means off
% s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
% s.add('ODT1',0);%DAC value 0-1V, negative means off
% s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
% s.add('ODT2',0);%DAC value 0-1V, negative means off
% s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
% s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);       %enable this for normal operation
% 
% % Trigger ABL back
% tODTRetTrip = tODTFwdTrip;
s.addStep(@ABLTransfer);
% s.wait(tODTRetTrip);
% s.wait(500e-3);
% s.add('VctrlCoilServo6',0.5);         %turn off  quant field coil
% s.add('VctrlCoilServo5',0.5);         %turn off  fastB field coil
% s.addStep(@fbCoilRampOn, 0, 10e-3);           %turn off Feshbach coill
% s.add('TTLuwaveampl',0);
% s.add('TTLValon', 0);         %trigger Valon synthesizer for preparing high B ARP, 0 = lowB ARP, 1 = HighB ARP;
% %%---------set memory map----------------------
% m = MemoryMap;
% m.Data(1).TOFRb = TOFRb;
% m.Data(1).TOFK = TOFK;
% m.Data(1).trapID = trapID;
% if ~exist('VODTtransf1','var')
%     VODTtransf1 = 0;
% end
% m.Data(1).VODTtransf1 = VODTtransf1;
% if ~exist('VODT1','var')
%     VODT1 = 0;
% end
% m.Data(1).VODT1 = VODT1;
% if ~exist('VODT2','var')
%     VODT2 = 0;
% end
% m.Data(1).VODT2 = VODT2;
% %% --------------K and Rb MOT-----------
% s.add('TTLscope',0); %trigger oscilloscope
% s.addStep(@MakeRbMOT);
% s.addStep(@MakeKMOT);
% 
% %% -------------Turn things off at the end of a script-----------
% VPS = 0.0; %set the QUIC trap P/S voltage
% s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

s.run();
end