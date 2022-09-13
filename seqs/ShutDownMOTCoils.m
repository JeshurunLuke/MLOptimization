function s = ShutDownMOTCoils()
%Sets DAC voltages to control MOT and shim fields to 0.

% Initialize the sequence
s = ExpSeq();

s.add('VctrlCoilServo1', 1);
s.add('VBOP', 0);
s.add('VBShimX', 0);
s.add('VBShimY', 0);
s.add('VBShimZ', 0);

s.run();

end