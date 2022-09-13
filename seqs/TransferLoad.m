function s = TransferLoad(s1,ITransferCoil,tRamp)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('ITransferCoil','var'))
    ITransferCoil = 320.0;%[A]
end


if ~exist('tRamp','var')
    tRamp = 500e-3;%[s]
end

VTransferCoil = - ITransferCoil/s.C.TransferCoilIV;
VShim = [0, 0.0, 0.0, 0]; %[VBop,VBshimX,VBshimY,VBshimZ](Roughly optimized 02/23/16)

s.addStep(tRamp)...
    .add('VBOP', VShim(1)) ...
    .add('VBShimX', VShim(2)) ...
    .add('VBShimY', VShim(3)) ...
    .add('VBShimZ', VShim(4)) ...
    .add('VctrlCoilServo1', rampTo(VTransferCoil));%rampTo(VMOT)

if(~exist('s1','var'))
    s.run();
end
end