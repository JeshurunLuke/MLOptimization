function s = MOTRecapture()

% Release time
TRelease = 100e-3;

% MOT Parameters
DetMOT = -10e6;
IMOT = 15.0;
VShimMOT = [-4.0, 0, 0, 1.5];
AmpRbRepumpMOT = 0.090;
TLoadMOT = 5.0;
MOTShutterDelay = 2.6e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/14/16

% Initialize sequence
s = ExpSeq();

%Load MOT
s.addStep(@SetRbLasersAndB,...
    1, DetMOT, IMOT, VShimMOT, AmpRbRepumpMOT, TLoadMOT);

%Release MOT
s.addStep(MOTShutterDelay) ...
    .add('TTLMOTTelescopeShutter', 0);

s.addStep(@SetRbLasersAndB, 0, DetMOT, -15, 0, AmpRbRepumpMOT, TRelease);

%Recapture MOT
s.addStep(MOTShutterDelay) ...
    .add('TTLMOTTelescopeShutter', 1);

s.addStep(@SetRbLasersAndB,...
    1, DetMOT, IMOT, VShimMOT, AmpRbRepumpMOT, TLoadMOT);

  s.run();
end
