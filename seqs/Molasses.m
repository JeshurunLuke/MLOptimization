function s = Molasses(s1, tMolas)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

useD2Molas = 0;

%% Rb Molasses Parameters
DetRbMolasses = -150e6;%-150was at -40e6; -150e6 11/20/2016
% VShimMolasses = [-2.5,0, 0, -.2];%[VBop,VBshimX,VBshimY,VBshimZ]
% VShimMolasses = [-1.5,-0.8, +0.8, -0.2];%[VBop,VBshimX,VBshimY,VBshimZ]
AmpRbRepumpMolasses = 0.225;%was 0.16 0.04 (7/16/2018)
fRbRepump = 86e6;%was at 85MHz,86.5MHz from 11/20/2016
s.add('FreqRbRepumpAOM', fRbRepump);

%% K grey molasses Parameters
 % We lock on the (F=1,2 crossover -> F'=2) peak, corresponding to laser
 % frequency 770.108 nm +78.55MHz.
 % We always divide by 2 because the shift is done through a double-pass AOM setup
DetKCoolMolasses = 14e6; %positive means blue detuned
DetKRepumpMolasses = 14e6; %positive means blue detuned, 14e6
FreqKCoolMolasses = (-20.8e6 - 57.75e6 + 571.5e6 + 211.9e6)/2  + DetKCoolMolasses/2; %double-pass AOM is +1 order
FreqKRepumpMolasses = (20.8e6 + 57.75e6  + (-571.5e6 + 1285.8e6) - 211.9e6)/2 - DetKRepumpMolasses/2; %double-pass AOM is -1 order
AmpKMolasses = 0.1150;%
AmpKRepumpMolasses = 0.285;
ShutterDelay = 2.8e-3;

%% K D2 grey molasses parameters

DetKCoolD2MolasInit = - 65.18e6;
DetKRepumpD2MolasInit = - 65.18e6;
DetKRepumpCoolD2MolasInit = -4.89e6;

DetKCoolD2MolasFinal = - 58.51e6; %Was 122.51
DetKRepumpD2MolasFinal = - 58.51e6;
DetKRepumpCoolD2MolasFinal = -3.38e6; %Was -3.38

freqKCoolD2MolasInit = ((571.5e6 - 57.75e6 + 126.0e6 - 2.3e6) - (80e6) + DetKCoolD2MolasInit) / s.C.KTrapPLLScale;
freqKCoolD2MolasFinal = ((571.5e6 - 57.75e6 + 126.0e6 - 2.3e6) - (80e6) + DetKCoolD2MolasFinal) / s.C.KTrapPLLScale;
% DetTrap is the detuning from the F = 9/2 -> F' = 9/2 resonance;
freqKRepumpD2MolasInit = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetKRepumpD2MolasInit + DetKRepumpCoolD2MolasInit) / s.C.KRepumpPLLScale;
freqKRepumpD2MolasFinal = abs((-714.3e6 - 57.75e6 + 126.0e6 - 2.3e6) + (80e6) - (80e6) + DetKRepumpD2MolasFinal + DetKRepumpCoolD2MolasFinal) / s.C.KRepumpPLLScale;
% DetRepump is the detuning from the F = 7/2 -> F' = 9/2 resonance;
% Positive detuning = blue detuned; negative detuning = red detuned;

%% K grey molasses Parameters
% We lock on the (F=1,2 crossover -> F'=2) peak, corresponding to laser
% freq
% DetKCoolMolasses = 0e6;%Current setting already has 14.3 blue detuning at DetKMolasses = 0
% DetKRepumpMolasses = 0e6;%Current setting already has 14.3 blue detuning at DetKRepumpMolasses = 0
% FreqKCoolMolasses = 359.425e6 + DetKCoolMolasses; %359.425e6
% FreqKRepumpMolasses = 283.475e6 + DetKRepumpMolasses;
% AmpKMolasses = 0.1150;%
% AmpKRepumpMolasses = 0.2850;
% ShutterDelay = 2.8e-3;

%% Coil parameters
VShimMolasses = [0, 0, 0.0, -0.5];% [-1, 0, 0.0, -0.5] [VBop,VBshimX,VBshimY,VBshimZ]([-1, 0, 0.0, -0.2]Roughly optimized 02/23/16)
IMOT = -15;%negative means off

%%
if(~exist('tMolas','var'))
    tMolas = 20e-3; % [s]Molasses duration (Roughly optimized 02/23/16)
end

if(useD2Molas)
    s.addStep(@SetRbMOTBeamsAndB,...
        1, DetRbMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, 10e-6);

    s.addStep(10e-6)...
        .add('AmpKMOTAOM',0.147)...
        .add('AmpKRepumpAOM',0.0445);

     s.addStep(1e-6)...
        .add('FreqKMOTTrap', freqKCoolD2MolasInit)...
        .add('FreqKMOTRepump', freqKRepumpD2MolasInit);

     s.addStep(6e-3)...
        .add('FreqKMOTTrap', rampTo(freqKCoolD2MolasFinal))...
        .add('FreqKMOTRepump', rampTo(freqKRepumpD2MolasFinal));

     s.wait(4e-3);
else
    s.addStep(ShutterDelay)...
        .add('TTLKGMShutter',1);

    s.addStep(10e-6)...
        .add('AmpKMOTAOM',0.000);

    s.addStep(1e-6)...
        .add('FreqKGMCoolAOM',FreqKCoolMolasses)...
        .add('AmpKGMCoolAOM',AmpKMolasses)...
        .add('FreqKGMRepumpAOM',FreqKRepumpMolasses)...
        .add('AmpKGMRepumpAOM',AmpKRepumpMolasses);

    s.addStep(@SetRbMOTBeamsAndB,...
        1, DetRbMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, tMolas);
end

if(~exist('s1','var'))
    s.run();
end
end

