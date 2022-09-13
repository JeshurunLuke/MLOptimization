function s = TTLOnOff(s1, tYagDelay, tExcite, tOff, period, duration)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tYagDelay','var'))
    tYagDelay = 170e-6;
end

if(~exist('tExcite','var'))
    tExcite = 2e-6;%[s]
end

if(~exist('tOff1','var'))
    tOff = 10e-3;%[s]
end

if(~exist('period','var'))
    period = 0.1;%[s]
end

if(~exist('duration','var'))
    duration = 10;%[s]
end

cycleNum = int64(duration./period);

% if onTime1 >= onTime2
%     error('onTime1 must < onTime2');
% end
%
% if onTime2 >= period
%     error('onTime2 must < period');
% end

tOn = tYagDelay - tExcite;

s.add('TTLRbImagingShutter',1);
s.add('AmpRbOPZeemanAOM', 0.3);

for i = 1:cycleNum
    s.addStep(tOn)...
        .add('TTLbkgd', 1)...
        .add('TTLImgAOMSwitch',0);
    s.addStep(tExcite)...
        .add('TTLbkgd', 1)...
        .add('TTLImgAOMSwitch',1);
    s.addStep(tOff - tYagDelay) ...
        .add('TTLbkgd', 1)...
        .add('TTLImgAOMSwitch', 0);
    s.addStep(period - tOff) ...
        .add('TTLbkgd', 0)...
        .add('TTLImgAOMSwitch', 0);
end

s.add('TTLRbImagingShutter',0);
s.add('AmpRbOPZeemanAOM', 0.0);

if(~exist('s1','var'))
    s.run();
end
end