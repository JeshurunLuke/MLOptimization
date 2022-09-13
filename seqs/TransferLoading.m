function s = TransferLoading()

%% Steps
% 1. Load Rb MOT;
% 2. Perform optical pumping
% 2. Perform MOT compression (CMOT)
% 3. Perform optical molasses
% 4. Turn off MOT light and ramp up weak quadrupole trap;
% 5. Hold in weak quadrupole trap for t = TFilter to allow atoms in |2,1> to escape;
% 6. Ramp up to strong quadrupole gradient in preparation for transfer;
% 7. Transfer the atoms past the differential pumping tube and back;
% 8. Recapture

%% Parameters

% Hold time
THold = 200e-3;

% MOT Parameters
DetMOT = -28e6; %-10.0
IMOT = 20.0; % 25.0
VShimMOT = [-4.0, 0, 0, 0];
AmpRbRepumpMOT = 0.090;
TLoadMOT = 2.0; % MOT loading duration
MOTShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16

% CMOT Parameters
DetCMOT = -20e6;
ICMOT = 30.0;
VShimCMOT = [-3.0, 0.0, 0.0, 0.5]; %(Roughly optimized 02/23/16)
AmpRbRepumpCMOT = 0.0030; %(Roughly optimized 02/23/16)
TCMOT = 50e-3; % CMOT duration (Roughly optimized 02/23/16)

% Molasses Parameters
DetMolasses = -40e6;
VShimMolasses = [-0.25, -4.0, -2.5, -0.100];
AmpRbRepumpMolasses = 0.030;
TMolasses = 20e-3; % MOT loading duration

% Optical Pumping Parameters
DetOPZeeman = -2e6;
VBOP = 5.0; % Positive value yields the correct quantization field direction, optimized for recaptured fraction as of 03/01/16
VShimOP = [VBOP, -5.0, 0.0, 0.0];
AmpRbOPZeemanAOM = 0.100;
AmpRbOPRepumpAOM = 0.250;
TOPDuration = 0.50e-3; % Optical pumping duration
TOPtoQLoad = 0.1e-3; % Wait time between end of optical pumping and beginning of weak quadrupole field ramping
OPShutterDelay = 2.6e-3;

% Transfer Coil Parameters
IWQuadField = 60.0 ;
TWQuadRamp = 20.0e-3; % ramp time shorter than 20 ms results in significant overshoot
TSpinFilter = 200e-3; % time to allow atoms in F = |2,1> to leave the quadrupole trap
ISQuadField = 200.0 ;
TSQuadRamp = 200.0e-3; % ramp time shorter than 100 ms results in significant overshoot

% Transfer Trip Parameters
TTransTrip = 1317e-3;
TTrackTTLOn = 100e-3;

% Fluorescence Imaging Parameters
TExposure = 4.0e-3; % Imaging Exposure Time

%% Initialize sequence
s = ExpSeq();

%% Load MOT
s.addStep(@SetRbMOTBeamsAndB,...
    1, DetMOT, IMOT, VShimMOT, AmpRbRepumpMOT, TLoadMOT);

%% Perform CMOT
s.addStep(@SetRbMOTBeamsAndB,...
    1, DetCMOT, ICMOT, VShimCMOT, AmpRbRepumpCMOT, TCMOT);

%% Perform Molasses
% s.addStep(@SetRbMOTBeamsAndB,...
%     1, DetMolasses, -15, VShimMolasses, AmpRbRepumpMolasses, TMolasses);
%
% %% Optical Pumping
% % Turn off MOT light and open OP light shutter
% s.addStep(MOTShutterDelay) ...
%     .add('TTLMOTTelescopeShutter', 0) ...
%     .add('TTLOPShutter', 1);
%
% s.addStep(@SetRbMOTBeamsAndB,...
%     0, DetMOT, -15, VShimOP, AmpRbRepumpMOT, 10e-6);
%
% s.wait(0.1e-3); % wait a bit to make sure that MOT light is completely off
%
% % Turn on optical pump beam AOMs and OP Zeeman field
% s.addStep(@SetRbOPBeamsAndB, ...
%     1, DetOPZeeman, VBOP, AmpRbOPZeemanAOM, AmpRbOPRepumpAOM, TOPDuration);
%
% % Turn off optical pump beam AOMs and OP Zeeman field
% s.addStep(@SetRbOPBeamsAndB, ...
%     0, DetOPZeeman, 0, 0, 0, TOPtoQLoad);

%% Post-Molasses Fluorescence Imaging
s.addStep(MOTShutterDelay) ...
    .add('TTLMOTTelescopeShutter', 1) ...
    .add('VBOP', 0.0) ...
    .add('VBShimX', 0.0) ...
    .add('VBShimY', 0.0) ...
    .add('VBShimZ', 0.0) ...

s.addStep(10e-6) ...
    .add('TTLMOTCCD', 0); % set the camera bit low to trigger a shot

s.addStep(@SetRbMOTBeamsAndB,...
    1, DetMOT, -15, 0, AmpRbRepumpMOT, (TExposure - MOTShutterDelay));

s.addStep(MOTShutterDelay) ...
    .add('TTLMOTTelescopeShutter', 0);

s.addStep(10e-6)...
    .add('TTLMOTCCD', 1); % set the camera bit back to high to wait for next trigger


%% Quadrupole Loading
% Ramp up the weak quadrupole field
s.addStep(@SetTransCoilRamp, IWQuadField, 0, TWQuadRamp);

% Allow atoms in F = |2,1> to leave the quadrupole trap
s.wait(TSpinFilter);

% Ramp up to strong quadrupole field
s.addStep(@SetTransCoilRamp, ISQuadField, 0, TSQuadRamp);

%% Track Transfer
% Trigger the track to transfer forward
s.addStep(TTrackTTLOn) ...
    .add('TTLTrackStart',1);

s.addStep(10e-6) ...
    .add('TTLTrackStart',0); % set the trigger bit back to 0

% Wait for the track to complete the forward transfer
s.wait((TTransTrip - TTrackTTLOn));

% Hold atoms in the strong quadrupole field
s.wait(THold);

% Trigger the track to transfer backward
s.addStep(TTrackTTLOn) ...
    .add('TTLTrackStart',1);

s.addStep(10e-6) ...
    .add('TTLTrackStart',0); % set the trigger bit back to 0

% Wait for the track to complete the backward transfer
s.wait((TTransTrip - TTrackTTLOn));

%% MOT Recapture
s.addStep(MOTShutterDelay) ...
    .add('TTLMOTTelescopeShutter', 1);

s.addStep(@SetRbMOTBeamsAndB,...
    1, DetMOT, IMOT, VShimMOT, AmpRbRepumpMOT, TLoadMOT);

%% In-Qtrap Fluorescence Imaging
% s.addStep(MOTShutterDelay) ...
%     .add('TTLMOTTelescopeShutter', 1);
%
% s.addStep(10e-6) ...
%     .add('TTLMOTCCD', 0); % set the camera bit low to trigger a shot
%
% s.addStep(@SetRbMOTBeamsAndB,...
%     1, DetMOT, ISQuadField, 0, AmpRbRepumpMOT, (TExposure - MOTShutterDelay));
%
% s.addStep(MOTShutterDelay) ...
%     .add('TTLMOTTelescopeShutter', 0);
%
% s.addStep(10e-6)...
%     .add('TTLMOTCCD', 1); % set the camera bit back to high to wait for next trigger
%
% s.addStep(10e-6)...
%     .add('VctrlCoilServo1', 1.0) ... % Turn off the quadrupole trap

%%
  s.run();
end

%% Old parameters

% For total MOT beam power of 120 mW
% CMOT Parameters
% DetCMOT = -10e6;
% ICMOT = 15.0;
% VShimCMOT = [0.0, 8.0, -10.0, -3.0]; %(Roughly optimized 02/16/16)
% AmpRbRepumpCMOT = 0.0025; %(Roughly optimized 02/16/16)
% TCMOT = 10e-3; % CMOT duration (Roughly optimized 02/16/16)

% For total MOT beam power of 250 mW
% CMOT Parameters
% DetCMOT = -10e6;
% ICMOT = 25.0;
% VShimCMOT = [0.0, 8.0, -10.0, 1.0]; %(Roughly optimized 02/23/16)
% AmpRbRepumpCMOT = 0.0030; %(Roughly optimized 02/23/16)
% TCMOT = 15e-3; % CMOT duration (Roughly optimized 02/23/16)

% Optical Pumping Parameters (before 03/01/16)
% DetOPZeeman = 0e6;
% VBOP = 5.0; % Positive value yields the correct quantization field direction, as of 02/16/16
% VShimOP = [VBOP, 0.0, 0.0, 0.0];
% AmpRbOPZeemanAOM = 0.100;
% AmpRbOPRepumpAOM = 0.250;
% TOPDuration = 1.0e-3; % Optical pumping duration
% TOPtoQLoad = 0.1e-3; % Wait time between end of optical pumping and beginning of weak quadrupole field ramping
% OPShutterDelay = 2.6e-3;
