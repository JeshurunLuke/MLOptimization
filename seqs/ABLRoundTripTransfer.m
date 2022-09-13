function s = ABLRoundTripTransfer(s1)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

tODTFwdTrip = 702e-3; % Using motion file ABL_test_2 or ABL_test_3
tODTRetTrip = tODTFwdTrip; % Using motion file or ABL_test_3
% s.addStep(10e-6) ...
%     .add('TTLuwaveampl',1);
s.addStep(@ABLTransfer,tODTFwdTrip);
% s.wait(100e-3);
% s.add('Vquant2',0);         %turn off the small transfer quant field coil
% s.wait(x);
s.addStep(@ABLTransfer,tODTRetTrip);
% s.wait(x*1e-3);

% s.addStep(10e-6) ...
%     .add('TTLuwaveampl',0);

if(~exist('s1','var'))
    s.run();
end

end