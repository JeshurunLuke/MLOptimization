function s = UVexposure(s1, tIonUVExp)
%% ----- Ionization sequence-----------
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
if(~exist('tIonUVExp','var'))
    tIonUVExp = 0.5;    %[s]  Please also change "edgeWaveBurst.m" correspondently.
end

s.addStep(tIonUVExp)...
    .add('TTLionShutter', 1)...
    .add('TTLbkgd', 1)...
    .add('TTLHVswitch1', 1);

s.wait(1e-6);
s.add('TTLionShutter', 0);
s.add('TTLbkgd', 0);
s.add('TTLHVswitch1', 0);

end
