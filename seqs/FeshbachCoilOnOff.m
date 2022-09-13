function s = FeshbachCoilOnOff()

s = ExpSeq();

% s.add('TTL2GHzRF',1);
s.add('TTLscope',0);

BFR1 = 550;        %[G]
tFR1 = 10e-3;
IFR1 = BFR1./s.C.FeshbachGperAHB;
s.addStep(@fbCoilRampOn,IFR1,tFR1);

s.add('TTLscope',1);
s.wait(200e-3);

BFR2 = 400.0;        %[G]
tFR2 = 10e-3;
IFR2 = BFR2./s.C.FeshbachGperAHB;
s.addStep(@fbCoilRampOn,IFR2,tFR2);
% s.wait(1);
% s.add('TTL2GHzRF',0);
s.wait(200e-3);

BFR3 = 0.0;        %[G]
tFR3 = 1e-6;
IFR3 = BFR3./s.C.FeshbachGperAHB;
s.addStep(@fbCoilRampOn,IFR3,tFR3);

s.wait(10e-3);
% s.add('TTL2GHzRF',1);
s.add('TTLscope',0);

s.run();
end