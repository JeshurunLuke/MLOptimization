function s = Test3()
s = ExpSeq();
s.findDriver('FPGABackend').setTimeResolution(10e-3);%set the time stepsize

f0=40e6;%[Hz] initial frequency
fb=2e6;%[Hz] trap bottom frequency

fcut=[20 7 3].*1e6;
tau=[5 3 2]; %[s]
amp=[0.1 0.05 0.01];

if min(fcut)<=fb
    error('fcut should > fb');
end
if max(fcut)>=f0
    error('fcut should <f0');
end

fstart=[f0 fcut(1:length(fcut)-1)];
tstage=-tau.*log((fcut-fb)./(fstart-fb));
disp(['t=',num2str(sum(tstage)),'s'];

for i=1:length(tau)
    if i==1
        s.add('FreqRFknife',f0);
    end
    s.add('AmpRFknife',amp(i));
    s.addStep(tstage(i))...
        .add('FreqRFknife',@(t) (fstart(i)-fb).*exp(-t./tau(i))+fb);
end
s.add('FreqRFknife',0e6);
s.add('AmpRFknife',0.0);



% s.add('TTLscope',0);%Default Scope trigger
% s.wait(0.2);
% s.addStep(@MakeRbMOT);%, TOFRb, TOFK)
% s.wait(2);

% % % --------------TOF imaging in evap chamber-----------
% TOFRb=3e-3;%[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
% TOFK=20e-3;%[s]
% ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
% s.wait(ShutterDelay);
% s.addStep(@Qtrapoff);      %turn off the trap, takes no time
% s.add('TTLscope',1); %trigger oscilloscope
% % s.wait(1e-3);
% s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
% s.addStep(@imagingTOF, TOFRb, TOFK);
% % --------------Rb Molasses----------
% tMolas=20e-3;%[s]The time duration of molasses
% s.addStep(@RbMolasses,tMolas);%takes 20ms

% %%%---TOF OD imaging-----
% s.wait(1);
% % s.addStep(@Qtrapoff);
% %
% % TOFRb=3e-3;%[s]
% % TOFK=7e-3;%[s]
% % s.addStep(@imagingTOF, TOFRb, TOFK)
%
% %--------------TOF imaging in evap chamber-----------
% TOFRb=5e-3;%[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
% TOFK=7e-3;%[s]
% ShutterDelay = 10e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
% s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
% s.wait(ShutterDelay);
% s.addStep(@Qtrapoff);      %turn off the trap, takes no time
% s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
% s.addStep(@imagingTOF, TOFRb, TOFK);
% s.addStep(@SetRbMOTBeamsAndB,...
%     1,1, -23e6, 200, [0,0,0,0], 0.09, 1e-6);
s.run();

end