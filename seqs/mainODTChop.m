function s = mainODTChop()

s = ExpSeq();

%% ------ Ionization pulse timing control -----------
tUVShtrOffDelay = 0e-3;
tUVShtrOnDelay = 4e-3; %was 40e-3
tUVShtrSkip = 4e-3;
tUVShtrMinOn = 4e-3;
% For more info see comments in TTLMgr
s.addOutputMgr('TTLionShutter', @TTLMgr, ...
    tUVShtrOffDelay, ... % The time it takes to react to channel turning off 
    tUVShtrOnDelay, ... % The time it takes to react to channel turning on 
    tUVShtrSkip, ... % Minimum off time. Off interval shorter than this will be skipped.
    tUVShtrMinOn); % Minimum on time. On time shorter than this will be extended
%% 
% s.wait(10);

VODT1 = 0.119.*1.3;
VODT2 = 0.400;

% VODT1 = 0;
% VODT2 = 0;

s.addStep(100e-3)...
    .add('TTLODT1',1)...
    .add('TTLODT2',1)...
    .add('ODT1',rampTo(VODT1))...
    .add('ODT2', rampTo(VODT2));
s.add('TTLscope',0);    
% s.wait(1);

% s.add('TTLscope',1);

%%
% s.add('TTLionShutter', 1);
% 
% tIonUVExp = 1;
% 
% repRate = 7000;
% numCycle = repRate.*tIonUVExp;
% tOn = 41e-6;
% tUVTrig = 71e-6 - tOn;
% tOff = 72e-6;
% LL = 2;
% 
% for i = 1:numCycle
%     s.addStep(tOn)...
%         .add('ODT1',(2-LL)*VODT1)...
%         .add('ODT2',(2-LL)*VODT2);
%     s.addStep(tUVTrig)...
%         .add('TTLbkgd',1);
%     s.addStep(tOff)...
%         .add('ODT1',LL*VODT1)...
%         .add('ODT2',LL*VODT2)...
%         .add('TTLbkgd',0);
% end
% 
% s.addStep(10e-6)...
%     .add('ODT1', rampTo(VODT1))...
%     .add('ODT2', rampTo(VODT2));

%%
tIonUVExp = 1; % [s]  Please also change "edgeWaveBurst.m" correspondently.
% f = (1/2000)/(1/2000 - 350e-6);
f = 2;

if tIonUVExp == 0
    s.add('TTLionShutter', 0);
else
    s.addStep(tIonUVExp)...
        .add('TTLscope',1)...
        .add('TTLHVswitch1',1)...
        .add('TTLionShutter', 1)...
        .add('TTLbkgd', 1)...           %trigger Agilent func gen.
        .add('ODT1',f*VODT1)...
        .add('ODT2',f*VODT2);
end
s.wait(1e-6);
s.add('TTLionShutter', 0);
s.add('TTLbkgd', 0);
s.add('TTLHVswitch1',0);
s.add('ODT1',VODT1);
s.add('ODT2',VODT2);

s.add('ODT1',0);
s.add('ODT2',0);
s.add('TTLODT1',0);
s.add('TTLODT2',0);
s.add('TTLscope',0);

% s.wait(48);

s.run

end