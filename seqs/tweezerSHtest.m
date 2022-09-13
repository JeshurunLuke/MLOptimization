function s = tweezerSHtest(tOFF)
tOFF=tOFF*1e-6;
s = ExpSeq();



ampTweez0=.8;%2; %don't ever go outside 0-6V
tON=100e-3;
%tOFF=3e-6;

s.addStep(1e-6)...
    .add('TTLtweezerRFsw',1)...
    .add('TTLtweezerSnH',0);


s.addStep(@modulateAO, 0,tON,0, ampTweez0);

s.addStep(tOFF)...
     .add('TTLtweezerRFsw',0)...
     .add('TTLtweezerSnH',1);

 s.addStep(1e-6)...
     .add('TTLtweezerSnH',0)...
     .add('TTLtweezerRFsw',1);



s.wait(tON);

%dump tweezer
s.addStep(@modulateAO, 0,1e-6,0, 0);


s.run();
