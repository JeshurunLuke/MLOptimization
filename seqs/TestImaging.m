function s = TestImaging(x)
%% Need to use runSeq(@TestImaging,1) to trigger pixelfly camera

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end
%% -------Imaging shutter timing control-----
tImagingShtrOffDelay = 0e-3;
tImagingShtrOnDelay = 4e-3;
tImagingShtrSkip = 4e-3;
tImagingShtrMinOn = 4e-3;

% For more info see comments in TTLMgr
s.addOutputMgr('TTLImagingShutter', @TTLMgr, ...
    tImagingShtrOffDelay, ... % The time it takes to react to channel turning off 
    tImagingShtrOnDelay, ... % The time it takes to react to channel turning on 
    tImagingShtrSkip, ... % Minimum off time. Off interval shorter than this will be skipped.
    tImagingShtrMinOn); % Minimum on time. On time shorter than this will be extended

s.wait(2);
% %%%-----imaging-----------
% % % %% --------------TOF imaging in evap chamber-----------
TOFRb = 3.0e-3;% TOFRb or TOFK needs to be bigger than texpcam/2+tid=105.6us
TOFK = 1.5e-3;%
m = MemoryMap;
m.Data(1).TOFRb = TOFRb;
m.Data(1).TOFK = TOFK;
% m.Data(1).flagCam=1;
Bstatus = 0;
if Bstatus
    s.addStep(@preimaging, 770e6, 0*6.1e6, -760e6, 0, Bstatus); % for 550G; Rb Taken on 8/7/2018, K taken on 8/7/2018
else
%     s.addStep(@preimaging, 42.4e6, 0, -31.6e6, 0, Bstatus); % for 30G; for K -9/2;  Taken on 7/27/2018
    s.addStep(@preimaging, 27.48e6, 0*6.1e6, 33.4e6, 0.*6.1e6, Bstatus);
end
s.wait(100e-3);        %need to wait for >1.5s for open camera
s.addStep(@imagingTOF, TOFRb, TOFK, Bstatus);%enable this for normal operation

if(~exist('s1','var'))
    s.run();
end

end