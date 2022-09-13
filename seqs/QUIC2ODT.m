function s = QUIC2ODT(s1,tRamp,VODTtransf)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tRamp','var')
    tRamp = 400e-3;%[s]
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

% %% Turn on the large quantization coil
% Ifield = 0;%1.2 0.5; was at 0.75A [A] (calculated B/I=1.9G/A at evap chamb)
% % if Ifield < 0
% %     error('Ifield for large quantization coil (Vquant3) need >= 0');
% % end
% VperA=1/0.54;%[V/A]Volt per amp
% Vfield = Ifield*VperA;


%%--The following lines are for playing quantization field---------
% QUIC trap Parameters
% tRamp1 = 400e-3;     %[s]
% tRamp2 = 100e-3;        %[s]
IQuadCoil1 = 2.75;     %[A]
IIoffeCoil1 = 2.75;    %[A]
VQuadCoil1 = - IQuadCoil1/s.C.QUICCoilIV;
VIoffeCoil1 = - IIoffeCoil1/s.C.QUICCoilIV;
%
% s.addStep(tRamp1) ...
%     .add('VctrlCoilServo2', rampTo(VQuadCoil1)) ...                                                                                                                                                                                                                                                                                                                                   ...
%     .add('VctrlCoilServo3', rampTo(VIoffeCoil1))...
%     .add('ODTtransf',rampTo(VODTtransf));
% s.wait(1e-6);
s.addStep(tRamp) ...
    .add('VctrlCoilServo2', rampTo(VQuadCoil)) ...                                                                                                                                                                                                                                                                                                                                   ...
    .add('VctrlCoilServo3', rampTo(VIoffeCoil))...
    .add('ODTtransf',rampTo(VODTtransf));
% %%%-------------------------------------------------


if(~exist('s1','var'))
    s.run();
end

end

