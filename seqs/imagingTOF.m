function s=imagingTOF(s1, TOFRb, TOFK, Bstatus)
%function s = imaging_TOF(TOFRb, TOFK) is for time of flight imaging
% Input parameters
% TOFRb Rb time-of-flight [ms]
% TOFK K time-of-flight [ms]
% Bstatus ---- %0 means low B (~30G), 1 means high B (~550G);

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('TOFRb','var')
    TOFRb=10e-3;%[s]
    disp(['TOFRb=',num2str(TOFRb*1000),' ms']);
end
if ~exist('TOFK','var')
    TOFK=5e-3;%[s]
    disp(['TOFK=',num2str(TOFK*1000),' ms']);
end
if(~exist('Bstatus','var'))
    Bstatus = 0;        %0 means low B (~30G), 1 means high B (~550G)
end
%% ----relevant times -----------
texp=100e-6;%[s](should < texpcam)laser pulse length or effective exposure time; was 200 us; changed to 50 us on 11/29/16
texpcam=0.5e-3;%[s]camera exposure; NEED TO CHANGE IN CAMERA SCRIPT!
tid=5.6e-6;%[s]camera internal time delay
titf=1e-6;%[s]camera internal time delay
tframe=400e-3;%[s] interframe time should > treadout (275ms)
PbeamRb=0.20;% was 0.25 with ND2 filter 0.15, changed to 0.08 on 2/14/2018, changed to 0.10 on 1/30/18; was 0.25, changed to 0.3 on 11/29/16; do not exceed 0.38
if Bstatus
    PbeamK = 0.12;           %for highB
else
    PbeamK = 0.08;          %0.15 for lowB, 0.07for highB do not exceed 0.38;
end

%% ----set time of flight--------
if abs(TOFK-TOFRb)<=((texpcam)/2+titf)
    error('abs(TOFK-TOFRb) need to be bigger!');
end
if TOFK<=(texpcam/2+tid)
    error(['TOFK should >',num2str(texpcam/2+tid),' s']);
end
if TOFRb<=(texpcam/2+tid)
    error(['TOFRb should >',num2str(texpcam/2+tid),' s']);
end
frac = 0.5;
if (TOFK<TOFRb)
    t1=TOFK-texpcam*frac-tid;
else
    t1=TOFRb-texpcam*frac-tid;
end

t2=abs(TOFRb-TOFK)-texp;
if t2 <= 0
    error(['abs(TOFK-TOFRb) need to be bigger than',num2str(texp),' s']);
end

s.wait(t1);
s.add('TTLQuicCamera',1)...
    .add('TTLImagingShutter', 1);
%% ----1st trigger for Shadow frame----------
s.wait(texpcam*frac+tid);

if TOFK > TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('AmpRbOPZeemanAOM', 0.00);
    s.wait(t2);                         %wait for t2 imaging
    if Bstatus
        s.addStep(texp)...
            .add('AmpKOPRepumpAOM', PbeamK);
    else
        s.addStep(texp)...
            .add('AmpKOPZeemanAOM', PbeamK);
    end
    s.add('TTLQuicCamera',0)...
        .add('AmpKOPZeemanAOM', 0.00)...
        .add('AmpKOPRepumpAOM', 0.00)...
        .add('TTLImagingShutter',0);       %turn off imaging shutter
else
    if Bstatus
        s.addStep(texp)...
            .add('AmpKOPRepumpAOM', PbeamK);
    else
        s.addStep(texp)...
            .add('AmpKOPZeemanAOM', PbeamK);
    end
    s.add('AmpKOPZeemanAOM', 0.00)...
        .add('AmpKOPRepumpAOM', 0.00);
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('TTLQuicCamera',0)...
        .add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLImagingShutter',0);%turn off imaging shutter
end

%% Turn off imaging quantization fields
s.add('Vquant1', 0);%turn off the imaging quantization field
s.add('VctrlCoilServo4', 0.5);%turn off the imaging quantization field
s.add('VctrlCoilServo5', 0.5);%turn off the imaging quantization field

%% ----2nd trigger for Light frame----------
s.wait(tframe-2.8e-3-TOFRb);
s.add('TTLImagingShutter',1);%imaging beam shutter opens 10ms before imaging pulse
% s.add('TTLKImagingShutter',1);%imaging beam shutter opens 10ms before imaging pulse
s.wait(2.8e-3+TOFRb-texpcam*frac-tid);
s.add('TTLQuicCamera',1);
s.wait(texpcam*frac+tid);
if TOFK>TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('AmpRbOPZeemanAOM', 0.00);%
    s.wait(t2);%wait for t2 imaging
    if Bstatus
        s.addStep(texp)...
            .add('AmpKOPRepumpAOM', PbeamK);
    else
        s.addStep(texp)...
            .add('AmpKOPZeemanAOM', PbeamK);
    end
    s.add('TTLQuicCamera',0)...
        .add('AmpKOPZeemanAOM', 0.00)...
        .add('AmpKOPRepumpAOM', 0.00)...
        .add('TTLImagingShutter',0);       %turn off imaging shutter
else
    if Bstatus
        s.addStep(texp)...
            .add('AmpKOPRepumpAOM', PbeamK);
    else
        s.addStep(texp)...
            .add('AmpKOPZeemanAOM', PbeamK);
    end
    s.add('AmpKOPZeemanAOM', 0.00)...
        .add('AmpKOPRepumpAOM', 0.00);
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('TTLQuicCamera',0)...
        .add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLImagingShutter',0);%turn off imaging shutter
end

%% ----3rd trigger for background frame----------
s.wait(tframe-2.8e-3-TOFRb);
% s.add('TTLImagingShutter',0);
s.wait(2.8e-3+TOFRb-texpcam*frac-tid);
s.add('TTLQuicCamera',1);
s.wait(texpcam*frac+tid);
if TOFK > TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', 0);
    s.wait(t2);                     %wait for t2 imaging
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', 0.0)...
        .add('AmpKOPRepumpAOM', 0.0);
    s.add('TTLQuicCamera',0);
else
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', 0.0)...
        .add('AmpKOPRepumpAOM', 0.0);
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', 0);
    s.add('TTLQuicCamera',0);
end
s.wait(tframe);

if(~exist('s1','var'))
    s.run();
end

end