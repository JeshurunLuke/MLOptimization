function s = QUICCoilRampOnParallel()

s = ExpSeq();

VPSQuad = 0.0;
% VPSIoffe = 0.0;
IQuadCoil = 0.0;
IIoffeCoil = 0.0;

if IIoffeCoil == 0
    VIoffeCoil = 1.0;
else
    VIoffeCoil = - IIoffeCoil/s.C.QUICCoilIV;
end

% VPSIoffeProg = VPSIoffe/s.C.GENH12560VPConst;

if IQuadCoil == 0
    VQuadCoil = 1.0;
else
    VQuadCoil = - IQuadCoil/s.C.QUICCoilIV;
end

VPSQuadProg = VPSQuad/s.C.XLN3640VPConst;

% Slew rate limit of the XLN3640 P/S is 2.4 V/ms
XLN3640SlewRate = 2400;

s.addStep(max(VPSQuad/XLN3640SlewRate,1e-6))...
    .add('XLN3640VP',VPSQuadProg);
%     .add('GENH12560VP',VPSIoffeProg);

s.add('TTLscope',1);
s.addStep(500e-3) ...
   .add('VctrlCoilServo3', rampTo(VIoffeCoil))...
   .add('VctrlCoilServo2', rampTo(VQuadCoil));

s.wait(2.0);

s.addStep(500e-3) ...
   .add('VctrlCoilServo3', rampTo(1.0))...
   .add('VctrlCoilServo2', rampTo(1.0));

s.add('TTLscope',0);

s.run();

end