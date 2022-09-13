function s = mainODTroundtripTransfer(x)

s = ExpSeq();

m = MemoryMap;

%% ------Add dummy pulse to trigger the NIDAQ----------
% s.addStep(1e-3)...
%     .add('XLN3640VP', linearRamp(0, 1))...
%     .add('Dummy1', linearRamp(0, 1));

%% ------Default camera triggers----------
s.add('TTLscope',0);
VPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);
s.add('TTLKGMShutter',0);   %Close shutter

%%
% Turn Transfer ODT 60 MHz power ON
% s.add('TTLODTtransf',1);%TTL switch ON/off ODT, 1 means on
s.add('AmpTransfODTAOM2', 0.5);
s.add('TTLODTtransf',0);

%% -----------------Rb MOT----------
% disp('MOT stage...');
s.addStep(@MakeRbMOT);
s.addStep(@MakeKMOT);
t1=2;%[s] old value 10 s; old value 2.5 s
s.wait(t1);%wait for t1 at Rb MOT stage


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
m = MemoryMap;
m.Data(1).trapID = 1;
s.wait(500e-3); %Hold the atoms in the QUIC trap for some time

%% --------------Evaporate inside the QUIC trap -------------
s.addStep(@RFevap2);
% s.addStep(@uwaveEvap3);
s.wait(500e-3); % 500e-319

% %%--------- Load in transfer ODT--------------
VODTtransf1 = 1.5;          %1.6W/V see 5/25/2018
s.add('TTLODTtransf',1);             %TTL switch ON/off ODT, 1 means on
s.addStep(@QUIC2ODT,500e-3,VODTtransf1);%
m.Data(1).trapID = 2;
m.Data(1).VODT = VODTtransf1;
s.wait(0.5);

%% -------Forward ODT transfer---------
Ratio4f = 2.4;
Pquic = 55.0;
PIntOffset = 0./Ratio4f;    % If stageNum > 1, put in PIntOffset;
TransDist = 20;             % [mm] transfer distance of ODT
PScienceOffset = TransDist/Ratio4f; %316.4/2.727;
Vel1 = 10;                  %velocity of ABL cart for stage 1
Vel2 = 200;                 %velocity of ABL cart for stage 2, inactive if stageNum = 1
ARate = 1;                % Acceleration of ABL cart
DRate = 1;                % deceleration of ABL cart
stageNum = 1;               % If stageNum > 1, put in PIntOffset;
ABLTrajPlotFlag = 1;    %0 mean not plot, 1 means plot
tODTFwdTrip = ABLTripTime(Ratio4f,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag);
disp(['tODTFwdTrip = ', num2str(tODTFwdTrip), ' s']);

% Trigger ABL forward
s.add('TTLscope',1);
s.addStep(@ABLTransfer);
s.wait(tODTFwdTrip);
s.wait(1500e-3);
% Trigger ABL back
tODTRetTrip = tODTFwdTrip;
s.addStep(@ABLTransfer);
s.wait(tODTRetTrip);
s.addStep(150e-3)...
    .add('Vquant3', rampTo(0));
s.wait(1);

% % %% --------------TOF imaging-----------
TOFRb = 5.0e-3;% TOFRb or TOFK needs to be bigger than texpcam200/2+tid=105.6usTOFK =0.5e-3;%
TOFK = 3e-3;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
s.addStep(@preimaging, 25.33e6, 0, 34.7e6, 0);
% s.add('Vquant2',0);         %turn off the small transfer quant field coil
s.add('Vquant3',0);         %turn off the large transfer quant field coil
s.addStep(@QuantFieldOn);
s.wait(ShutterDelay);

%% ---------Turn off ODT---
s.add('ODTtransf',0);%DAC value 0-1V, negative means off
s.add('TTLODTtransf',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT1',0);%DAC value 0-1V, negative means off
s.add('TTLODT1',0);%TTL switch ON/off ODT, 1 means on
s.add('ODT2',0);%DAC value 0-1V, negative means off
s.add('TTLODT2',0);%TTL switch ON/off ODT, 1 means on
s.addStep(@imagingTOF, TOFRb, TOFK);        %enable this for normal operation

s.addStep(@fbCoilRampOn,0,10e-3);           %turn off Feshbach coill
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