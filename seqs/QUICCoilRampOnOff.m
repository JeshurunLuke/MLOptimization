 function s = QUICCoilRampOnOff()

s = ExpSeq();

s.wait(0.5);

s.addStep(@QUICLoad);
s.wait(0.5);
s.addStep(@QUICTrapOff);

s.wait(0.5);

  s.run();
end