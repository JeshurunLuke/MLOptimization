function s = lowbARPs(s1, ISciImgFld, Ikill, x)
if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%%%-------Rb ARP-----------
fARP = 6897.9;           %[MHz]
s.addStep(@RbuwaveARP, fARP);     %Rb ARP between |22> and |11>

%%--------Rb kill--------------
s.addStep(@fbCoilRampOn,Ikill,5e-3);
s.addStep(@Rbkill);     %blasting beam
s.addStep(@fbCoilRampOn,ISciImgFld,5e-3);
s.wait(10e-3);

%-----K ARP--------
s.addStep(@KrfARP, x);       %incldue K RF ARP from |9/2,9/2> to |9/2,-9/2>

if(~exist('s1','var'))
    s.run();
end

end