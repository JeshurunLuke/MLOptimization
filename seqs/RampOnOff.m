 function s = RampOnOff()

s = ExpSeq();

s.addStep(5.0)...
    .add('GenericChn1',5);

s.addStep(30.0)...
    .add('GenericChn1',0);

s.run();
end