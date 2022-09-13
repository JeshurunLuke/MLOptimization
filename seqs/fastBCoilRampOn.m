function s = fastBCoilRampOn(s1, IfbCoil, tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tRamp','var'))
    tRamp = 500e-3;%[s]
end

if IfbCoil == 0
    VfbCoil = 0.5;
else
    VfbCoil = - IfbCoil/s.C.FastBCoilIV;
end

s.addStep(tRamp) ...
    .add('VctrlCoilServo5', rampTo(VfbCoil));

if(~exist('s1','var'))
    s.run();
end

end