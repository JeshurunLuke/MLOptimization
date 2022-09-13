function s = KpreKill(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
% %----Imaging pulse for removing leftover F=2 atoms-----
fKprobe = -760e6;
fKprobeRepump = (571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) + fKprobe;     % [Hz]reference to locking point of K39 master laser
fKRepump = abs(fKprobeRepump - 110e6) / s.C.KRepumpPLLScale;          % 110MHz is for compensating a +1 order AOM

fRbimaging = 1.39e6*544.476;  % Zeeman shift of the |2,2> -> |3,3> transition is 1.39e6 MHz/G
fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - fRbimaging) / s.C.RbPLLScale;

s.add('FreqKMOTRepump',fKRepump)...
    .add('AmpKOPRepumpAOM', 0.0)...
    .add('FreqRbMOTTrap', fRb)...
    .add('AmpRbOPZeemanAOM', 0.0);        

if(~exist('s1','var'))
    s.run();
end

end