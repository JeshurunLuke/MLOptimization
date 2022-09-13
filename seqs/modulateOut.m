%% Copyright (c) 2014-2014, Yichao Yu <yyc1992@gmail.com>
%%
%% This library is free software; you can redistribute it and/or
%% modify it under the terms of the GNU Lesser General Public
%% License as published by the Free Software Foundation; either
%% version 3.0 of the License, or (at your option) any later version.
%% This library is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%% Lesser General Public License for more details.
%% You should have received a copy of the GNU Lesser General Public
%% License along with this library.

%%5/22 --Lee added line 22 to shut off the piezo modulation--it was on when
%%I came in this morning.
function s = modulateOut(chn, freq, amp, offset, cycle)
  %% If you want to edit this file to set parameters you are looking at
  %% wrong place. Use
  %% runSeq(@modulateOut, ..., {'channel', freq, amp, offset, cycle})
  %% to set the parameters for runSeq. DO NOT hard code them in this file
  %% EVER.
  s = ExpSeq();
  % Both the fpga box and matlab are super slow at parsing commands
  % Limit the time resolution so it does not take forever.
  % s.findDriver('FPGABackend').setTimeResolution(1 / freq / 500);
  s.addStep(cycle / freq) ...
   .add(chn, @(t, len, old) offset + amp .* sin(2 .* pi .* freq .* t));

  %% Sequence running is disabled if called within #runSeq()
  s.run();
end
