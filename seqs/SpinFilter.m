function s = SpinFilter(s1, tSpinFilter)
%%tOP is the total time for OP, including shutter delay,laser pulse length
%%etc.
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% Transfer Coil Parameters
IWQuadField = 60.0 ;
if(~exist('tSpinFilter','var'))
    tSpinFilter = 200e-3; % time to allow atoms in F = |2,1> to leave the quadrupole trap
end



% % Optical Pumping Parameters
% DetOPZeeman = -2e6;% Det is the detuning from the F = 2 -> F' = 2 resonance;
% f = ((6.834682610*1e9 - 156.9470/2*1e6 + 80.0000*1e6) - DetOPZeeman) / s.C.RbPLLScale;
% VBOP = 5; % Positive value yields the correct quantization field direction, optimized for recaptured fraction as of 03/01/16
% VShim = [VBOP, 0, 0.0, 0.0];%%[VBop(0.3A/V),VBshimX(0.1A/V),VBshimY(0.1A/V),VBshimZ(0.1A/V)]
% AmpRbOPZeemanAOM = 0.045;%0.045=>50uW (see calibration on 10/21/2016)
% AmpRbOPRepumpAOM = 0.135;%0.135=>1mW (see calibration on 10/21/2016)
% frepump=85e6;%78.4735e6;%
% s.add('FreqRbRepumpAOM', frepump)...
%     .add('AmpRbRepumpAOM',0.09);
%
% Delay = 10e-6;  %delay before the OP laser pulse after shutters open
% ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% if(~exist('tOP','var'))
%     tOP =0.5e-3+ShutterDelay+Delay; % [s]Molasses duration (Roughly optimized 02/23/16)  was
% end
%
% if tOP<(ShutterDelay+Delay)
%     error(['tOP need >=',num2str(ShutterDelay+Delay),'s']);
% end
% TOPDuration=tOP-(ShutterDelay+Delay);
% %% Optical Pumping
% % Turn off MOT light and open OP light shutter
% s.addStep(ShutterDelay) ...
%     .add('TTLKMOTShutter',0)...
%     .add('TTLRbMOTShutter',0)...
%     .add('TTLMOTTelescopeShutter', 0) ...
%     .add('TTLOPShutter', 1);
%
% %set shim coils and AOM frequencies ready for OP
% s.addStep(Delay)...
%     .add('VBOP', VShim(1)) ...
%     .add('VBShimX', VShim(2)) ...
%     .add('VBShimY', VShim(3)) ...
%     .add('VBShimZ', VShim(4)) ...
%     .add('FreqRbMOTTrap', f);
%
% %%laser pulse on for OP
% s.addStep(TOPDuration)...
%     .add('AmpRbOPRepumpAOM',AmpRbOPRepumpAOM)...
%     .add('AmpRbOPZeemanAOM',AmpRbOPZeemanAOM);
%
% %%laser pulse off for OP
% s.add('AmpRbOPRepumpAOM',0)...
%     .add('AmpRbOPZeemanAOM',0)...
%     .add('TTLOPShutter',0);

if(~exist('s1','var'))
    s.run();
end

end

