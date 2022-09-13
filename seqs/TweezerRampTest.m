function s = TweezerRampTest()


s = ExpSeq();

s.add('TTLtweezerRFsw',1);
s.add('VTweezer',2);
s.add('AmpTiSapph',1);

s.wait(100e-6);


s.add('AmpTiSapph',0);
s.add('VTweezer',0);
s.add('TTLtweezerRFsw',1);

s.wait(20e-6);

s.add('AmpTiSapph',0.6);
s.add('VTweezer',2);
s.add('TTLtweezerRFsw',1);

% s.addStep(2e-6) ...
%     .add('VTweezer',2) ...
%     .add('AmpTiSapph',linearRamp(0.5,0.55));

s.wait(100e-6);

s.add('VTweezer',0);
s.add('AmpTiSapph',1);
s.add('TTLtweezerRFsw',1);


s.run();