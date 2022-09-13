function s = QUICCoilRampOn()

s = ExpSeq();

% VPS = 0.00;
% VPS = 7.25;
% VPS = 12.50;
VPS = 0.0;

% IQuadCoil2 = 0.2;
% IIoffeCoil2 = 0.15;
% IBleeder2 = IQuadCoil2 - IIoffeCoil2;
% VIoffeCoil2 = - IIoffeCoil2/s.C.QUICCoilIV;
% VBleeder2 = - IBleeder2/s.C.QUICCoilIV;
% s.addStep(100e-3) ...
%    .add('VctrlCoilServo2', rampTo(VBleeder2)) ...
%    .add('VctrlCoilServo3', rampTo(VIoffeCoil2));
% s.wait(500e-3)

IQuadCoil1 = 0.00;
IIoffeCoil1 = 0.00;
IBleeder1 = IQuadCoil1 - IIoffeCoil1;

% IQuadCoil2 = 0.00;
% IIoffeCoil2 = 0.00;
% IBleeder2 = IQuadCoil2 - IIoffeCoil2;

if IIoffeCoil1 == 0
    VIoffeCoil1 = 1.0;
else
    VIoffeCoil1 = - IIoffeCoil1/s.C.QUICCoilIV;
end

if IBleeder1 == 0
    VBleeder1 = 1.0;
else
    VBleeder1 = - IBleeder1/s.C.QUICCoilIV;
end

% if IIoffeCoil2 == 0
%     VIoffeCoil2 = 1.0;
% else
%     VIoffeCoil2 = - IIoffeCoil2/s.C.QUICCoilIV;
% end
%
% if IBleeder2 == 0
%     VBleeder2 = 1.0;
% else
%     VBleeder2 = - IBleeder2/s.C.QUICCoilIV;
% end

VPSProg = VPS/s.C.XLN3640VPConst;

% Slew rate limit of the XLN3640 P/S is 2.4 V/ms
XLN3640SlewRate = 2400;

s.addStep(max(VPS/XLN3640SlewRate,1e-6))...
    .add('XLN3640VP',VPSProg);

s.addStep(500e-3) ...
   .add('VctrlCoilServo2', rampTo(VBleeder1)) ...
   .add('VctrlCoilServo3', rampTo(VIoffeCoil1));

% s.wait(1.0);
%
% s.addStep(100e-3) ...
%    .add('VctrlCoilServo2', rampTo(VBleeder2)) ...
%    .add('VctrlCoilServo3', rampTo(VIoffeCoil2));
%
% s.wait(1.0);
%
% s.addStep(1e-3) ...
%    .add('VctrlCoilServo2', rampTo(1.0)) ...
%    .add('VctrlCoilServo3', rampTo(1.0));
% s.wait(2);

  s.run();
end