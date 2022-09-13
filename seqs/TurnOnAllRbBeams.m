function s = TurnOnAllRbBeams()

% Initialize the sequence
s = ExpSeq();

%Turn on all shutters
s.add('TTLMOTTelescopeShutter', 0);
s.add('TTLOPShutter', 1);

%Turn on all AOMs
s.add('AmpRbOPZeemanAOM', 0.250);
s.add('AmpRbOPRepumpAOM', 0.250);
s.add('AmpRbRepumpAOM', 0.090);

s.run();
end