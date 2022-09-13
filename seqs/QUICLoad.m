function s = QUICLoad(s1, IQUICCoil, tSwitch)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tSwitch','var'))
    tSwitch = 500e-3;%[s]
end

if(~exist('IQUICCoil','var'))
    IQUICCoil = 20.0;%[A]
end

if IQUICCoil == 0
    VQUICCoil = 1.0;
else
    VQUICCoil = - IQUICCoil/s.C.QUICCoilIV;
end

% if(~exist('IQuadCoil','var'))
%     IQuadCoil = 20.0;%[A]
% end
%
% if IQuadCoil == 0
%     VQuadCoil = 1.0;
% else
%     VQuadCoil = - IQuadCoil/s.C.QUICCoilIV;
% end
%
% if(~exist('IIoffeCoil','var'))
%     IIoffeCoil = 20.0;%[A]
% end
%
% if IIoffeCoil == 0
%     VIoffeCoil = 1.0;
% else
%     VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
% end

ITransferCoil = -10.0;%[A]
VTransferCoil = - ITransferCoil/s.C.TransferCoilIV;

s.addStep(tSwitch) ...
    .add('VctrlCoilServo3', rampTo(VQUICCoil)) ...
    .add('VctrlCoilServo1', rampTo(VTransferCoil));

% s.addStep(tSwitch) ...
%     .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...
%     .add('VctrlCoilServo3', rampTo(VIoffeCoil)) ...
%     .add('VctrlCoilServo1', rampTo(VTransferCoil));

if(~exist('s1','var'))
    s.run();
end

end