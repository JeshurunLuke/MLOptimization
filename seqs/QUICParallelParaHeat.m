function s = QUICParallelParaHeat(s1,IQuadCoil,IIoffeCoil,tDrive,AmpI,Freq)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tDrive = 1;%[s]
end

if ~exist('AmpI','var')
    AmpI = 2;%[A]
end

if ~exist('Freq','var')
    Freq = 10;%[Hz]
end

if ~exist('IQuadCoil','var')
    IQuadCoil = 20.00;%[A]
end

if ~exist('IIoffeCoil','var')
    IIoffeCoil = 21.63;%[A]
end

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

% Sinusoidal drive parameters

Period = 1./Freq;
AmpV = - AmpI/s.C.QUICCoilIV;

s.addStep(tDrive) ...
    .add('VctrlCoilServo2', @(t) AmpV.*sin(t*2*pi/Period) + VQuadCoil) ...
    .add('VctrlCoilServo3', @(t) AmpV.*sin(t*2*pi/Period) + VIoffeCoil);

if(~exist('s1','var'))
    s.run();
end

end