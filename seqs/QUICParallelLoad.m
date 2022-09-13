function s = QUICParallelLoad(s1, IQuadCoil, IIoffeCoil, tSwitch)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tSwitch','var'))
    tSwitch = 500e-3;%[s]
end

if(~exist('IQuadCoil','var'))
    IQuadCoil = 20.0;%[A]
end

if(~exist('IIoffeCoil','var'))
    IIoffeCoil = 0.0;%[A]
end

ITransferCoil = -10.0;%[A]

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

VTransferCoil = - ITransferCoil/s.C.TransferCoilIV;

s.addStep(tSwitch) ...
    .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...
    .add('VctrlCoilServo3', rampTo(VIoffeCoil)) ...
    .add('VctrlCoilServo1', rampTo(VTransferCoil));

if(~exist('s1','var'))
    s.run();
end

end