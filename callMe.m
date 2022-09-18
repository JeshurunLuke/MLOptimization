function s = callMe(iters)

countDir
fileloc  = "N:\KRbLab\M_loop\MLoopParam\param.mat";
CountFolderDirectory = "N:\KRbLab\M_loop\Counter";

countstart = cell2mat(struct2cell(load(fileloc, 'count')));
while countstart < iters
    countCurrent = length(dir(CountFolderDirectory));
    if countCurrent >  countstart
        runScan(@mainHighB, 4, 'random', 1)
        currentstart = countCurrent;
    end
    
end
        
