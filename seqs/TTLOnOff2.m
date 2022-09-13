function s = TTLOnOff2(x)

s = ExpSeq();

IfbCoil = 197.20;

VfbCoil = - IfbCoil/s.C.FeshbachCoilIV;
% VfbCoil = - IfbCoil/s.C.TransferCoilIV;

s.addStep(500e-3) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil));

s.wait(500e-3);

for i = 1:200
s.addStep(1e-3)...
    .add('TTLMCP',1);

s.addStep(1e-3)...
    .add('TTLMCP',0);

s.addStep(0.5)...
    .add('TTLMCP',1);
end

s.addStep(10e-3) ...
    .add('VctrlCoilServo4', rampTo(0.5));

s.run();

end