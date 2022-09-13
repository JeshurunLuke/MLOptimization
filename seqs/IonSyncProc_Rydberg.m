function IonSyncProc_Rydberg(s1)
% IonSyncProc(s1, tYagDelay, tExcite, period)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tYagDelay','var'))
    tYagDelay = 180e-6; %was 170us
end

if(~exist('tExcite','var'))
    tExcite = 15e-6;%[s] was 2 us
end

if(~exist('period','var'))
    period = 0.1;%[s]
end
T1 = 10e-3; %time for turning HV off

% % This will be added later in the background 10Hz step to happen
% % between ionStart and ionEnd Make sure the step is shorter than 100ms
% tOn = tYagDelay - tExcite;
%
% s.addStep(tOn)...
%     .add('TTLODT1',1); %Now on ODT1
% s.addStep(tExcite)...
%     .add('TTLODT1',0)...
%     .add('TTLscope',1);
% s.addStep(period - tYagDelay) ...
%     .add('TTLODT1',1);


%%The following are for switching HV  %%%%%%%%%%%%%%
tExcite = 8e-6;%[s] was 2 us
tYagDelay = 170e-6; %was 170us
tOn = tYagDelay - tExcite;
s.addStep(tOn)...
    .add('TTLODT1',1)...        %Now on ODT1 (Vertical ODT
    .add('TTLODT2',1);     %Now on ODTtransf (Vertical ODT

%% turn off ODT for Rydberg excitation
s.add('TTLODT1',1);
s.add('TTLODT2',1);
s.add('TTLscope',1);
s.wait(tExcite);            %after waiting, UV pulse on

dtpulse = 5*1.0e-6;        %Time delay from UV pulse on to ODT on, measured through scope
tHVon1 = 1.0e-6;           %time interval between the UV pulse rising edge and HV1 on command
tHVon2 = (tHVon1+32.0e-6);    %time interval between the UV pulse rising edge and HV2 on command

if(tHVon2 <= tHVon1)
    error('tHVon2 should > tHVon1');
end
if ((tHVon1 < dtpulse) && (tHVon1 > 0))
   s.wait(tHVon1);
    s.add('TTLHVswitch1', 1);
    if (tHVon2 < dtpulse)
        s.wait(tHVon2-tHVon1);
%         s.add('TTLHVswitch2', 1);
        s.wait(dtpulse - tHVon2);
        s.add('TTLODT1', 1);
        s.add('TTLODT2',1);
        s.addStep(T1 - tYagDelay - dtpulse);
    elseif (tHVon2 == dtpulse)
        s.wait(tHVon2-tHVon1);
%         s.add('TTLHVswitch2', 1);
        s.add('TTLODT1', 1);
        s.add('TTLODT2',1);
        s.addStep(T1 - tYagDelay - dtpulse);
    else
        s.wait(dtpulse - tHVon1);
        s.add('TTLODT1', 1);
        s.add('TTLODT2',1);
        s.wait(tHVon2-dtpulse);
%         s.add('TTLHVswitch2', 1);
        s.addStep(T1 - tYagDelay -tHVon2);
    end
elseif (tHVon1 == dtpulse)
    s.wait(tHVon1);
    s.add('TTLHVswitch1', 1);
    s.add('TTLODT1', 1);
    s.add('TTLODT2',1);
    s.wait(tHVon2-tHVon1);
%     s.add('TTLHVswitch2', 1);
    s.addStep(T1 - tYagDelay -tHVon2);
elseif (tHVon1 > dtpulse)
    s.wait(dtpulse);
    s.add('TTLODT1', 1);
    s.add('TTLODT2',1);
    s.wait(tHVon1 - dtpulse);
    s.add('TTLHVswitch1', 1);
    s.wait(tHVon2-tHVon1);
%     s.add('TTLHVswitch2', 1);
    s.addStep(T1 - tYagDelay - tHVon2);
else
    error('tHVon need > 0');
end


%% turn the HV switch back off
s.addStep(period-T1)...
    .add('TTLHVswitch1', 0);
%     .add('TTLHVswitch2', 0);




if s.totalTime() > period
    error('10Hz pulse too long.');
end
if s.totalTime() < period
    error('10Hz pulse too short.');
end

if(~exist('s1','var'))
    s.run();
end

end
