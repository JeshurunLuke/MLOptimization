function s = mainHybridTrapTransfer(x)

s = ExpSeq();

%% ------Default camera triggers----------
s.add('TTLscope',0);
VQUICPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VQUICPS/s.C.XLN3640VPConst);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
t1=2;%[s] old value 10 s; old value 2.5 s(m
s.wait(t1);%wait for t1 at Rb MOT stage
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
fcut1 = 4;  % [MHz]
% s.addStep(@HybridRFevap1, tevap1);
s.addStep(@hybriduwaveEvap1, tevap1, fcut1);
s.addStep(@HybridRFevap2, tevap2, tBramp1, fcut1);       %tBramp should > tevap2, ODT loading
s.wait(1e-3);
% s.addStep(@QUICTrapOff,1e-3);      %turn off the Quadruple trap, takes 1 ms
s.addStep(@QUICTrapRampOff,100e-3);
s.addStep(500e-3)...
    .add('ODT1',rampTo(4));
% s.add('TTLscope',1);
s.wait(500e-3);

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
ABLTrajPlotFlag = 0;    %0 mean not plot, 1 means plot
tODTFwdTrip = ABLTripTime(Magnification,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
% tODTFwdTrip = 1011.*1e-3;
s.addStep(@ABLTransfer);

Ifield1 = 0.1;
Ifield2 = 0.3;
VperA=1/0.54;   %[V/A]Volt per amp
Vfield1 = Ifield1*VperA;
Vfield2 = Ifield2*VperA;
s.addStep(500e-3)...
    .add('Vquant3', rampTo(Vfield1));
s.wait(1e-3);
s.addStep(tODTFwdTrip-500e-3)...
    .add('Vquant3', rampTo(Vfield2));
s.wait(500e-3);

%% --------------Transfer from ODT1 to ODT2 (static) -----------
s.add('TTLscope',1);
s.addStep(@ODT2ODT);
s.wait(500e-3)
% s.addStep(@ODT2Evap);
% s.wait(500e-3);

%% ==== Science chamber imaging Feshbach coil parameters
BSciImgFld = 19.84;
ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
tSciImgFld = 1e-3;              % Ramp on time for the science chamber imaging field
s.addStep(@fbCoilRampOn,ISciImgFld,tSciImgFld);
s.wait(20e-3);
% s.wait(20);

%% --------------TOF imaging in evap chamber-----------
TOFRb = 3e-3;% TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 20.0e-3;%
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
% m.Data(1).flagCam=1;
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% s.addStep(@preimaging,2.32e6,x*6.1e6);
s.add('Vquant3',0);         %turn off the large transfer quant field coil
s.wait(4e-3);
s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
% s.addStep(@QuantFieldOn);
s.wait(ShutterDelay);
%-------------
s.addStep(@QUICTrapOff,1e-3);      %turn off the QUIC trap, takes 1 ms

%% ---------Turn off ODT---
s.add('ODT1',-1);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',-1);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on

s.addStep(@imagingTOF, TOFRb, TOFK);%enable this for normal operation

%% ----------- trigger ABL back ------------------------
tODTRetTrip = tODTFwdTrip; % Using motion file or ABL_test_3
s.addStep(@ABLTransfer);
s.wait(tODTRetTrip);
s.wait(500e-3);
% s.add('Vquant3',0);
% % s.add('TTLuwaveampl',0)
%% --------------K and Rb MOT-----------
s.add('TTLscope',0); %trigger oscilloscope
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);

%% -------------Turn things off at the end of a script-----------
s.add('XLN3640VP',0);

s.run();
end