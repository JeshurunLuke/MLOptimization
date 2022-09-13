function s = KMOTAOMOnOff(s1, dt, T)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('dt','var')
    dt = 20e-3; %[s]
end

if ~exist('T','var')
    T = 200e-3; %[s]
end

s.addStep(2.8e-3)...
    .add('TTLMOTShutters', 1)...
    .add('TTLKGMShutter', 1);

s.addStep(dt)...
    .add('AmpKMOTAOM',0.000)...
    .add('TTLSTIRAPTrig',1);

s.addStep(T - dt)...
    .add('AmpKMOTAOM',0.400)...
    .add('TTLSTIRAPTrig',0);

end

%TTLSTIRAPTrig