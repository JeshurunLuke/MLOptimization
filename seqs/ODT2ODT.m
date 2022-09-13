function s = ODT2ODT(s1,tRamp, VODT1)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 10e-3;%[s]
end
if ~exist('VODT1','var')
    error('Please assign ODT1 power!');
end
% VODT2 = 3.5; % Corresponding to 4.87 W (11/28/2017)
VODTtransf = 0;

tRailing = 25e-3;      %servo railing time
tRampEff=tRamp-tRailing;    %effective ramptime

s.add('TTLODT1',1); %Turn on RF switch for ODT1
s.add('ODT1',0.001);
s.wait(tRailing);

s.addStep(tRampEff) ...
    .add('ODTtransf', rampTo(VODTtransf))...
    .add('ODT1', rampTo(VODT1));

% s.addStep(tRampEff) ...
%     .add('ODT1', rampTo(VODT1));
% s.addStep(500e-3)...
%     .add('ODTtransf', rampTo(VODTtransf));

s.add('TTLODTtransf',0); %Turn off RF switch for transfer ODT

if(~exist('s1','var'))
    s.run();
end

end