function s = ramp2Norm(s1, V0, N, t, x)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%compute time and voltage step
dt = t/N;
dV = (x-V0)/N;
ti = 0; 
Vlist = [];
Tlist = [];
for i = 1:N
    V = V0 + i*dV;
    ti = ti + dt;
    Tlist = [Tlist, ti];
    Vlist = [Vlist, V];
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