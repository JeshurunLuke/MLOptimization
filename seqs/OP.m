function s = OP(s1,tOP)
%%tOP is the total time for OP, including shutter delay,laser pulse length
%%etc.
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
% Optical Pumping Parameters
DetRbZeeman = 10.5e6;% Det is the detuning from the F = 2 -> F' = 2 resonance;
DetKZeeman = 10.*1e6;
DetKRepump = 0.*1e6;
fRbZeeman = ((6.834682610*1e9 - 156.9470/2*1e6 - 80.0000*1e6) - DetRbZeeman) / s.C.RbPLLScale;
fRbRepump = 78.4735e6;%80e6;%78.4735e6
fKZeeman = ((571.5e6 - 57.75e6 + 126.0e6 - 2.3e6) + (110e6) + DetKZeeman) / s.C.KTrapPLLScale;
fKRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) - (110e6) + DetKRepump) / s.C.KRepumpPLLScale;
% fKZeeman = ((571.5e6 - 57.75e6 + 126.0e6 - 46.6e6) + (110e6) + DetKZeeman) / s.C.KTrapPLLScale;
% fKRepump = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) - (110e6) + DetKRepump) / s.C.KRepumpPLLScale;
VBOP = 9.0; % Positive value yields the correct quantization field direction, optimized for recaptured fraction as of 03/01/16
VShim = [VBOP, 0, 0.0, 0.0];%%[VBop(0.3A/V),VBshimX(0.1A/V),VBshimY(0.1A/V),VBshimZ(0.1A/V)]
AmpRbOPZeemanAOM = 0.08; % 0.080 was 0.035  %12/12/2018; 0.038;% 38 uW (after fiber) as measured 01/08/17, optimized to 0.020 V; 38uW (after fiber) as measured 12/01/16, optimized to 0.02 V; 0.045=>50uW (see calibration on 10/21/2016), was at 0.015, 0.02 11/21/2016
%Was 0.083 on 3/01/2020
%Was 0.080 on 2/20/2020
%Was 0.080 on 11/19/2019
%Was 0.080 on 10/06/2019
AmpRbOPRepumpAOM = 0.175; %0.175 was 0.17, 1.020 mW, 06/28/2018;
%Was 0.186 on 3/01/2020
%Was 0.175 on 2/20/2020
%Was 0.175 on 11/19/2019
%Was 0.17 on 10/06/2019
AmpKOPZeemanAOM = 0.060;% 0.065 08/21/18 was 0.045, optimized on 07/03/18;
%Was 0.045 on 2/20/2020
%Was 0.065 on 1/9/2020
%Was 0.045 on 1/6/2020
%Was 0.04 on 11/19/2019
%Was 0.0475 on 10/06/2019
%Was 0.1 on 10/07/2019d
AmpKOPRepumpAOM = 0.3;  %0.23 0.27 0.2 Optimized on 12/07/16;
%Was 0.23 on 1/9/2020
%Was 0.27 on 1/6/2020
%Was 0.25 on 10/06/2019

Delay = 10e-6;  %delay before the OP laser pulse after shutters open
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
%ShutterDelay = 2.8e-3; 11/19/2019
if(~exist('tOP','var'))
    tOP =0.5e-3+ShutterDelay+Delay; % [s]Molasses duration (Roughly optimized 02/23/16)  was
end

if tOP<(ShutterDelay+Delay)
    error(['tOP need >=',num2str(ShutterDelay+Delay),'s']);
end
TOPDuration=tOP-(ShutterDelay+Delay);
%% Optical Pumping
% Turn off MOT light and open OP light shutter
s.addStep(ShutterDelay) ...
    .add('TTLKGMShutter', 0)...
    .add('TTLMOTShutters', 0)...
    .add('TTLOPShutter', 1)...
    .add('FreqKMOTTrap',fKZeeman)...
    .add('FreqKMOTRepump',fKRepump)...
    .add('AmpRbRepumpAOM', 0.0);
%    .add('AmpKRepumpAOM',0.0)... % Turn off K MOT repump AMO to divert all power to K OP repump

%set shim coils and AOM frequencies ready for OP
s.addStep(Delay)...
    .add('VBOP', VShim(1)) ...
    .add('VBShimX', VShim(2)) ...
    .add('VBShimY', VShim(3)) ...
    .add('VBShimZ', VShim(4)) ...
    .add('FreqRbMOTTrap', fRbZeeman)...
    .add('FreqRbRepumpAOM', fRbRepump);

%%laser pulse on for OP
s.addStep(TOPDuration)...
    .add('AmpRbOPRepumpAOM',AmpRbOPRepumpAOM)...
    .add('AmpRbOPZeemanAOM',AmpRbOPZeemanAOM)...
    .add('AmpKOPRepumpAOM',AmpKOPRepumpAOM)...
    .add('AmpKOPZeemanAOM',AmpKOPZeemanAOM);

%%laser pulse off for OP
s.addStep(1e-6)...
    .add('AmpRbOPRepumpAOM',0.0000)...
    .add('AmpRbOPZeemanAOM',0.0000)...
    .add('AmpKOPRepumpAOM',0.0000)...
    .add('AmpKOPZeemanAOM',0.0000)...
    .add('TTLOPShutter',0);

if(~exist('s1','var'))
    s.run();
end

end

