function s = KKill(s1, tkill)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
if(~exist('tkill','var'))
    tkill = 40e-6;%[s]
end

s.addStep(tkill)...
    .add('AmpKOPRepumpAOM', 0.0)...        %%don't exceed 0.3 V
s.add('AmpKOPRepumpAOM', 0.0)...        %%don't exceed 0.3 V
    .add('AmpRbOPZeemanAOM', 0)...
    .add('Ampuwave',0)...
    .add('TTLRbImagingShutter', 0)...
    .add('TTLKImagingShutter', 0);

if(~exist('s1','var'))
    s.run();
end

end