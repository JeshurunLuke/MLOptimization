function s = MCPVoltageRampOff(s1,VBack,tRamp1,tRamp2)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tRamp1','var'))
    tRamp1 = 2;%[s]
end

if(~exist('tRamp2','var'))
    tRamp2 = 3;%[s]
end

VBackDAC = VBack./s.C.HV26Const;

s.addStep(tRamp2) ...
    .add('MCPPSCHA', rampTo(VBackDAC));

s.addStep(tRamp1) ...
    .add('MCPPSCHA', rampTo(0)) ...
    .add('MCPPSCHB', rampTo(0));

if(~exist('s1','var'))
    s.run();
end

end