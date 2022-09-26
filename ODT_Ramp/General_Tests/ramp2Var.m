function s = ramp2Norm(V0, N, t, x)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end



Regions = 5;
Vend = (V0-x).*[0.9,0.70, 0.5, 0.4] + x;
Vend = [V0, Vend, x];
disp(Vend)
%compute time and voltage step
dt = t/N;
Npart = N/Regions;
ti = 0; 
Vlist = [];
Tlist = [];
for j = 1:Regions
    dV = (Vend(j+1)-Vend(j))/Npart;
    for i = 1:Npart
        V = Vend(j) + i*dV;
        ti = ti + dt;
        Tlist = [Tlist, ti];
        Vlist = [Vlist, V];
    end

    %s.addStep(dt) ...
    %    .add(chName, V);
%     s.add(chName,V);
%     s.wait(dt);

end
plot(Tlist, Vlist)


%if(~exist('s1','var'))
%    s.run();
%end

end