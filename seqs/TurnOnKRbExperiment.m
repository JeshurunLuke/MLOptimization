function s = TurnOnKRbExperiment()

% Initialize the sequence
s = ExpSeq();

%Turn on all shutters
s.add('TTLMOTTelescopeShutter', 1);
s.add('TTLOPShutter', 1);
%

%Turn on water flow

s.run();
end