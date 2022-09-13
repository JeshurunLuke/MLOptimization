function s = FreqRampTest(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

fm = 1002.231705e6;
frange = 2*0.2317e6;
fi = fm - frange./2;
ff = fm + frange./2;

tRamp = 1;

s.addStep(1e-3)...
    .add('FreqKMOTTrap',fi);

s.addStep(tRamp./2)...
    .add('FreqKMOTTrap',rampTo(fm));

s.addStep(tRamp./2)...
    .add('TTLscope',1)...
    .add('FreqKMOTTrap',rampTo(ff));

s.add('TTLscope',0);

if(~exist('s1','var'))
    s.run();
end
end