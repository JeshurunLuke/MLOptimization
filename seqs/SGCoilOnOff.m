 function s = SGCoilOnOff(s1,VPS,tSG)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('VPS','var'))
   VPS = 35; %[V] original =35
end

if(~exist('tSG','var'))
    tSG = 3e-3;%[s]
end

s.add('XLN3640VP',VPS/s.C.XLN3640VPConst);

s.wait(3);

s.addStep(tSG) ...
    .add('VSG', 10.0)...
    .add('TTLscope', 1);

s.addStep(10e-6) ...
    .add('VSG', 0)...
    .add('TTLscope',0);

s.add('XLN3640VP',0);

if(~exist('s1','var'))
    s.run();
end

end