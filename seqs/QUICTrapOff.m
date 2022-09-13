function s = QUICTrapOff(s1,tRamp)

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

Ifield1 = -4.8/10;%[A] B=2.2 G; -4.8/10
VperA1=1/0.54;%[V/A]Volt per amp
Vfield1 = Ifield1*VperA1;

s.addStep(tRamp) ...
    .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...                                                                                                                                                                                                                                                                                                                                   ...
    .add('VctrlCoilServo3', rampTo(VIoffeCoil))...
    .add('Vquant1', rampTo(Vfield1));

if(~exist('s1','var'))
    s.run();
end

end

