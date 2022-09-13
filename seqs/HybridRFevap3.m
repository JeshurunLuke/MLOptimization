function s = HybridRFevap3(s1)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if(~exist('tevap3','var'))
    tevap3 = 4;%[s]
end

IBleeder0 = 1.4;      %[A] 7.5 A corresponds to 80 G/cm
VBleeder0 = - IBleeder0/s.C.QUICCoilIV;

IBleeder = (27/2)/(15/1.4);      %[A] 7.5 A corresponds to 80 G/cm
VBleeder = - IBleeder/s.C.QUICCoilIV;


VODT0=4.0;    %DAC value 0-6V, negative means off
VODTmin = 0.00;  %Minimum ODT power
%%----------set parameters for different evap stages--------
VODT = [0.5,4.0];    %[V]  W/V
tau = [1.5,2];         % 0.8 [s]

Vstart = [VODT0 VODT(1:length(VODT)-1)];
tstage = -tau.*log((VODT-VODTmin)./(Vstart-VODTmin));
tau = tau.*sign(tstage);
tstage=abs(tstage);
tODTevap = sum(tstage);

if sum(tevap3)>=100
    error('Too long evaporation time!');
end

for i=1:length(tau)
    if i==1
        s.add('ODT1',VODT0);
    end
    Nj=300;
    dt=tstage(i)/Nj;
    s.wait(dt);
    for j=1:Nj
        V1=(Vstart(i)-VODTmin).*exp(-j.*dt./tau(i))+VODTmin;
        if i==1
            VBleederj = VBleeder0 -j*dt*(VBleeder0-VBleeder)/tstage(1);
            s.addStep(dt)...
             .add('ODT1',V1)...
             .add('VctrlCoilServo2', VBleederj);
        else
            s.add('VctrlCoilServo2', 0.25);
        end
    end
end

if(~exist('s1','var'))
    s.run();
end

end