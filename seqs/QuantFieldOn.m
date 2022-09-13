function s = QuantFieldOn(s1,tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 10e-6;%[s]
end

% QUIC chamber imaging field by AG coil ramp on
Ifield1 = -4.8;%[A] B=22 G;
VperA1=1/0.54;%[V/A]Volt per amp
Vfield1 = Ifield1*VperA1;

% % QUIC chamber imaging field by side coil ramp on
% Ifield1 = -4.8;%[A] B=22 G;
% VperA1=1/0.54;%[V/A]Volt per amp
% Vfield1 = Ifield1*VperA1;

% Big quantization coil ramp off
% Ifield2 = 0.0;%[A] B=22 G;
% VperA2 = 1/0.54;%[V/A]Volt per amp
% Vfield2 = Ifield2*VperA2;

s.addStep(tRamp)...
    .add('Vquant1', Vfield1);

if(~exist('s1','var'))
    s.run();
end
end