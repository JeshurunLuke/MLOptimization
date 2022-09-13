function [PLoad, TotalAttempts, UniqueParams] = ScanLoadingRateRealTime
% Scan loading rate vs. some value, updates plot in real time.  If the
% script takes multiple images, we will only look at the first.

%Sequence
seq = @(x) CsSingleAtomRaman(x);
% How many images does the sequence acquire?  We will only look at the
% first, but we need to grab all of them.
NumImages = 2;

%Parameter to scan over
ParamName = 'VShimX';
Param = -0.1:0.02:0.1;
Param = stack(Param,10);
Param = scramble(Param);



%% Begin Script

%Initialize and configure Andor.
op = AndorConfigure('Bulb','Frame',17,'Kinetics',NumImages);

fname = DateTimeStampFilename;

% close all
TakeAScan = 1;
SingleAtom = [];
Param_list = [];
AcqImage = [];

while TakeAScan
    Param_list = [Param_list Param];
    tic;
    for j = 1:length(Param)
        disp(['Starting parameter ' int2str(j) '/' int2str(length(Param))])
        %Tell Andor to start acquiring
        [ret] = StartAcquisition();
        CheckError(ret);
%         disp(['StartAcquisition:' int2str(1e3*toc)])
        %Run sequence
        seq(Param(j));
%         disp(['seq:' int2str(1e3*toc)])
        pause(10e-3);
        NewImages = AndorGetPictures(op);
%         disp(['AndorGetPictures:' int2str(1e3*toc)])
        AcqImage(:,:,end+1) = NewImages(:,:,1);

        SingleAtom(end+1) = find_single_atoms(AcqImage(:,:,end));

        subplot(3,1,1)
        imagesc(AcqImage(:,:,end))
        title(['Single atom? = ' int2str(SingleAtom(end))])
        colormap(gray(64))
        drawnow;

        subplot(3,1,2)
        SingleAtomIndex = find(SingleAtom);
        [n, UniqueParams] = hist(Param_list(SingleAtomIndex),unique(Param_list));
        TotalAttempts = hist(Param_list(1:length(SingleAtom)),unique(Param_list));
        PLoad = n./TotalAttempts;
        PLoad(isnan(PLoad)) = 0;
        errorbar(UniqueParams, 100*PLoad, 100*sqrt(PLoad.*(1-PLoad)./TotalAttempts), 'ks')
        xlabel(ParamName)
        ylabel('Loading Efficiency [%]')
        drawnow;

        subplot(3,1,3)
        bar(UniqueParams, TotalAttempts)
        xlabel(ParamName)
        ylabel('Loading Attempts')
        drawnow;

%         disp(['Plots:' int2str(1e3*toc)])
    end
    disp(['Average delay between sequence starts: ' int2str(1e3*toc/length(Param)) ' ms'])
    disp(['Total loading probability: ' int2str(100*sum(SingleAtom)/length(SingleAtom)) '%'])
    beep
    TakeAScan = input('Take another scan?  Enter =  yes, 0 = no, ctrl+c = abort: ');
    if isempty(TakeAScan)
        TakeAScan = 1;
    end
    if TakeAScan
        save(DateTimeStampFilename, 'AcqImage', 'SingleAtom', 'Param_list')
        disp(['Saved as ' fname ])
    end

end

save(DateTimeStampFilename, 'AcqImage', 'SingleAtom', 'Param_list')
disp(['Saved as ' fname ])