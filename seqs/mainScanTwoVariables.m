x1s = 13.75;
x2s = [6];
xlist = {};
for x1 = x1s
    for x2 = x2s
        xlist{end + 1} = {x1, x2};
    end
end
runScan(@mainHighB, 1, xlist{:})