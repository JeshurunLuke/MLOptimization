function s = alignOP()
%load MOT, flash OP RP ttl, use molecube to reduce OP RP amplitude.

%% params

%bits
dumpTweezer=1;
blast=1;
Diagnose=1; %0=normal expt; 1=load MOT and keep it.
MolassesLoad=0;
MolassesImg=0;
secondImg=1;

% amps
ampTweez0=0;%2; %don't ever go outside 0-6V
AmpCsCoolMOT = 0.085;%.079;
AmpCsRepumpMOT = .0047; %.0053;

%dets
DetMOT = -7e6;

%voltages
VMOT = -9;
VShimMOT=  -1*[0.02, 1.00, -1.32];

%times
TLoadMOT = 2;
openDelay= 10e-3;
openRise = 6e-3;

%random stuff
fmod=0;

%%
%%%%%%%%%%%%%%%START SEQUENCE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize sequence
s = ExpSeq();
s.add('TTLAndor',0);
%tweezer on
s.addStep(@modulateAO, fmod,10e-6,0, ampTweez0);
%%
%Load MOT
%open MOT shutters, close OP shutters.
%turn on lasers
s.addStep(-openDelay)...
    .add('TTLMOTShutter',1);
s.add('TTLCsMOTRPShutter',0);
s.add('TTLCsMOTCoolShutter',1);
s.add('TTLCsOPRPShutter',1);
s.add('TTLCsOPShutter',0);
s.wait(openRise);

s.addStep(@SetCsLasersAndB,...
    DetMOT, VMOT, VShimMOT, AmpCsCoolMOT, AmpCsRepumpMOT, TLoadMOT);

%flash RP TTL
s.add('TTLCsOPRPShutter',0);

s.run();