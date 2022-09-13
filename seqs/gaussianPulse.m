function s = gaussianPulse()

s = ExpSeq();

% Gaussian pulse parameters
amp_970 = 0.25;
sigma_970 = 50e-6;
mu_970 = 73.5e-4;

amp_690 = 0.1;
sigma_690 = 50e-6;
mu_690 = 75e-4;

% Initial laser power set to 0
s.addStep(0.1) ...
    .add('AmpStirapAOM690', 0)...
    .add('AmpStirapAOM970', 0);

s.wait(1)

% Trigger photodiode
% s.add('TTLTest',1);

s.addStep(10e-6) ...
    .add('AmpStirapAOM690', 0.1);
s.wait(10e-6);
s.addStep(10e-6) ...
    .add('AmpStirapAOM690', 0);
s.wait(100e-6);

% Pulse modulation
s.addStep(20e-3) ...
    .add('AmpStirapAOM970', @(t) amp_970.*exp(-((t-mu_970).^2)/(2*sigma_970.^2)))...
    .add('AmpStirapAOM690', @(t) amp_690.*exp(-((t-mu_690).^2)/(2*sigma_690.^2)));

% s.addStep(20e-3) ...
%     .add('AmpStirapAOM970', @(t) amp_970.*exp(-((t-mu_970).^2)/(2*sigma_970.^2)));

s.run();

end