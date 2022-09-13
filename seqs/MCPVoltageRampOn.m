function s = MCPVoltageRampOn(s1, VFront, VBack, tRamp1, tRamp2)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('VFront','var'))
    VFront = 0;%[V]
end

if(~exist('VBack','var'))
    VBack = 0;%[V]
end

if(~exist('tRamp1','var'))
    tRamp1 = 2;%[s]
end

if(~exist('tRamp2','var'))
    tRamp2 = 3;%[s]
end

VFrontDAC = VFront./s.C.HV26Const;
VBackDAC = VBack./s.C.HV26Const;

s.addStep(tRamp1) ...
    .add('MCPPSCHA', rampTo(VBackDAC)) ...
    .add('MCPPSCHB', rampTo(VBackDAC));

s.addStep(tRamp2) ...
    .add('MCPPSCHA', rampTo(VFrontDAC));

if(~exist('s1','var'))
    s.run();
end

end