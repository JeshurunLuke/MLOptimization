function s = MolassesTest(s1)
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
AmpRbRepumpMolasses = 0.1;%0.07
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
AmpKRepumpMolasses = 0.2850;
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
VShimMolasses = [0, 0, 0.0, -0.5];%[VBop,VBshimX,VBshimY,VBshimZ][-1, 0, 0.0, -0.5]
IMOT = -15;%negative means off

%%
if(~exist('tMolas','var'))
    tMolas = 20e-3; % [s]Molasses duration (Roughly optimized 02/23/16)
end

if(useD2Molas)
    s.addStep(@SetRbMOTBeamsAndB,...
        1,1, DetRbMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, 10e-6);

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

%     s.addStep(@SetRbMOTBeamsAndB,...
%         1,1, DetRbMolasses, IMOT, VShimMolasses, AmpRbRepumpMolasses, tMolas-tRbGM);
%     s.addStep(@SetRbMOTBeamsAndB,...
%         1, 1, DetRbMolasses, IMOT, VShimMolasses, 0, 2.8e-3);      %%only for setting B field to zero

    tRbGM = 3e-3;

    fRbGMRepump0 = 125e6;
    AmpRbGMRepump = 1.0;        % Grey molasses Repump AOM amp [V]
    Delta22 = fRbGMRepump0 - 156.95e6/2;     %Repump detuning from F = 1 --> F=2' transition
    delta22 = 0*1e6;              % Raman detuning between repump laser and cooling laser
    fRbGMRepump = fRbGMRepump0 + delta22;   % Grey molasses Repump AOM frequency [Hz]

    DetRbGMCool = Delta22 - 266.65e6;     %cooling laser detuning from F=2 --> F=3' transition
%     s.add('AmpRbRepumpAOM', 0); % Turn off Rb MOT repump AOM
    s.addStep(@SetRbGM,...
        1, 1, DetRbGMCool, IMOT, VShimMolasses, fRbGMRepump, AmpRbGMRepump, tRbGM);
    s.wait(1e-6);
    s.add('AmpRbGMRepumpAOM', 0);       %turn off Rb grey molasses repump AOM
    s.add('AmpRbRepumpAOM', AmpRbRepumpMolasses);       %Switch Rb repump on for OP
end

if(~exist('s1','var'))
    s.run();
end
end

