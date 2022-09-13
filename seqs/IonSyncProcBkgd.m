function IonSyncProcBkgd(s1)
% IonSyncProc(s1, tYagDelay, tExcite, period)
% more complicated sequency for turning off ODT and HV switch can be found
% in IonSyncProc_Rydberg.m
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tYagDelay','var'))
    tYagDelay = 170.92e-6; %UV pulse delay from t=0, determined by hardware
end

if(~exist('period','var'))
    period = 0.1;%[s]
end
T1 = 10e-3; %time for turning HV off

%%-----------for KRb-------------------
% % turn on HV
% s.addStep(T1)...
%     .add('TTLHVswitch1', 1);
%%----------------------------

%%The following are for MCP and HV switch timing %%%%%%%%%%%%%%
tMCPtrig = -0*1e-6;      % MCP trigger time, in ref to UV pulse, take values of [-170us T1]
tODToff1 = -2e-6;         % Time to turn H ODT off, in ref to UV pulse
tODTon1 = tODToff1 + 5e-6;         % Time to turn H ODT on, in ref to UV pulse
tODToff2 = tODToff1;    %vertical ODT off time, in ref to UV pulse
tODTon2 = tODTon1;      % vertical ODT on time, in ref to UV pulse
tHVon = -10e-6;           % Time to turn HV switch on, in ref to UV pulse
tScope = 0e-6;          % Time to trigger Oscilloscope, in ref to UV pulse

if (tMCPtrig < (-tYagDelay)) || (tMCPtrig > T1)
    error('tMCPtrig is set wrong!');
end
if (tODToff1 < (-tYagDelay)) || (tODToff1 > T1)
    error('tODToff is set wrong!');
end
if (tODTon1 < tODToff1) || (tODTon1 > T1)
    error('tODTon is set wrong!');
end
if (tHVon < (-tYagDelay)) || (tHVon > T1)
    error('tHVon is set wrong!');
end

tList0 = [tMCPtrig tODToff1 tODTon1 tODToff2 tODTon2 tHVon tScope];
ChanList = {'TTLMCP' 'TTLODT1' 'TTLODT1' 'TTLODT2' 'TTLODT2' 'TTLHVswitch1' 'TTLscope'};
ChanVal = [1 0 0 0 0 1 0];
if length(tList0)~= length(ChanList)
    error('length(tList0)~= length(ChanList)!');
end
if length(tList0)~= length(ChanVal)
    error('length(tList0)~= length(ChanVal)!');
end
[tList1, tindex] = sort(tList0);
dtList = diff([-tYagDelay tList1]);

for i = 1:length(tList0)
    s.wait(dtList(i));
    s.add(ChanList{tindex(i)}, ChanVal(tindex(i)));
end
s.addStep(T1 - tYagDelay - max(tList0));

%% turn the HV switch back off
s.addStep(period-T1)...
    .add('TTLHVswitch1', 0)...
    .add('TTLMCP', 0)...
    .add('TTLscope', 0);

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
