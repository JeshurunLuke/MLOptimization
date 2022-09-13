function s = QUICTrapOff1(s1,tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 1e-3;%[s]
end

% QUIC trap Parameters
IQuadCoil = 0.00;
IIoffeCoil = 0.00;

if IQuadCoil == 0
    VQuadCoil = 1;
else
    VQuadCoil = - IQuadCoil/s.C.QUICCoilIV;
end

if IIoffeCoil == 0
    VIoffeCoil = 1;
else
    VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
end

% Ifield1 = -4.8/10;%[A] B=2.2 G;
% VperA1=1/0.54;%[V/A]Volt per amp
% Vfield1 = Ifield1*VperA1;

% s.addStep(tRamp) ...
%     .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...                                                                                                                                                                                                                                                                                                                                   ...
%     .add('VctrlCoilServo3', rampTo(VIoffeCoil))...
%     .add('Vquant1', rampTo(Vfield1));

%% Turn on the large quantization coil
Ifield = 0.5;%was at 0.75A [A] B=15G, when I=-4.4A ==>Measured B/I=3.4G/A. (calculated B/I=4.2G/A)
if Ifield < 0
    error('Ifield for large quantization coil (Vquant3) need >= 0');
end
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

