function s = rnr()

% Initialize the sequence

s = ExpSeq();

release_tweezer = 0;
release_MOT = 1;

AndorPeriod1 = 1e-6; % 7.6e-3;
AndorExp1 = 10e-3; % image1 / pgc1 time
AndorExp2 = 10e-3; % image2 / pgc2 time

AndorPeriod2 = .4; % min time b / t andor image sets

DETMOT = 10;
motv = 2.46;
shimvMOT = [0.0, -0.43, .3]; % 0.0, -0.43, .3
amp_coolMOT = .08; % 0.08;
amp_rpMOT = .001; % 0.001;
tLoadMOT = 1.5;

DETPGC = 30; % 13; % 30; % 140;
shimvPGC = shimvMOT;
amp_coolPGC = amp_coolMOT;
amp_rpPGC = amp_rpMOT;

TOFMOT = 40e-3;
TOFtweez = 20e-6;
tweezAmp = 0.9;

% The default values are listed in expConfig.m.  Any values not explicitly
% specified at the beginning of the sequence are set to the default values
% specified in expConfig.  If a default value is not specified in the
% config file, then it will be set to 0.  Every sequence updates all TTL
% channels.

% Specify initial values.  Channel names are defined in the config file.
% before the first clock pulse all channels will take their default value
% according to nacsConfg, if not specified they will all (incl freqs, amps)
% set to zero.

s.add('TTL27', 1);
% Use TTL27 as a trigger to indicate the start of the sequence, so wait 10
% us and then turn back off.
s.wait(10e-6);
s.add('TTL27', 0);

% Wait 100 us
s.wait(100e-6);

% start------------------------------
% load mot, tweezer on, expose
s.add('AmpTiSapph', tweezAmp);
s.addStep(@loadMOT, DETMOT, motv, shimvMOT, ...
          amp_coolMOT, amp_rpMOT, tLoadMOT);

s.add('TTLAndor', 1);
s.wait(AndorExp1); %%%%%%%%%%%%%
s.add('TTLAndor', 0);

% release, wait
if release_MOT
    s.addStep(@PGC1, DETPGC, shimvPGC, 0, 0, TOFMOT);
end

%rnr tweezer
if release_tweezer
    s.addStep(@PGC1, DETPGC, shimvPGC, 0, 0, TOFtweez) ...
     .add('AmpTiSapph', 0);
    s.add('AmpTiSapph', tweezAmp);
end

s.addStep(@PGC1, DETPGC, shimvPGC, 0, 0, AndorPeriod1);

%take pic
s.add('TTLAndor', 1);
s.addStep(@PGC1, DETMOT, shimvPGC, amp_coolMOT, amp_rpMOT, AndorExp2);
s.add('TTLAndor', 0);

%dump tweezer
s.addStep(@PGC1, DETPGC, shimvPGC, 0, 0, 10e-3) ...
 .add('AmpTiSapph', 0);
s.add('AmpTiSapph', tweezAmp);


%return to mot loading condition
s.addStep(@loadMOT, DETMOT, motv, shimvMOT, amp_coolMOT, amp_rpMOT, 1e-6);

s.run();

end
