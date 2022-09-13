function s = QUICTrapRampOff(s1,tRamp)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 1e-3;%[s]
end

% QUIC trap parameters
IQuadCoil = 0.0; %20*0.4; %
IIoffeCoil = 0.0; %19.5*0.4;%

if IIoffeCoil == 0
    VIoffeCoil = 1.0;
else
    VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
end

if IQuadCoil == 0
    VQuadCoil = 1.0;
else
    VQuadCoil = - IQuadCoil/s.C.QUICCoilIV;
end

% Ramp off the QUIC coils while ramping on the quantization coil
% s.addStep(tRamp) ...
%     .add('VctrlCoilServo2', rampTo(VBleeder));

%% Turn on the large quantization coil
Ifield = 0.5;%was at 0.5A [A] B=15G, when I=-4.4A ==>Measured B/I=3.4G/A. (calculated B/I=4.2G/A)
VperA=1/0.54;%[V/A]Volt per amp
Vfield = Ifield*VperA;
% s.add('Vquant3',Vfield);

s.addStep(tRamp) ...
    .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...                                                                                                                                                                                                                                                                                                                                   ...
    .add('VctrlCoilServo3', rampTo(VIoffeCoil))...
    .add('Vquant3', rampTo(Vfield));


if(~exist('s1','var'))
    s.run();
end

end

