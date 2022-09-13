function s = ramp2(s1, chName, V0, N, t, x)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

%compute time and voltage step
dt = t/N;
dV = (x-V0)/N;

for i = 1:N
    V = V0 + i*dV;

    s.addStep(dt) ...
        .add(chName, V);
%     s.add(chName,V);
%     s.wait(dt);

end


if(~exist('s1','var'))
    s.run();
end

end