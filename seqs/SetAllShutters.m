function SetAllShutters(TTL)
% SetAllShutters(TTL), TTL = 1 for open, 0 for closed.  TTL is optional,
% and default is 0.

if nargin == 0
    TTL = 0;
end

s = ExpSeq();

s.add('TTLMOTShutter', TTL);
s.add('TTLCsOPShutter', TTL);
s.add('TTLCsMOTRPShutter', TTL);
s.add('TTLCsOPRPShutter', TTL);
s.add('TTLCsMOTCoolShutter', TTL);

s.run();
