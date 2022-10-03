function s = callMe(iters)

countDir
fileloc  = "N:\KRbLab\M_loop\MLoopParam\param.mat";
CountFolderDirectory = "N:\KRbLab\M_loop\Counter";

countstart = cell2mat(struct2cell(load(fileloc, 'count')));
tic;
while countstart <= iters
    countCurrent = length(dir(CountFolderDirectory));
    if countCurrent >  countstart
        runScan(@mainHighB, 4, 'random', 1)
        currentstart = countCurrent;
        tic;
    end
    if toc > 30*60
        break
    end
    
end
        
