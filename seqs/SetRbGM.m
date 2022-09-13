function SetRbGM(s, RbShutterState, MOTShutterState, Det, IMOT, VShim, fRbGMRepump, AmpRbGMRepump, TLength)

% Sets B fields and Rb laser parameters
%   Det is detuning in Hz (negative = red)
%   VShim = [Vx, Vy, Vz] sets the shim coils.
%   VMOT = MOT current voltage.  If input as 0, B field TTL is also set to zero.
%   AmpRbCool = New amplitude for Rb cooling laser
%   AmpRbRepump = New amplitude for Rb repump
%   TLength = length of time

fRbGMCool = ((6.834682610 * 1e9 - 156.9470/2 * 1e6 - 266.6500*1e6) - Det) / s.C.RbPLLScale;
% Det is the detuning from the F = 2 -> F' = 3 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

VMOT = - IMOT/s.C.TransferCoilIV;

TLength = max(TLength, 1e-6);

if length(VShim) == 1
    VShim = [1, 1, 1, 1] * VShim;
end

TLength = max(TLength, 1e-6);

s.addStep(TLength) ...
   .add('TTLMOTTelescopeShutter', MOTShutterState) ...
   .add('TTLRbMOTShutter', RbShutterState) ...
   .add('VBOP', VShim(1)) ...
   .add('VBShimX', VShim(2)) ...
   .add('VBShimY', VShim(3)) ...
   .add('VBShimZ', VShim(4)) ...
   .add('VctrlCoilServo1', VMOT) ...
   .add('FreqRbGMRepumpAOM', fRbGMRepump) ...
   .add('AmpRbGMRepumpAOM', AmpRbGMRepump) ...
   .add('AmpRbRepumpAOM', 0)...
   .add('FreqRbMOTTrap', fRbGMCool);

end
