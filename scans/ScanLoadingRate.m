function [PLoad, TotalAttempts, UniqueParams] = ScanLoadingRate
% Scan loading rate vs. some value.  Plots update each time we complete one
% scan through parameters.If the script takes multiple images, we will only
% look at the first.


%Single atom electron cutoff
Cutoff = 100;

%Parameter to scan over
ParamName = 'dVShimMOTy';
Param = -0.1:0.01:0.1;
%Number of times to scan through parameters (don't worry, you can continue
%the scan if you want more statistics)
NumRepeats = 30;

%Sequence

seq = @(x) CsSingleAtom(0, x, 0);
% How many images does the sequence acquire?  We will only look at the
% first, but we need to grab all of them.
NumImages = 2;



%% Begin Script

%Initialize and configure Andor.
op = AndorConfigure('Bulb','Frame',17,'Kinetics',NumImages*length(Param));

fname = DateTimeStampFilename;

% close all
TakeAScan = 1;
SingleAtom = [];
Param_list = [];
AcqImage = [];

while TakeAScan
    tic;
    for j = 1:NumRepeats
        ScanParams = scramble(Param);
        Param_list = [Param_list ScanParams];
        disp(['Starting scan ' int2str(j) '/' int2str(NumRepeats)])
        %Tell Andor to start acquiring
        [ret] = StartAcquisition();
        CheckError(ret);

        %Run sequence
        runSeq(seq, 1, ScanParams);

        NewImages = AndorGetPictures(op);
        % Only look at first image
        AcqImage = cat(3, AcqImage, NewImages(:,:,1:NumImages:end));

        [SingleAtom, ~, Counts] = find_single_atoms(AcqImage, Cutoff);

        figure(1)

        subplot(4,1,1)
        imagesc(AcqImage(:,:,end))
        title(['Single atom? = ' int2str(SingleAtom(end))])
        colormap(gray(64))
        drawnow;

        save(fname, 'AcqImage', 'SingleAtom', 'Param_list')
        disp(['Saved as ' fname ])

        if length(unique(Param_list))<2
            continue
        end

        subplot(4,1,2)
        SingleAtomIndex = find(SingleAtom);
%         [n, UniqueParams] = hist(Param_list(SingleAtomIndex),unique(Param_list));
        TotalAttempts = hist(Param_list(1:length(SingleAtom)),unique(Param_list));
        [PLoad, PLoadErr, UniqueParams] =...
            BernoulliTrialMeanError(SingleAtom, Param_list);
        errorbar(UniqueParams, 100*PLoad, 100*PLoadErr, 'k.','markersize',0.000001)
        xlabel(ParamName)
        ylabel('Loading Efficiency [%]')
        ylim([0, 100])
        drawnow;

        subplot(4,1,3)
        hist(Counts,25)
        xlabel('Electrons')
        hold on
        plot(Cutoff*[1,1], ylim,'r-')
        xlabel('Electrons')
        hold off

        subplot(4,1,4)
        bar(unique(Param_list), TotalAttempts)
        xlabel(ParamName)
        ylabel('Loading Attempts')
        drawnow;

        %         disp(['Plots:' int2str(1e3*toc)])
        disp(['Total loading probability: ' int2str(100*sum(SingleAtom)/length(SingleAtom)) '%'])

        try
            print_portrait_stretch([fname '.pdf']);
        catch
            warning('Unable to save PDF.')
        end
    end

    disp(['Average delay between sequence starts: ' int2str(1e3*toc/length(Param)) ' ms'])
    disp(['Total loading probability: ' int2str(100*sum(SingleAtom)/length(SingleAtom)) '%'])
    beep
    TakeAScan = input('Take another scan?  Enter =  yes, 0 = no, ctrl+c = abort: ');
    if isempty(TakeAScan)
        TakeAScan = 1;
    end
end

save(DateTimeStampFilename, 'AcqImage', 'SingleAtom', 'Param_list')
disp(['Saved as ' fname ])