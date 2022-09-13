function s=imagingTOFuwave(s1, TOFRb, TOFK)
%Temporary file for testing u-wave

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
%----relevant times -----------
texp=100e-6;%[s](should < texpcam)laser pulse length or effective exposure time; was 200 us; changed ot 50 us on 11/29/16
texpcam=0.5e-3;%[s]camera exposure; NEED TO CHANGE IN CAMERA SCRIPT!
tid=5.6e-6;%[s]camera internal time delay
titf=1e-6;%[s]camera internal time delay
tframe=400e-3;%[s] interframe time should > treadout (275ms)
PbeamRb=0.3;%0.01; was 0.1, changed to 0.3 on 11/29/16; do not exceed 0.38
PbeamK=0.10;% set on 12/01; do not exceed 0.38

%----set time of flight--------
if abs(TOFK-TOFRb)<=((texpcam)/2+titf)
    error('abs(TOFK-TOFRb) need to be bigger!');
end
if TOFK<=(texpcam/2+tid)
    error(['TOFK should >',num2str(texpcam/2+tid),' s']);
end
if TOFRb<=(texpcam/2+tid)
    error(['TOFRb should >',num2str(texpcam/2+tid),' s']);
end

if (TOFK<TOFRb)
    t1=TOFK-texpcam/2-tid;
else
    t1=TOFRb-texpcam/2-tid;
end
t2=abs(TOFRb-TOFK)-texp;
%%%---add u-wave operation----
% s.wait(t1);
s.addStep(@uwave,t1);
%%%---------------------------
s.add('TTLQuicCamera',1);
%----1st trigger for Shadow frame----------
s.wait(texpcam/2+tid);
if TOFK>TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb)...
        .add('TTLscope',1);
    s.add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLRbImagingShutter',0);%turn off imaging shutter
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', PbeamK);
    s.add('TTLQuicCamera',0)...
        .add('AmpKOPZeemanAOM', 0.00)...
        .add('TTLKImagingShutter',0);%turn off imaging shutter
else
   s.addStep(texp)...
        .add('AmpKOPZeemanAOM', PbeamK)...
        .add('TTLscope',1);
    s.add('AmpKOPZeemanAOM', 0.00)...
        .add('TTLKImagingShutter',0);%turn off imaging shutter
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('TTLQuicCamera',0)...
        .add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLRbImagingShutter',0);%turn off imaging shutter
end

s.add('Vquant1', 0);%turn off the imaging quantization field

%----2nd trigger for Light frame----------
s.wait(tframe-2.8e-3-TOFRb);
s.add('TTLRbImagingShutter',1);%imaging beam shutter opens 10ms before imaging pulse
s.add('TTLKImagingShutter',1);%imaging beam shutter opens 10ms before imaging pulse
s.wait(2.8e-3+TOFRb-texpcam/2-tid);
s.add('TTLQuicCamera',1);
s.wait(texpcam/2+tid);
if TOFK>TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLRbImagingShutter',0);%
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', PbeamK);
    s.add('TTLQuicCamera',0)...
        .add('AmpKOPZeemanAOM', 0.00)...
        .add('TTLKImagingShutter',0);%turn off imaging shutter
else
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', PbeamK);
    s.add('AmpKOPZeemanAOM', 0.00)...
        .add('TTLKImagingShutter',0);%turn off imaging shutter
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', PbeamRb);
    s.add('TTLQuicCamera',0)...
        .add('AmpRbOPZeemanAOM', 0.00)...
        .add('TTLRbImagingShutter',0);%turn off imaging shutter
end

%----3rd trigger for background frame----------
s.wait(tframe-2.8e-3-TOFRb);
s.add('TTLRbImagingShutter',0);
s.add('TTLKImagingShutter',0);
s.wait(2.8e-3+TOFRb-texpcam/2-tid);
s.add('TTLQuicCamera',1);
s.wait(texpcam/2+tid);
if TOFK>TOFRb
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', 0);
    s.add('TTLRbImagingShutter',0);%
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', 0);
    s.add('TTLQuicCamera',0)...
        .add('TTLKImagingShutter',0);%turn off imaging shutter
else
    s.addStep(texp)...
        .add('AmpKOPZeemanAOM', 0);
    s.add('TTLKImagingShutter',0);%turn off imaging shutter
    s.wait(t2);%wait for t2 imaging
    s.addStep(texp)...
        .add('AmpRbOPZeemanAOM', 0);
    s.add('TTLQuicCamera',0)...
        .add('TTLRbImagingShutter',0);%turn off imaging shutter
end
s.wait(tframe);

if(~exist('s1','var'))
    s.run();
end

end