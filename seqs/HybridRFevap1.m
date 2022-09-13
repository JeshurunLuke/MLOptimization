function s = HybridRFevap1(s1, tevap1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tevap1','var'))
    tevap1 = 3;%[s]
end

f0=30e6;%[Hz] initial frequency
fb=0e6;%[Hz] trap bottom frequency

fcut=[4.5].*1e6;% [25,15,3].*1e6;[22,20].*1e6;
tau = [tevap1]; %(f0 - fcut)./cutrate; %[s][8,11,10];[6, 5];
amp=[0.5]; %[V][0.7,0.8,0.8];[0.8,0.8,0.8];
% amp = [0.0];


if min(fcut)<=fb
    error('fcut should > fb');
end
if max(fcut)>=f0
    error('fcut should < f0');
end

fstart=[f0 fcut(1:length(fcut)-1)];
tstage=tau;

if sum(tevap1)>=100
    error('Too long evaporation time!');
end
disp(['RF evap takes ',num2str(sum(tstage)),' s']);
disp(['RF stops at ',num2str(fcut(length(fcut))/1e6),' MHz']);

for i=1:length(tau)
    if i==1
        s.add('FreqRFknife',f0);
    end
    s.add('AmpRFknife',amp(i));
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
%         f=(fstart(i)-fb).*exp(-j.*dt./tau(i))+fb;
        f=fstart(i)-j*dt*(fstart(i)-fcut(i))/tau(i);
%         disp(['f=',num2str(f/1e6),'MHz']);
        s.addStep(dt)...
         .add('FreqRFknife',f);
    end
end

%%------turn off RF knife------
s.add('FreqRFknife',0e6);
s.add('AmpRFknife',0.);

% Make sure the RF evaporation time is >= the cart return time
tRetTrip = 4281e-3; % for "slow" return using "transfer_variable_wait_5.ab"
if sum(tau)<=tRetTrip
    s.wait(tRetTrip - sum(tau));
end

% s.addStep(@MakeRbMOT);

if(~exist('s1','var'))
    s.run();
end

end