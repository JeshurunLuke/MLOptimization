function s = TrackTransfer(s1,tTrip)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tTrip','var'))
   tTrip = 500e-3;
end

% Track motion parameters are set in Soloist motion composer .ab file
% Current active file:
% C:\Users\Public\Documents\Aerotech\Soloist\User Files\transfer_variable_wait_5

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

tTrackTTLOn = 1e-3;

% Trigger the track to start the transfer
s.addStep(tTrackTTLOn) ...
    .add('TTLTrackStart',1);

s.addStep(10e-6) ...
    .add('TTLTrackStart',0); % set the trigger bit back to 0

% Wait for the track to complete the transfer
s.wait((tTrip - tTrackTTLOn));

if(~exist('s1','var'))
    s.run();
end
end