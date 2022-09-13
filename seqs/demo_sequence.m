function s = demo_sequence(parameter)
% hello world
if nargin == 0
    parameter = 900e-6;
end

% Initialize the sequence
s = ExpSeq();

% The default values are listed in expConfig.m.  Any values not explicitly
% specified at the beginning of the sequence are set to the default values
% specified in expConfig.  If a default value is not specified in the
% config file, then it will be set to 0.  Every sequence updates all TTL
% channels.

% Override default value
s.setDefault('TTL27',1);

% Specify initial values.  Channel names are defined in the config file.
s.add('TTL27',1);
s.add('V4',0);
s.add('V5',0);
s.add('V6',0);

% Use TTL27 as a trigger to indicate the start of the sequence, so wait 10
% us and then turn back off.
s.wait(10e-6);
s.add('TTL27',0);

% Wait 100 us
s.wait(100e-6);

% Add a step that lasts 500 us
s.addStep(500e-6)... %Don't forget the "..."
    .add('V4',linearRamp(0,1))... %Ramp V4 from 0 to 1 over length of step
    .add('V5',jumpTo(1,300e-6)); %Jump V5 to 1 after 300 us

% Add a background step.  This step will execute without advancing the
% current time pointer.  In other words, the step after this one will begin
% at the same time as this step.
s.addBackground(700e-6)... %This step is 500 us long
    .add('V4', rampTo(1/s.CsLOScale));
    %Ramp V4 from its current value to 1/CsLOScale, where CsLOScale is a
    %constant defined in expConfig.m

% As a check, add a step "in the foreground", which should execute at the
% same time.  We will make a sine wave output with 100 us period.
s.addStep(900e-6)...
    .add('V5', @(t) sin(t * 2 * pi / 100e-6));

%% As shown above the pulses added can be a function. It can have up to
%% 3 parameters. Here's a example which uses all of them.
%% Make V4 undergo three sinusoidal oscillations about it's current value
%% for time length "parameter
s.addStep(parameter)...
    .add('V4', @(t, len, old) old + sin(t * 2 * pi / len * 3));

%% For rounding error, hopefully fix soon...
s.wait(1e-9);

% Insert a sub-sequence
s.addStep('demo_step');

% Add a step that goes "backward in time."  Set V4 to putout 1 V for 1
% ms, but tell V5 to go to 1 V 500 us before V4 goes back to zero.
s.wait(100e-6);
s.addStep(1e-3)...
    .add('V4',1);
s.addStep(-500e-6)...
    .add('V5',1);

% Set everything back to zero
s.add('TTL27',06);
s.add('V4',0);
s.add('V5',0);
s.add('V6',0);

% Run the sequence immediately and one time
s.run();

% If you want to run the sequence twice, first with parameter = 1e-3 and
% second with 2e-3, run this from the command line:
% runSeq(@demo_sequence,2,{1e-3},{2e-3})
% If the second argument is 0, will run forever

end
