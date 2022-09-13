function MonitorAndSaveAndorScans()
% This function runs continuously in a MATLAB instance and saves data from
% the Andor camera.  This function assumes that scans are being run by
% StartScan; sequences run from the command line (including runSeq) will be
% ignored.  This function pulls data from the camera, does some basic
% analysis, and saves the data to a timestamped file using the usual format
% (for example, N:\NaCsLab\Data\20150402\data_20150402_191437.mat).  The
% timestamp is determined by the time when StartScan was run.  In case of
% bad behavior, abort this function and StartScan, run ResetMemoryMap, and
% start this function and StartScan again. This function uses a memory map
% (see MemoryMap) to communicate between the MATLAB instances. See
% NaCs2015\"Running runSeq/ExpSeq and acquiring images on separate MATLAB
% instances" for details. Nick Hutzler, 2 April 2015
%  ErrorCode records if there were any errors.
%   0: No known errors
%   1: ScanComplete was set to 1 while MonitorAndSaveAndorScans was still
%   acquiring, i.e. fewer acquisitions than scans.  One of the images must
%   have not saved.
%   2: There was a sequence run after we started the acquisition step, and
%   was therefore not saved
%   3: There were more acquisitions than sequences run.

%Load memory mapped variable m
m = MemoryMap;

while 1 %This program runs forever in the background and listens for data.
    %Andor is not yet configured.
    m.Data(1).AndorConfigured = 0;
    %No errors yet.
    ErrorCode = 0;
    %Wait for StartScan to indicate that we are ready.  If we have been
    %waiting for more than 1 hour, abort.
    tic
    disp('Ready to start.  Waiting for StartScan to set ScanParamsSet = 1.  Hit ctrl+c to abort...')
    while m.Data(1).ScanParamsSet == 0
        pause(0.5)
        if toc > 60*60
            warning('MonitorAndSaveAndorScan is aborting due to timeout')
            return
        end
    end

    %File where data will be saved.
    fname = DateTimeStampFilename(m.Data(1).DateStamp, m.Data(1).TimeStamp);

    %Load scan parameters
    ScanIn = load(fname);
    Scan = ScanIn.Scan;

    % Initialize Andor.  We will extract images in groups of sequences.
    FrameSize = 15;
    Scan.AndorOp = AndorConfigure(...
        'Bulb', 'Frame', FrameSize, 'Kinetics', Scan.NumImages*Scan.NumPerGroup);
    pause(100e-3);

    disp('Andor configured, ready to acquire.')
    m.Data(1).AndorConfigured = 1;
    %Set runSeq to pause until we start the acquisition
    m.Data(1).PauseRunSeq = 1;

    % Initialize Counts and SingleAtom.
    Counts = [];
    Images = [];
    SingleAtom = [];
    ParamList = [];
    SingleAtomRate = [];

    Counter = 0; %Counts how many groups we have acquired
    StopScan = 0; %Set to 1 when we can stop the scan.
    MeanLoads = 0; %Mean number of atoms loaded per parameter.

     %Keep running sequencer in groups until we have loaded enough atoms.
     %Also run if counter==0, meaning that we run at least once.
    while (MeanLoads < m.Data(1).NumPerParamAvg) || Counter==0

        %Check if StartScan has finished
        if m.Data(1).ScanComplete
            ErrorCode = 1;
            memmap = m.Data(1);
            save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images')
            warning('StartScan indicates that sequences are finished, but Andor is still acquiring.  We may have skipped an image.')
            StopScan = 1;
            break
        end

        disp(['Stating sequence group.  Mean loads per parameter ' ...
            int2str(MeanLoads) '/' int2str(m.Data(1).NumPerParamAvg) ...
            '.  Next acquisition after sequence #' ...
            int2str((Counter+1)*Scan.NumPerGroup) '.' ])

        %Acquire a group of images, then process.

        %Start acquisition.
        ret = StartAcquisition();
        CheckError(ret)

        %Unpause runSeq
        m.Data(1).PauseRunSeq = 0;

        %Wait until runSeq has stepped through Scan.NumPerGroup sequences.
        LastSeqNum = m.Data(1).CurrentSeqNum;
        %This next line looks silly,
        LastSeqNum = LastSeqNum + 0;
        tic
        %We will stop acquiring once we have acquired a multiple of
        %NumPerGroup sequences.
        if m.Data(1).PauseRunSeq == 1
            warning('runSeq is paused.  Unpause it, or abort and restart.')
        end
        while m.Data(1).CurrentSeqNum < (Counter+1)*Scan.NumPerGroup
            pause(10e-3)
            % If CurrentSeqNum has changed since the last time we queried,
            % that means we have taken an image.
            if m.Data(1).CurrentSeqNum ~= LastSeqNum
                tic %Reset timeout clock
                LastSeqNum = m.Data(1).CurrentSeqNum;
                LastSeqNum = LastSeqNum + 0;
            end

            %If runSeq is deliberately paused, reset timeout clock
            if m.Data(1).PauseRunSeq == 1
                tic;
            end

            if abs(toc-10)<10e-3
                warning('No sequences have been run for 10 seconds.  Will abort acquisition in 10 more seconds.')
            end

            %Timeout clock.
            if (toc > 20)
                memmap = m.Data(1);
                save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images')
                warning('No sequences have been run for 20 seconds.  Stopping.')
                StopScan = 1;
                break
            end
        end

        disp('Sequence group finished')
        Counter = Counter + 1;

        if StopScan
            break;
        end

        %Pause runSeq while we process images
        m.Data(1).PauseRunSeq = 1;
        %Wait for runSeq to arrive in paused state
        while m.Data(1).IsPausedRunSeq == 0
            pause(10e-3)
        end

        %Check to see if a new scan started since we issued the pause order
        if mod(m.Data(1).CurrentSeqNum, Scan.NumPerGroup)
            ErrorCode = 2;
            memmap = m.Data(1);
            save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images')
            warning('runSeq ran a sequence that was not acquired by the Andor.')
            StopScan = 1;
            break
        end

        % Grab images
%         [ret, first, last] = GetNumberNewImages();
%         [ret, first, last, m.Data(1).CurrentSeqNum]
        NewImages = AndorGetPictures(Scan.AndorOp);
        disp(['Successfully acquired images at ' datestr(datenum(clock),'HHMMSS')])

        NewIndices = length(SingleAtom) + (1:Scan.NumImages*Scan.NumPerGroup);
        Images(:,:,NewIndices) = NewImages;
        [SingleAtom(NewIndices), ~, Counts(NewIndices)] =...
            find_single_atoms(Images(:,:,NewIndices),  m.Data(1).Cutoff);


        %Build parameter list
        while length(ParamList) < Counter*Scan.NumPerGroup
            ParamList = [ParamList Scan.Params];
        end
        ParamList((Scan.NumPerGroup*Counter+1):end) = [];


        %ParamListImage is the same length as the total number of images
        %acquired
        ParamListImage = duplicate_each_element(ParamList, Scan.NumImages);

        %Save everything
        memmap = m.Data(1);
        save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images');
        disp(['Successfully saved ' fname])


        %Plots
        figure(1)
        set(0,'DefaultAxesFontSize',9)
        % Single atom images
        for j = 1:Scan.NumImages
            subplot(5,Scan.NumImages,j)
            imagesc(Images(:,:,NewIndices(j)))
            colormap(gray(32))
            set(gca,'XTick',[])
            set(gca,'YTick',[])
            title(['Single Atom? = ' int2str(SingleAtom(NewIndices(j)))])
        end


        %Electron counts histogram
        subplot(5,1,2)
        hist(Counts, 25)
        hold on
        plot(m.Data(1).Cutoff*[1, 1], ylim, 'r-')
        hold off
        xlabel('Electrons (Counts)')
        ylabel('Frequency')

        %Loading rates, averaged over groups.  Only look at first images.
        subplot(5,1,3)
        for j = 1:Scan.NumImages
            SingleAtomRate(j,Counter) = mean(SingleAtom(NewIndices(j:Scan.NumImages:end)));
        end
        h = plot((1:size(SingleAtomRate,2))*Scan.NumPerGroup, SingleAtomRate');
        xlabel('Sequence number')
        ylabel(['Average (/' int2str(Scan.NumPerGroup)  ') loading'])
        legend(int2str((1:Scan.NumImages)'),'orientation','horizontal',...
            'location','nw')
        ylim([0 1])
        set(h,'Marker','.')
        set(gca,'YTick',0:0.25:1)
        set(gca,'YGrid','on')

        if all(SingleAtomRate(:,Counter) == 0)
            warning('No atoms loaded for last group!')
            beep
        end

        %Loaded atoms.  Only look at first image.  Loads = 1 for image
        %index which is the first image in a sequence and has an atom.
        Attempts = 1:Scan.NumImages:length(SingleAtom);
        Loads = intersect(find(SingleAtom), Attempts);

        % Chart of now many loads per parameter
        UniqueParamsToPlot = unique(ParamList)/Scan.PlotScale;
        subplot(5,1,4)
        [HistLoads, HistLoadsCenters] = hist(...
            ParamListImage(Loads)/Scan.PlotScale, UniqueParamsToPlot);
        stem(HistLoadsCenters, HistLoads,'k.')
        XLimits(1) = HistLoadsCenters(1) - 0.5*(HistLoadsCenters(2) - HistLoadsCenters(1));
        XLimits(2) = HistLoadsCenters(end) + 0.5*(HistLoadsCenters(end) - HistLoadsCenters(end-1));
        xlim(XLimits)
        ylim(ylim + [0, 1])
        xlabel([Scan.ParamName ' [' Scan.ParamUnits ']'])
        ylabel('Loads')

        %Mean loads and loading rate
        MeanLoads = mean(HistLoads);
        MeanLoadingRate = mean(length(Loads)/length(Attempts));

        %Loading rate per parameter
        UniqueParam = unique(ParamList);
        for j = 1:length(UniqueParamsToPlot)
            LoadingRate(j) = HistLoads(j)/length(find(ParamList==UniqueParam(j)));
        end


        hold on
        %Show mean number as red dashed line
        plot(xlim, MeanLoads*[1, 1], 'r--')
        %Show values for each parameter, and for mean
        text(XLimits(2), MeanLoads, ['-' int2str(MeanLoadingRate*100) '%'])
        for j = 1:length(UniqueParamsToPlot)
            text(UniqueParamsToPlot(j), HistLoads(j), ...
                ['-' int2str(LoadingRate(j)*100) '%'])
        end
        hold off
%         disp(['Average of ' int2str(MeanLoads) ' loads per parameter.'])


        if Scan.NumImages > 1
            subplot(5,1,5)
            %Compute survival rate by looking at images after loads
            [PSurvive, PSurviveErr, UniqueParams] = ...
                BernoulliTrialMeanError(SingleAtom(Loads+1),ParamListImage(Loads));
            errorbar(UniqueParams/Scan.PlotScale, PSurvive, PSurviveErr,'ks-');
            xlim(XLimits)
            set(xlabel({[Scan.ParamName ' [' Scan.ParamUnits ']' ], fname}),...
                'interpreter', 'none')
            ylabel('Survival probability')
            ylim([0 1])
        end


        try
            print_portrait_stretch(fname);
        catch
            warning(['Unable to save PDF ' fname ...
                '.  It might be open in another program.'])
        end


        %Check to see if a new scan started since we issued the pause order
        if mod(m.Data(1).CurrentSeqNum, Scan.NumPerGroup)
            ErrorCode = 2;
            memmap = m.Data(1);
            save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images')
            warning('runSeq ran a sequence that was not acquired by the Andor.')
            StopScan = 1;
            break
        end

        %Check to see if there are more acquired sequences than sequences
        %that have actually run
        if length(ParamList) ~= (m.Data(1).CurrentSeqNum)
            ErrorCode = 3;
            memmap = m.Data(1);
            save(fname, 'memmap', 'Counts', 'SingleAtom', 'ErrorCode',...
            'Scan', 'ParamList', 'Images')
            warning('runSeq ran a sequence that was not acquired by the Andor.')
            StopScan = 1;
            break
        end

        if StopScan
            break;
        end
    end
    % Since we have loaded enough atoms, tell runSeq to abort.  Note that
    % this will result in a single sequence being run after we save the
    % data; to check that this last run isn't saved, you can comment out
    % the next two lines and notice that this script will save the correct
    % number of sequences, but runSeq will be paused forever after
    % outputting the correct number of sequences.
    m.Data(1).AbortRunSeq = 1;
    m.Data(1).PauseRunSeq = 0;
    m.Data(1).NumPerGroup = 0;
    %This Andor configuration is no longer valid since scan is complete.
    m.Data(1).AndorConfigured = 0;
    disp(['Scan finished.  Saved ' int2str(length(ParamList)) ' sets of images.'])
    disp(' ')
end


end