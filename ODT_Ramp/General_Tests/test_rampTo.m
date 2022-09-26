function tester = test_rampTo()
d = rampTo(10);
tlist = linspace(0, 5, 100);
freq = [];
for i = 1:length(tlist)
    f = d(tlist(i),tlist(length(tlist)), 20);
    freq = [freq, f];
end
plot(tlist, freq)
tester = 0;
end
