function s = ionSyncTest(x)

s = ExpSeq();

s.wait(1);
ionStart = s.curTime;
s.addStep(1)...
    .add('TTLscope',1);
ionEnd = s.curTime;
s.wait(1);

s.add('TTLscope',0);

%% ------------Generate a background 10Hz TTL ----------------
s.waitAll();
% Make sure we don't start this before time 0.
seqlen = s.totalTime();
function background10Hz(s, len)
    offset = 0;
    freq = 10;
    period = 1./freq; %0.1
    onTime = period./2;
    s.wait(mod(ionStart + offset, period));
    while s.totalTime() < len
        cycleStart = s.totalTime();
%         Add anything that is to be synced with the ionization pulses
        if cycleStart > ionStart && cycleStart < ionEnd
%             s.addBackground(@IonSyncProc); %% Shorter than 100ms
        end
        s.addStep(onTime) ...
            .add('TTLbkgd', 1);
        s.addStep(period - onTime) ...
            .add('TTLbkgd', 0);
    end
end
s.addAt(startTime(s), @background10Hz, seqlen);

end