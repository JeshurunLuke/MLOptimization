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

function s = setChns(varargin)
  %% Sequence to set specified channels to specified values
  %% You can set multiple channels altogether by adding multiple channel value
  %% pairs in the argument either with: `channel_name, value` or
  %% `{channel_name, value}`.
  chns = {};
  vals = [];

  ResetMemoryMap;

  if nargin == 0
    error('Please specify at least one channel to set');
  end

  i = 1;
  while i <= nargin
    arg = varargin{i};
    if iscell(arg)
      if size(arg, 2) < 2
        error('No channel name or value to set to.');
      elseif size(arg, 2) == 2
        name = arg{1};
        value = arg{2};
        if ~ischar(name)
          error('Channel name has to be a string.');
        elseif ~isnumeric(value)
          error('Output value has to be a number.');
        end
        chns{end + 1} = name;
        vals(end + 1) = value;
      elseif size(arg, 2) > 2
        error('Too many argument for one channel.');
      end
    elseif ischar(arg)
      name = arg;
      i = i + 1;
      if i > nargin
        error('No value to set');
      end
      value = varargin{i};
      if ~isnumeric(value)
        error('Output value has to be a number.');
      end
      chns{end + 1} = name;
      vals(end + 1) = value;
    else
      error('Invalid argument type');
    end
    i = i + 1;
  end

  names = cellfun(@(s) ['-', strrep(s, '/', '_')], chns, ...
                  'UniformOutput', false);

  s = ExpSeq();

  for i = 1:size(vals, 2)
    s.add(chns{i}, vals(i));
  end

  %% Sequence running is disabled if called within #runSeq()
  s.run();
end
