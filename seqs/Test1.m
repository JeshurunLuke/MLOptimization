function s = Test1(s1)
%%tOP is the total time for OP, including shutter delay,laser pulse length
%%etc.
s = ExpSeq();

s.addStep(@ABLTransfer);
% s.add('VBShimZ', 3);

if(~exist('s1','var'))
    s.run();
end

end