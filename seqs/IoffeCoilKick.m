function s = IoffeCoilKick(s1,IIoffeCoil,tKick)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tKick','var')
    tKick = 1.5e-3;%[s]
end

if ~exist('IIoffeCoil','var')
    IIoffeCoil = 20.0; %[A]
end

if IIoffeCoil == 0
    VIoffeCoil = 1.0;
else
    VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
end

s.addStep(tKick) ...
   .add('VctrlCoilServo3', VIoffeCoil);

s.addStep(10e-6)... %Turns Ioffe coil off
    .add('VctrlCoilServo3', 0.5);

if(~exist('s1','var'))
    s.run();
end
end