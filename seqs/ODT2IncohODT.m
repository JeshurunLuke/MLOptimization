function s = ODT2IncohODT(s1,tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 35e-3;%[s]
end

VODT2 = 3.0; % Corresponding to 4.87 W (11/28/2017)
VODT1 = 0.0;

tRailing = 25e-3;      %servo railing time
tRampEff=tRamp-tRailing;    %effective ramptime

s.add('TTLODT2',1); %Turn on RF switch for ODT2
s.add('ODT2',0.001);
s.wait(tRailing);

s.addStep(tRampEff) ...
    .add('ODT1', rampTo(VODT1))...
    .add('ODT2', rampTo(VODT2));

if(~exist('s1','var'))
    s.run();
end

end