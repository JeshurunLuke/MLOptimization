function MakeNaMOT
%Make a Na MOT and leave it there.

s = ExpSeq();

s.add('TTLpiezomirror', 0);
s.add('AmpNaEOMHalf', .5);
s.add('FreqNaEOMHalf', 880.5e6);
s.add('AmpNaResDP', 0.5);
s.add('FreqNaResDP', 74e6);
s.add('AmpNaMOT', 0.15);
s.add('FreqNaMOT', 80e6);
s.add('AmpNaLockDP', 1);
s.add('FreqNaLockDP', 120e6);
 s.add('VBShimX', -.1);
 s.add('VBShimY', -4.5);%s.add('VBShimY', -2);
 s.add('VBShimZ', 1);

s.add('VMOTCur', -9);
s.add('TTLMOTShutter', 1);

s.run();