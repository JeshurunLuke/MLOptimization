function s = mainImagingTest(index1)

s = ExpSeq();

if ~exist('index1','var')
    index1=0;
end
disp(['index1=',num2str(index1)]);
% s.add('TTLscope',0);%Default Scope trigger
% s.wait(0.2);
% s.addStep(@MakeRbMOT);%, TOFRb, TOFK)
% s.wait(2);

s.wait(3);
% % --------------TOF imaging in evap chamber-----------
TOFRb=10e-3;%[s]TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK=7e-3;%[s]
ShutterDelay = 2.8e-3; % Delay between TTL on and shutter on/off, emprically determined on 02/29/16
s.addStep(@preimaging);  %% set up imaging frequency, open up imaging shutter, takes no time
s.wait(ShutterDelay);
s.addStep(@Qtrapoff);      %turn off the trap, takes no time
s.add('TTLscope',1); %trigger oscilloscope
% s.wait(1e-3);
s.addStep(@QuantFieldOn);   % turn on the imaging field at 30G, takes no time
s.addStep(@imagingTOF, TOFRb, TOFK);

s.run();

end