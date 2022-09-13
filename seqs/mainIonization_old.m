function s = mainIonization_old(x)

s = ExpSeq();

%% ------Default camera triggers----------
% s.add('TTLscope',0);
VQUICPS = 20.0; %set the QUIC trap P/S voltage
VVMIPS = 0; %set the VMI plates P/S voltage
ShutterDelay = 2.8e-3;
% VMCPFront = 4000;
% VMCPBack = 1500;
% tMCPRamp1 = 2;
% tMCPRamp2 = 2;
s.add('XLN3640VP',VQUICPS/s.C.XLN3640VPConst);
s.add('DACVPS350',VVMIPS/s.C.P350Const);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
s.wait(2);
% s.addStep(@MCPVoltageRampOn,VMCPFront,VMCPBack,tMCPRamp1,tMCPRamp2); %Takes a total of 6s to ramp the MCP to the set voltages
s.add('TTLMOTCCD', 1);% trigger at both rising and falling edge
% s.add('TTLionShutter',1);
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
tFwdTrip = 3409e-3; %updated from 3412e-3 on 05/14/2017; [s]1077ms for 200mm,2551ms for 971.25mm, 3412ms for966.25
s.addStep(@TrackTransfer,tFwdTrip);

%% --------------Load from transfer coil into Qtrap+ODT HybridTrap-----------
tLoad = 500e-3;
% s.add('TTLscope',1);
s.addStep(@HybridTrapLoad,tLoad);  %Total load time = 2 + 2*tLoad [s]

% % %% --------------Backward cart transfer----------
% % s.addStep(@TrackTransfer,tTrackTrig);

%% --------------Backward cart transfer----------
tTrackTrig = 1e-3;
s.addStep(@TrackTransfer,tTrackTrig);

%% ------------Evap in QUIC Quad & ODT loading----------
tevap1 = 17;   %[s]
tevap2 = 2;   %[s]
tBramp1 = 3;    %[s]
% s.addStep(@HybridRFevap1, tevap1);
s.addStep(@hybriduwaveEvap1,tevap1);
s.addStep(@HybridRFevap2, tevap2, tBramp1);       %tBramp should > tevap2, ODT loading
s.wait(1e-3);
% s.addStep(@QUICTrapOff,1e-3);      %turn off the Quadruple trap, takes 1 ms
s.addStep(@QUICTrapRampOff,100e-3);
% s.addStep(500e-3)...
%     .add('ODT1',rampTo(2));
% s.add('TTLscope',1);
% s.wait(500e-3);
% s.wait(5);

%% Turn on the large quantization coil
% Ifield = x;%[A] B=15G, when I=-4.4A ==>Measured B/I=3.4G/A. (calculated B/I=4.2G/A)
% VperA=1/0.54;%[V/A]Volt per amp
% Vfield = Ifield*VperA;
% s.add('Vquant3',Vfield);

%% ------------Evap in QUIC Quad & ODT loading----------
% s.addStep(@ODTEvap);
% s.wait(500e-3);
%
% % s.wait(x)

% % %% ---------u-wave in evaporation chamber-----
% VperA1=1/0.54;%[V/A]Volt per amp
% VperG = VperA1*(-4.8/22);
% B0 = 20;        %[G]  use imaging coil for quantization here
% f0 = (7066.5-(6871-1.8))*1e6;     %[Hz] f = 7066.5- f0
% df = 2*1e6; %%[G] ARP frequency deviation
% dfdt = 2e6/20e-3;   %[Hz/s] ARP ramp rate
% dt = df/dfdt;       %[s] ARP duration
% f1 = (f0-df/2);
% f2 = (f0+df/2);
%
% s.add('Frequwave', f1);
% % s.add('Ampuwave', 0.0);
% s.addStep(10e-3)...
%     .add('Vquant1', rampTo(B0*VperG))...    %turn on imaging quantization coil
%     .add('TTLuwaveampl',1);
% s.wait(100e-3);
% s.add('TTLscope',1);
%
% s.addStep(dt)...
%     .add('Frequwave', rampTo(f2))...
%     .add('Ampuwave',1);
% s.wait(0.001e-3);
% s.add('Ampuwave',0);
% s.add('Frequwave',f1)...
%     .add('TTLuwaveampl',0);
% s.wait(100e-3);


% %----Kill pulse for removing leftover |22> atoms-----
% DetImagingRb = 0*6.1e6;% (19.36 + x.*6.1)*1e6; new resonance 19.36 MHz resonant f=20.6e6 Det=8.8 is the detuning from the F = 2,2 -> F' = 3,3 resonance;
% fRbimaging = 26.798*1e6;  %28.323 [Hz] Zeeman frequency shift due to B field (last updated on 7/17/2017)
% fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - (fRbimaging+DetImagingRb)) / s.C.RbPLLScale;
% s.add('FreqRbMOTTrap', fRb)...
%     .add('TTLRbImagingShutter', 1);
% s.wait(10e-3);
% s.add('AmpRbOPZeemanAOM', 0.3)
% s.wait(10e-3);
% s.add('AmpRbOPZeemanAOM', 0)...
%     .add('TTLRbImagingShutter', 0);
% %%------------------------------------------------
% s.add('Frequwave',f1);
% s.addStep(20e-3)...
%     .add('Frequwave', rampTo(f2))...
%     .add('Ampuwave',0.7);
% % s.wait(0.001e-3);
% % s.add('Ampuwave',0);
% % s.add('Frequwave',f1);
% % s.wait(10e-3);
% % s.addStep(20e-3)...
% %     .add('Frequwave', rampTo(f2))...
% %     .add('Ampuwave',0.7);
%
% s.wait(0.001e-3);
% s.add('Ampuwave',0);
%
% s.wait(10e-3);
% s.add('TTLuwaveampl',0);  %turn off u-wave
% %%%---end of u-wave-----


%% -------Forward ODT transfer---------
Magnification = 2.727;
Pquic = -61.0;
PIntOffset = 20/2.727;
PScienceOffset = 316.4/2.727;
Vel1 = 200;
Vel2 = 230;
ARate = 1000;
DRate = 300;
stageNum = 1;
ABLTrajPlotFlag = 1;
tODTFwdTrip = ABLTripTime(Magnification,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
% tODTFwdTrip = 1011.*1e-3;
s.addStep(@ABLTransfer);
s.addStep(tODTFwdTrip)...
    .add('ODT1',rampTo(4));
% s.add('TTLscope',1);
s.wait(500e-3);
%
% s.wait(x);
%% ====set pushout frequency of Rb=====
% BSciPushFld = 19.84;
% ISciPushFld = BSciPushFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
% tSciPushFld = 1e-3;              % Ramp on time for the science chamber imaging field
% % VperG = -0.0090;              %[V/G] for Feshbach coil
% % BFR = 118.58;                 %[G]
% % s.add('TTLscope',1);
% s.addStep(@fbCoilRampOn,ISciPushFld,tSciPushFld);
% s.wait(20e-3);

s.addStep(@preimaging);  %% set pushout frequency, open up imaging shutter, takes no time
% s.wait(ShutterDelay);
%
% tPushOut = 10.0e-3;
% s.addStep(tPushOut)...
%     .add('TTLImgAOMSwitch',1)...
%     .add('AmpRbOPZeemanAOM', 0.3);
% s.addStep(2e-6)...
%     .add('TTLImgAOMSwitch',0)...
%     .add('AmpRbOPZeemanAOM', 0.0);
%
% s.add('TTLRbImagingShutter',0);
% s.wait(ShutterDelay);

% DetImagingRb = 100*6.1e6;% (19.36 + x.*6.1)*1e6; new resonance 19.36 MHz resonant f=20.6e6 Det=8.8 is the detuning from the F = 2,2 -> F' = 3,3 resonance;
% fRbimaging = 0e6; %28.323 [Hz] Zeeman frequency shift due to B field (last updated on 7/17/2017)
% fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - (fRbimaging+DetImagingRb)) / s.C.RbPLLScale;
% tPushOut = 0.5;
% s.addStep(tPushOut)...
%     .add('FreqRbMOTTrap', fRb)...
%     .add('TTLKGMShutter', 1);
% s.add('TTLKGMShutter', 0);
% s.wait(500e-3);

% % repRate = 10; % [Hz] Rep rate of the ionization laser
tIonExpTot = 15; % [s] time the Rb cloud is exposed to the ionization laser
tIonScopeTrigStart = 0.5; % [s] time the scope start triggering
tScopeLogicOn = 101e-3; % [s] duration of the scope logic sigmal

BIonShftFld = 0.0; % [G] B field to shift the ion position
IIonShftFld = BIonShftFld./s.C.FeshbachGperA;      %[A] B = 19.84 G, Feshbach coil conversionope ratio is 2.5969 G/A
tIonShftFld = 20e-3; % [s] B field to shift the ion position

ionStart = s.curTime;
s.addStep(@preimaging,0e6,30*6.1e6); % detuning the excitation pulses to match the BIonShftFld used
% s.addStep(@preimaging,29.78e6,x*6.1e6);
s.addStep(@fbCoilRampOn,IIonShftFld,tIonShftFld);
s.add('TTLIonLogic',1);
s.add('TTLionShutter',1);
s.add('TTLRbImagingShutter',1);
s.add('AmpRbOPZeemanAOM', 0.25);
s.wait(tIonScopeTrigStart);
s.add('TTLScopeLogic',1);
s.wait(tScopeLogicOn);
s.add('TTLScopeLogic',0);
s.wait(tIonExpTot - tIonScopeTrigStart - tScopeLogicOn);
s.add('TTLRbImagingShutter',0);
s.add('AmpRbOPZeemanAOM', 0.0);
s.add('TTLionShutter',0);
s.add('TTLIonLogic',0);
ionEnd = s.curTime;

%% ===================================

% s.add('AmpRbOPZeemanAOM', 0.3) %0.3
% s.wait(0.075e-3);
% s.add('TTLRbImagingShutter',0);
% s.add('AmpRbOPZeemanAOM', 0);
% s.wait(50e-3);
% s.add('VctrlCoilServo4', 0.5); % Feshbach coil off
% s.wait(50e-3);
% s.wait(x);
% %%trigger ABL back
% tODTRetTrip = tODTFwdTrip; % Using motion file or ABL_test_3
% s.addStep(@ABLTransfer,tODTRetTrip);
% s.wait(500e-3);

%% --------- ODT Parametric Heating ------------
% tDrive = 1;
% AmpV = 0.1;
% Freq = x;
%
% s.add('TTLscope',1);
% s.addStep(@ODTParaHeat,tDrive,AmpV,Freq); % Apply sinusoidal drive for tDrive
% s.wait(500e-3);

%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 19.84;
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 1e-3;              % Ramp on time for the science chamber imaging field
% VperG = -0.0090;              %[V/G] for Feshbach coil
% BFR = 118.58;                 %[G]
% s.add('TTLscope',1);
s.addStep(@fbCoilRampOn,ISciImgFld,tSciImgFld);
s.wait(20e-3);

% s.wait(x);

% s.addStep(@RbRF);       %incldue Rb RF ARP from |22> to |11>


% s.addStep(@RbuwaveARP);
% s.addStep(@Rbkill);     %include Rb u-wave ARP+blasting beam+ u-wave ARP
% s.addStep(@RbRF);       %incldue Rb RF ARP from |22> to |11>

%% ====set pushout frequency of Rb=====
% DetImagingRb = 0*6.1e6;% (19.36 + x.*6.1)*1e6; new resonance 19.36 MHz resonant f=20.6e6 Det=8.8 is the detuning from the F = 2,2 -> F' = 3,3 resonance;
% fRbimaging = 29.06e6; %28.323 [Hz] Zeeman frequency shift due to B field (last updated on 7/17/2017)
% fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - (fRbimaging+DetImagingRb)) / s.C.RbPLLScale;
% s.add('FreqRbMOTTrap', fRb)...
%     .add('TTLRbImagingShutter',0);
% s.wait(10e-3);
% s.add('AmpRbOPZeemanAOM', 0.3);
% s.wait(10e-3);
% s.add('AmpRbOPZeemanAOM', 0);
% s.add('TTLRbImagingShutter',0);
% s.wait(100e-3);
% %%%==============================
% s.add('Frequwave', f1);
% s.addStep(4e-3)...
%     .add('Frequwave', rampTo(f2))...
%     .add('Ampuwave',0.4);
% s.wait(0.001e-3);
% s.add('Ampuwave',0);


%% --------------TOF imaging in evap chamber-----------
TOFRb = 0.5*1e-3;% TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 3e-3;%
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
% m.Data(1).flagCam=1;
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
% s.add('Vquant2',0);         %turn off the small transfer quant field coil
% s.add('Vquant3',0);         %turn off the large transfer quant field coil
% s.addStep(@QuantFieldOn);
% s.addStep(1e-3)...
%     .add('Vquant1', rampTo(22*VperG));
s.wait(ShutterDelay);

%-------------
% s.addStep(@QUICTrapOff,1e-3);      %turn off the QUIC trap, takes 1 ms
% s.addStep(@QuantFieldOn);

% s.totalTime()
%% ---------Turn off ODT---
s.add('ODT1',-1);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on

s.addStep(@imagingTOF, TOFRb, TOFK);%enable this for normal operation

%% ----------- trigger ABL back ------------------------
tODTRetTrip = tODTFwdTrip; % Using motion file or ABL_test_3
s.addStep(@ABLTransfer);
s.wait(tODTRetTrip);
s.wait(500e-3);
% s.add('Vquant3',0);
% % s.add('TTLuwaveampl',0)
%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %reset scope trigger
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
s.add('XLN3640VP',0);
s.add('DACVPS350',0);
% s.add('MCPPSCHA',0);

%% ------------Generate a background 10Hz TTL ----------------
s.waitAll();
% Make sure we don't start this before time 0.
seqlen = s.totalTime() - 0.1;
function background10Hz(s, len)
    period = 0.1; %0.1
    onTime = 0.010;
    while s.totalTime() < len
        cycleStart = s.totalTime();
        % Add anything that is to be synced with the ionization pulses
        if cycleStart > ionStart && cycleStart < ionEnd
            s.addBackground(@IonSyncProc); %% Shorter than 100ms
        end
        s.addStep(onTime) ...
            .add('TTLbkgd', 1);
        s.addStep(period - onTime) ...
            .add('TTLbkgd', 0);
    end
end
s.addBackground(-seqlen, @background10Hz, seqlen);

s.run();
end
