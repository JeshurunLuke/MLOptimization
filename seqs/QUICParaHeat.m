function s = QUICParaHeat(s1,tDrive,AmpI,Freq)

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

VPS = 20.0; %set the QUIC trap P/S voltage
s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

IQuadCoil = 20.0;%[A]
IIoffeCoil = 19.5;%[A]
IBleeder = IQuadCoil - IIoffeCoil;

VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
VBleeder = - IBleeder/s.C.QUICCoilIV;

% Sinusoidal drive parameters

Period = 1./Freq;
AmpV = - AmpI/s.C.QUICCoilIV;

s.addStep(tDrive) ...
    .add('VctrlCoilServo2', VBleeder) ...
    .add('VctrlCoilServo3', @(t) AmpV.*sin(t*2*pi/Period) + VIoffeCoil);

if(~exist('s1','var'))
    s.run();
end

end