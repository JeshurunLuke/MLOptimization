function s = TestPLLFreqJump(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

s.addStep(@MakeRbMOT);
s.wait(100e-3);

s.add('TTLscope',1);

s.addStep(@MolassesTest);
s.wait(100e-3);

s.add('TTLscope',0);

if(~exist('s1','var'))
    s.run();
end
end