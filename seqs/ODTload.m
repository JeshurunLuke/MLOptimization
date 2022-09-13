function s = ODTload(s1,tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 125e-3;%[s]
end

% s.add('ODT1',0.001);
s.add('TTLODT1',1); %Turn on RF switch
s.add('ODT1',0.001);
% s.add('TTLscope',1);

tRailing = 25e-3;      %servo railing time
tRampEff=tRamp-tRailing;    %effective ramptime
s.wait(tRailing);
VODT = 3.0;%3 corresponds to 3.66W for Gain=30dB
s.addStep(tRampEff) ...
    .add('ODT1', rampTo(VODT));

% s.add('TTLscope',0)
% s.wait(5000e-3);
% s.add('TTLODT1',0); %Turn off RF switch
% s.add('ODT1',-0.5);

if(~exist('s1','var'))
    s.run();
end

end