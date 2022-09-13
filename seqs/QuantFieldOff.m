function s = QuantFieldOff(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% Qtrap Parameters

Ifield = 0;%[A] B=15G, when I=-4.4A ==>Measured B/I=3.4G/A. (calculated B/I=4.2G/A)
VperA=1/0.54;%[V/A]Volt per amp
Vfield = Ifield*VperA;

s.add('Vquant1', Vfield);

if(~exist('s1','var'))
    s.run();
end
end