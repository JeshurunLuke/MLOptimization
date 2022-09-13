function s = setstuff

s = ExpSeq();

DetMOT = -7.5e6;%-10e6; %MOT detuning
VBMOT = 2.46; %Main MOT coil control voltage
VShimMOT =[ 0.01 -0.32 +0.35];

AmpCsCoolMOT = 0.10;
AmpCsRepumpMOT = 0.005;

s.addStep(@SetCsLasersAndB, DetMOT, VBMOT, VShimMOT, AmpCsCoolMOT,AmpCsRepumpMOT,10e-6);


s.run();

%runSeq(@paramheat,1,{100e3})

end

