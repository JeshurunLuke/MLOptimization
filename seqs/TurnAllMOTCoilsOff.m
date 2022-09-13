function s = TurnAllMOTCoilsOff()

s = ExpSeq();

s.add('VctrlCoilServo1', 1.0);
s.add('VBOptPump', 0.0);
s.add('VBShimZ', 0.0);
s.add('VBShimY', 0.0);
s.add('VBShimX', 0.0);

s.run();
end