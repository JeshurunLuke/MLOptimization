function s = TransferCoilOnOff()

s = ExpSeq();

s.addStep(1)...
    .add('VctrlCoilServo1',0.5);

s.addStep(500e-3)...
    .add('TTLscope',1)...
    .add('VctrlCoilServo1',rampTo(-320/40));

s.wait(5);

s.addStep(500e-3)...
    .add('TTLscope',0)...
    .add('VctrlCoilServo1',rampTo(0.5));

s.wait(2);

  s.run();
end