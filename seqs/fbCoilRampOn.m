function s = fbCoilRampOn(s1, IfbCoil, tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('IfbCoil','var'))
    IfbCoil = 0;%[s]
end

if(~exist('tRamp','var'))
    tRamp = 500e-3;%[s]
end

if IfbCoil == 0
    VfbCoil = 0.5;
else
    VfbCoil = - IfbCoil/s.C.FeshbachCoilIV;
end

s.addStep(tRamp) ...
    .add('VctrlCoilServo4', rampTo(VfbCoil));

if(~exist('s1','var'))
    s.run();
end

end