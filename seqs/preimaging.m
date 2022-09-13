function s = preimaging(s1,fRbimaging,DetImagingRb,fKimaging,DetImagingK, Bstatus)
%%Bstatus ---- %0 means low B (~30G), 1 means high B (~550G);
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

mem=MemoryMap;
%% ===set Imaging frequency of Rb=====
if(~exist('fRbimaging','var'))
    if mem.Data(1).camera == 1        %% for science chamber
        fRbimaging = 29.78e6; %calibrated on 09/20/17 %29.06e6 for science chamber imaging; 26.798*1e6;(118.58*1.4-0.5)*1e6;%  % 28.323 [Hz] Zeeman frequency shift due to B field (last updated on 7/17/2017)
    else %%% for evaporation chamber
        fRbimaging = 27.48*1e6; %25.93 MHz is for TOF = 3ms; 27.5MHz is for TOF=35ms  for evaporation chamber imaging, calibrated on 04/22/2018
    end
end

if(~exist('Bstatus','var'))
    Bstatus = 0;        %0 means low B (~30G), 1 means high B (~550G)
end

if(~exist('DetImagingRb','var'))
    DetImagingRb = 0.*6.1e6;% Positive -> blue detuning; Negative -> red detuning; (19.36 + x.*6.1)*1e6; new resonance 19.36 MHz resonant f=20.6e6 Det=8.8 is the detuning from the F = 2,2 -> F' = 3,3 resonance;
end

mem.Data(1).dfRb = DetImagingRb/1e6;%[MHz]
fRb = ((6.834682610*1e9 - 156.9470/2*1e6-266.65*1e6-80.0000*1e6) - (fRbimaging+DetImagingRb)) / s.C.RbPLLScale;
s.add('FreqRbMOTTrap', fRb)...
    .add('AmpRbOPZeemanAOM', 0.0);

%% ===set Imaging frequency of K=====
if(~exist('fKimaging','var'))
    if mem.Data(1).camera == 1        %% for science chamber
        fKimaging = 30e6; %
    else %%% for evaporation chamber
        fKimaging = 32e6; % for evaporation chamber imaging
    end
end

if(~exist('DetImagingK','var'))
    DetImagingK = 0.*6.1e6;%(27.30 - 0.0*6.1).*1e6; new resonance 27.30 (Old value: 27.67 MHz)
end

mem.Data(1).dfK=DetImagingK/1e6;%[MHz]
if Bstatus
    fKprobe = fKimaging;        % [Hz] reference to F=9/2--> F= 11/2 transition at zero B field
    fKprobeRepump = (571.5e6 - 57.75e6 + 126.0e6 - 46.4e6) + (fKprobe + DetImagingK);     % [Hz]reference to locking point of K39 master laser
    fKRepump = abs(fKprobeRepump - 110e6) / s.C.KRepumpPLLScale;          % 110MHz is for compensating a +1 order AOM
    s.add('FreqKMOTRepump',fKRepump)...
        .add('AmpKOPRepumpAOM', 0.0);
else
    fK = ((571.5e6 - 57.75e6 + 126.0e6 - 46.4e6 + 110.0000*1e6) + (fKimaging + DetImagingK)) / s.C.KTrapPLLScale;
    s.add('FreqKMOTTrap', fK)...
        .add('AmpKOPZeemanAOM', 0.0);
end


if(~exist('s1','var'))
    s.run();
end
end


