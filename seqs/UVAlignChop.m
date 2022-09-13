function s = UVAlignChop(x)

s = ExpSeq();

s.addStep(1e-6)...o
    .add('TTLbkgd',1);

s.wait(5);

s.addStep(1e-6)...
    .add('TTLbkgd',0);

s.run();

end