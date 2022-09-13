function s = TrackTransfer(s1,tTrip)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Trigger the track to transfer forward
s.addStep(tTrackTTLOn) ...
    .add('TTLTrackStart',1);

s.addStep(10e-6) ...
    .add('TTLTrackStart',0); % set the trigger bit back to 0

% Wait for the track to complete the forward transfer
s.wait((tTrip - tTrackTTLOn));

if(~exist('s1','var'))
    s.run();
end
end