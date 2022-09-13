function s = fastBCoilOnOff()

s = ExpSeq();

s.add('TTLscope',0);

BFB1 = 2.0;        %[G]
tFB1 = 1e-3;
IFB1 = BFB1./s.C.FastBCoilGperA;
s.addStep(@fastBCoilRampOn,IFB1,tFB1);

s.wait(10e-3);
s.add('TTLscope',1);

BFB2 = 0.0;        %[G]
tFB2 = 1e-3;
IFB2 = BFB2./s.C.FastBCoilGperA;
s.addStep(@fastBCoilRampOn,IFB2,tFB2);

s.wait(10e-3);
s.add('TTLscope',0);

  s.run();
end