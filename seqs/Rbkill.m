function s = Rbkill(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% %----Imaging pulse for removing leftover F=2 atoms-----
DetImagingRb = 0*6.1e6;% (19.36 + x.*6.1)*1e6; new resonance 19.36 MHz resonant f=20.6e6 Det=8.8 is the detuning from the F = 2,2 -> F' = 3,3 resonance;
fRbimaging = 3e6;  % 3MHz for B = 2G (last updated on 8/31/2017)
fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - (fRbimaging+DetImagingRb)) / s.C.RbPLLScale;
s.add('FreqRbMOTTrap', fRb)...
    .add('TTLImagingShutter', 1);%1
s.wait(2.8e-3);
s.add('AmpRbOPZeemanAOM', 0.3)
s.wait(10e-3);
s.add('AmpRbOPZeemanAOM', 0)...
    .add('TTLImagingShutter', 0);

if(~exist('s1','var'))
    s.run();
end

end