function s = Qtrapoff(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% Qtrap Parameters

IQtrap = -10;%turn off
VMOT = - IQtrap/s.C.TransferCoilIV;

s.add('VctrlCoilServo1', VMOT);

if(~exist('s1','var'))
    s.run();
end

end

