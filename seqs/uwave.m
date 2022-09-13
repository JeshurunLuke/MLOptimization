function s = uwave(s1,t1)
%%tOP is the total time for OP, including shutter delay,laser pulse length
%%etc.
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
if(~exist('t1','var'))
    t1 = 10e-3;
end

tuwave=4e-3;%[s] u-wave pulse length
dt=2e-3;%wait time for field settling down
if abs(tuwave+dt)>t1
    error('abs(TOFK-TOFRb) need to be bigger!');
end
VperA=1/0.54;%[V/A]Volt per amp
IL1=1;  %[A] L1 is the small coil, IL1<5A
% IL2=3;  %[A] L2 is the large coil, IL2<=3A
VL1=IL1*VperA;
% VL2=IL2*VperA;
% s.add('Vquant3',VL2);
s.add('Vquant2',0.1);

s.addStep(@QuantFieldOff);  %turn off imaging quantization field
s.wait(dt); %waiting for field settling down
% s.add('TTLscope',1); %trigger oscilloscope
% s.add('TTLuwavesweep',1);   %trigger u-wave synthesizer to do frequency sweep, set sweep duration in V5009CM
s.add('TTLuwaveampl',0);    %u-wave amplifier enable
% s.wait(tuwave);
s.addStep(tuwave) ...
    .add('Vquant2', rampTo(VL1));
% s.add('TTLuwavesweep',0);   %trigger u-wave synthesizer to do frequency sweep, set sweep duration in V5009CM
s.add('TTLuwaveampl',0);    %u-wave amplifier disable

%after wave turn coils off and imaging coil on
s.add('Vquant2',0);
s.add('Vquant3',0);
s.addStep(@QuantFieldOn);%
s.wait(t1-tuwave-dt);

if(~exist('s1','var'))
    s.run();
end

end