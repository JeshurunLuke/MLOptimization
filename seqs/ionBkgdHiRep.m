function s = ionBkgdHiRep(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

tIonBkgd = 2168827/50000;

s.addStep(tIonBkgd)...
    .add('TTLionShutter', 1)...
    .add('TTLbkgd', 1)...
    .add('TTLHVswitch1', 1);

s.add('TTLionShutter', 0);
s.add('TTLbkgd', 0);
s.add('TTLHVswitch1', 0);

if(~exist('s1','var'))
    s.run();
end

end