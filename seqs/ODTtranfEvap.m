function s = ODTtranfEvap(s1, Vtransf0, VODT2)
%%%%%%%%%%%%%%%%%%%%%
%%%reduce ODT power by exponential decay P(t)=P0*exp(-t/tau1) with t=0 to
%%%t1 (t1 satisfies P0*exp(-t1/tau1)=P1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

VODT0 = Vtransf0; %Vtransf0;    %DAC value 0-6V, negative means off
VODTmin = 0.00;  %Minimum ODT power
%%----------set parameters for different evap stages--------
VODT = [1.5, 0.05];    %[V]  W/V
% VODT = [0.8];    %[V]  W/V
tau = [0.5, 2];         % 0.8 [s]

Vstart = [VODT0 VODT(1:length(VODT)-1)];
tstage = -tau.*log((VODT-VODTmin)./(Vstart-VODTmin));
tau = tau.*sign(tstage);
tstage=abs(tstage);
tODTevap = sum(tstage);
if length(VODT)~= length(tau)
    error('Length of VODT should equal length of tau');
end

if min(VODT)<=VODTmin
    error('VODTtransf should > 0');
end
if max(VODT)> VODT0
    error('VODTtransf should <= VODTtransf0');
end

if tODTevap >= 100 %[s]
    error('Too long ODT evaporation time!');
end
disp(['ODT evap takes ',num2str(tODTevap),'s']);

for i=1:length(tau)
    if i==1
        s.add('ODTtransf',VODT0);
        s.add('TTLODT2',1);
        s.add('ODT2', 0.01);
    end

    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        V1=(Vstart(i)-VODTmin).*exp(-j.*dt./tau(i))+VODTmin;
%         disp(['V1=',num2str(V1),' ']);
%         s.addStep(dt)...
        s.add('ODTtransf',V1);
        if i == 1
            V2 = VODT2*j/Nj;
            s.add('ODT2', V2);
        end
        s.wait(dt);
    end
end
% disp(['V1 = ',num2str(V1)]);


if(~exist('s1','var'))
    s.run();
end

end