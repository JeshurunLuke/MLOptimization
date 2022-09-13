function s = QUICPowerCycling()

s = ExpSeq();

s.addStep(5)...
    .add('CurrProg',0.0);

s.addStep(40)...
    .add('CurrProg',95*20/440);

s.addStep(5)...
    .add('CurrProg',0.0);

  s.run();
end