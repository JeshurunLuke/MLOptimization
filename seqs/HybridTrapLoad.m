function s = HybridTrapLoad(s1, tLoad)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tLoad','var'))
    tLoad = 500e-3;%[s]
end

IBleeder = 7.5;%80/(15/1.4);%[A] 15 A corresponds to 80 G/cm
ITransferCoil = -10.0;%[A]

if tLoad < 25e-3
    error('tLoad should be > 25 ms !');
end

if IBleeder == 0
    VBleeder = 1.0;
else
    VBleeder = - IBleeder/s.C.QUICCoilIV;
end

VTransferCoil = - ITransferCoil/s.C.TransferCoilIV;

s.addStep(tLoad) ...
    .add('VctrlCoilServo2', rampTo(VBleeder)) ...
    .add('VctrlCoilServo1', rampTo(VTransferCoil));

%% --------------Backward cart transfer----------
tTrackTrig = 1e-3; % min value 1 ms
s.addStep(@TrackTransfer,tTrackTrig);
s.wait(1);

%%--------------ODT on--------
s.add('TTLODT1', 1); %Turn on RF switch
s.add('ODT1', 0.001);
tRailing = 25e-3;      %servo railing time
s.wait(tRailing);

tRamp = tLoad-tRailing;

s.addStep(tRamp)...
    .add('ODT1',rampTo(3.0));       %was 2.5V, 3 means 3.66W, 4 corresponds to 4.88 W for Gain=30dB

if(~exist('s1','var'))
    s.run();
end
