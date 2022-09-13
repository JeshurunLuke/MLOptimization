 function s = PLLFreqJumpTest()

s = ExpSeq();

fKRepump1 = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6)) / s.C.KRepumpPLLScale;
fKRepump2 = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) - (110e6)) / s.C.KRepumpPLLScale;

s.addStep(1e-3)...
    .add('FreqKMOTRepump', rampTo(fKRepump1))...
    .add('TTLscope',1);

s.wait(100e-3);

s.addStep(1e-3)...
    .add('TTLscope',0)...
    .add('FreqKMOTRepump', rampTo(fKRepump2))...

s.wait(100e-3);

  s.run();
end