function s = IoffeLoad(s1, IIoffeCoil, tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 500e-3;%[s]
end

if(~exist('IIoffeCoil','var'))
    IIoffeCoil = 0.0;%[A]
end
if IIoffeCoil == 0
    VIoffeCoil = 1.0;
else
    VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
end

s.addStep(tRamp) ...
    .add('VctrlCoilServo3', rampTo(VIoffeCoil));



%%%%%%%%%%%%%%%%%%%old%%%%%%%%%%%%%%%%%%%
% IQuadCoil = 20.0;%[A]
% IIoffeCoil = 19.99;%[A] 19.5
% ITransferCoil = -10.00;%[A]
% IBleeder = IQuadCoil - IIoffeCoil;
%
% if IIoffeCoil == 0
%     VIoffeCoil = 1.0;
% else
%     VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
% end
%
% if IBleeder == 0
%     VBleeder = 1.0;
% else
%     VBleeder = - IBleeder/s.C.QUICCoilIV;
% end
%
% VTransferCoil = - ITransferCoil/s.C.TransferCoilIV;
%
% s.addStep(tRamp) ...
%     .add('VctrlCoilServo2', rampTo(VBleeder)) ...
%     .add('VctrlCoilServo3', rampTo(VIoffeCoil)) ...
%     .add('VctrlCoilServo1', rampTo(VTransferCoil));

if(~exist('s1','var'))
    s.run();
end

end