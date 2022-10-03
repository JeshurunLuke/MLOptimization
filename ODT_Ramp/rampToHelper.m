function ret = rampToHelper(t, len, old_val, new_val)
    RatiosF = [0.9,0.70, 0.5, 0.4];
    %fileloc  = "N:\KRbLab\M_loop\MLoopParam\param.mat";

    %RatiosF = cell2mat(struct2cell(load(fileloc, 'RatiosF')));
    Vend = (old_val-new_val).*RatiosF + new_val;
    Vend = [old_val, Vend, new_val];
    tspace = linspace(0, len, length(Vend));
    for i = 1:(length(tspace)-1)
        if tspace(i) <= t && tspace(i + 1) >= t
            ret = (t - tspace(i))./(tspace(i+1) - tspace(i)).*(Vend(i+1) - Vend(i)) + Vend(i);
        end
    end
end
