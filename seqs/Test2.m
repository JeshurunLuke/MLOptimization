function s = Test2(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

% s.disableChannel('VctrlCoilServo4');

%% ==== Science chamber imaging Feshbach coil parameters
% BSciImgFld = 30.0;     %[G] 19.84
% ISciImgFld = BSciImgFld./s.C.FeshbachGperA;      %[A] B=19.84 G, Feshbach coil conversion ratio is 2.5969 G/A
% tSciImgFld = 10e-3;              % Ramp on time for the science chamber imaging field
% VfbCoil = - ISciImgFld/s.C.FeshbachCoilIV;
% s.addStep(tSciImgFld) ...
%     .add('VctrlCoilServo4', rampTo(VfbCoil));
% s.wait(200e-3);
% % s.addStep(5e-6)...
% %     .add('TTLscope',1);
% % dtt = s.curTime - 5e-6;
% % disp(['dtt = ', num2str(dtt)]);
%% ------Ramp down across Feshbach resonance---------------
% BFR1 = 550;        %[G]
% tFR1 = 10e-3;     %[s]
% IFR1 = BFR1./s.C.FeshbachGperAHB;     %use FeshbachGperAHB for high B
% s.addStep(@fbCoilRampOn,IFR1,tFR1);
% % dtt = s.totalTime();
% % disp(['dtt = ', num2str(dtt)]);
% s.wait(200e-3);
% % s.addStep(tFR1)...
% %     .add('VctrlCoilServo3', rampTo(-2));

%% ------Ramp down across Feshbach resonance---------------
% BFR2 = 545.5;       %[G] 545.5
% tFR2 = 3e-3;        % 3e-3 %[s]
% 
% % % Use Feshbach coil for ramp
% % IFR2 = BFR2./s.C.FeshbachGperAHB;
% % s.add('TTLscope',1);
% % s.addStep(@fbCoilRampOn,IFR2,tFR2);
% 
% % Use fast B coil for ramp
% BFB2 = BFR1 - BFR2;
% IFB2 = BFB2./s.C.FastBCoilGperA;
% s.add('TTLscope',1);
% s.addStep(@fastBCoilRampOn,IFB2,tFR2);

%% ------Ramp down across Feshbach resonance---------------
% BFR21 = 544.1;        % [G] was at 544.5 G
% tFR21 = 0.1e-3;     %0.1e-3 [s]
% 
% % % Use Feshbach coil for ramp
% % IFR21 = BFR21./s.C.FeshbachGperAHB;
% % s.addStep(@fbCoilRampOn,IFR21,tFR21);
% 
% % Use fast B coil for ramp
% BFB21 = BFR1 - BFR21;
% IFB21 = BFB21./s.C.FastBCoilGperA;
% s.addStep(@fastBCoilRampOn,IFB21,tFR21);
% 
% s.wait(0.650e-3);
% fARPKill = 8036.25*1e6; %8036.25 8037.75e6; %8037.50; 8036e6; for 2 ms; 8038.75 for 1 ms
% dfKill = 1e6;
% % s.add('TTLscope',1);
% s.addStep(@RbARPKill, fARPKill, dfKill, 0.5e-3);
% s.wait(1e-6);

%% ------Ramp up for imaging-------------
% BFR3 = 550;        %[G]
% tFR3 = 0.1e-3;     %[s]
% 
% % % Use Feshbach coil for ramp
% % IFR3 = BFR3./s.C.FeshbachGperAHB;
% % s.addStep(@fbCoilRampOn,IFR3,tFR3);
% 
% % % Use fast B coil for ramp
% BFB3 = BFR1 - BFR3;        %[G]
% IFB3 = BFB3./s.C.FastBCoilGperA;
% s.addStep(@fastBCoilRampOn,IFB3,tFR3);
% 
% % s.add('TTLscope',1);
% s.wait(8e-3);
% s.wait(500e-3);
% % s.add('TTLscope',1);
%% ------Ramp down for ionization-------------
% BFR3 = 30;        %[G]
% tFR3 = 10e-6;     %[s]
% IFR3 = BFR3./s.C.FeshbachGperA;
% VfbCoil3 = - IFR3/s.C.FeshbachCoilIV;
% % s.addStep(@fbCoilRampOn,IFR3,tFR3);
% s.addStep(tFR3) ...
%     .add('VctrlCoilServo4', rampTo(VfbCoil3));
% s.wait(100e-3);

% s.addStep(@fbCoilRampOn,0,10e-3);           %turn off Feshbach coill
% s.addStep(@fastBCoilRampOn,0,10e-3);           %turn off FastB coill

%% ----- Pulse on 970 nm light ----------
% t_STIRAP_on = 10e-6; %[s]
% s.addStep(t_STIRAP_on)...
%     .add('AmpStirapAOM970', 0.475)...
%     .add('AmpStirapAOM690', 0.0);
% s.add('TTLSTIRAPShutter', 1);
% s.wait(100e-3);
% s.add('TTLscope',1)...
%     .add('TTLSTIRAPShutter', 0);
% s.wait(10e-3);
% s.add('AmpStirapAOM970', 0.0)...
%     .add('AmpStirapAOM690', 0.0);
% 
% s.wait(100e-3);

%% -------- STIRAP ----------
STIRAPShutterDelay = 4.0e-3;

s.addStep(STIRAPShutterDelay)...
    .add('TTLSTIRAPShutter', 1);

AmpDDS970 = 0.475;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
AmpDDS690 = 0.300;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
AmpDDSKKill = 0.300;        % DDS amplitude for K kill pulse after GS molecule step

FreqDDS970_1 = 80.0e6;
FreqDDS690_1 = 80.0e6;
%     FreqDDS970_2 = 80.0e6;
FreqDDS690_2 = 80e6;%79.4e6;

dtSTIRAPramp = 4e-6;
t_STIRAP_fwd = 7e-6 + dtSTIRAPramp; %[s]
t_STIRAP_GS = 8e-6;%[s]
t_STIRAP_bk = t_STIRAP_fwd; %[s]
t_STIRAP_wait = 24e-6;%x*1e-3; %[s] wait time between FW and BK STIRAP
t_STIRAP_wait_min = 24e-6; %[s]

if t_STIRAP_wait < t_STIRAP_wait_min
    error('t_STIRAP_wait needs to be >= t_STIRAP_wait_min')
end
s.add('TTLscope',1);
%%-----------Forward STIRAP-----------
s.add('FreqStirapAOM970', FreqDDS970_1)...
    .add('FreqStirapAOM690', FreqDDS690_1);
s.add('TTLSTIRAPTrig',1);
s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
    .add('AmpStirapAOM970', AmpDDS970)...
    .add('AmpStirapAOM690', AmpDDS690);
s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
    .add('AmpStirapAOM690', 0.0)...
    .add('TTLSTIRAPTrig',0);
s.addStep(t_STIRAP_bk)...
    .add('AmpKOPRepumpAOM', AmpDDSKKill);
s.add('TTLscope',0);
s.add('AmpKOPRepumpAOM', 0.0);
%%-----------hold at GS KRb-------------
s.wait(t_STIRAP_wait - t_STIRAP_wait_min + 1.5e-6);
%%-----------Backbard STIRAP-----------
s.add('FreqStirapAOM970', FreqDDS970_1)...
    .add('FreqStirapAOM690', FreqDDS690_2);
s.addStep(t_STIRAP_fwd)...
    .add('TTLSTIRAPTrig', 1);
s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
    .add('AmpStirapAOM970', AmpDDS970)...
    .add('AmpStirapAOM690', AmpDDS690)...
    .add('TTLImagingShutter', 0);
s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
    .add('AmpStirapAOM690', 0.0);
s.add('TTLSTIRAPTrig',0);

s.add('TTLSTIRAPShutter', 0);

s.wait(100e-3);
%% -------- STIRAP again----------
% FreqDDS970_2 = 80.0e6;
% FreqDDS690_2 = 85.0e6;
% 
% s.add('TTLSTIRAPTrig',1);
% 
% s.add('FreqStirapAOM970', FreqDDS970_2)...
%     .add('FreqStirapAOM690', FreqDDS690_2);
% 
% s.addStep(t_STIRAP_fwd+t_STIRAP_GS)...
%     .add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0)...
%     .add('TTLSTIRAPTrig',0);
% s.addStep(t_STIRAP_bk)...
%     .add('AmpKOPRepumpAOM', AmpDDSKKill);
% s.wait(50e-6);
% s.add('AmpKOPRepumpAOM', 0.0);
% % s.wait(x*1e-6);
% 
% % s.wait(t_STIRAP_wait - t_STIRAP_wait_min + 1.5e-6);
% 
% s.addStep(t_STIRAP_fwd)...
%     .add('TTLSTIRAPTrig', 1);
% s.addStep(t_STIRAP_bk+t_STIRAP_GS)...
%     .add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690)...
%     .add('TTLKImagingShutter', 0);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0);
% s.add('TTLSTIRAPTrig',0);

%% STIRAP roundtrip
% AmpDDS970 = 0.0;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% AmpDDS690 = 0.385;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% AmpDDSKKill = 0.3;        % DDS amplitude for K kill pulse after GS molecule step
% % AmpDDS970 = 0;      % 0.35x1.3571=0.475 [V] max power of 970nm laser, 27 mW
% % AmpDDS690 = 0;        %0.3x1.2833=0.385 [V] max power of 690nm laser, 4.45 mW
% % AmpDDSKKill = 0.0;
% 
% t_STIRAP = 35e-6; %[s]
% t_KKill = 40e-6;
% 
% s.add('AmpStirapAOM970', AmpDDS970)...
%     .add('AmpStirapAOM690', AmpDDS690);
% s.add('TTLscope',1)...
%     .add('TTLSTIRAPTrig',1);
% s.wait(t_STIRAP);
% s.add('AmpStirapAOM970', 0.0)...    % turn off STIRAP lasers
%     .add('AmpStirapAOM690', 0.0)...
%     .add('AmpKOPRepumpAOM', AmpDDSKKill);
% s.wait(t_KKill);
% s.add('TTLscope',0)...
%     .add('TTLSTIRAPTrig',0)...
%     .add('AmpKOPRepumpAOM', 0.0)...
%     .add('TTLKImagingShutter', 0);

s.add('TTLscope',0);

s.run();

end
