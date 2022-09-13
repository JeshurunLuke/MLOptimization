function [PSurvive, PSurviveErr, TotalLoads, UniqueParams, AcqImage, ParamList] =...
    ScanSurvivalRate(NumRamanCoolRadialPulsed, doPGC)
% Scan survival rate vs. some value.  Makes sure to get the same statistics
% for each point.

%% EDIT THESE TO SET UP YOUR SCAN

ParamName = 'detRaman'; %Parameter to scan over
ParamUnits = 'MHz'; %Units of the parameter (for plots only)
%On plots, units will be scaled down by PlotScale.  For example, if you
%scan over Hz but want the plots to show kHz, enter PlotScale = 1e3.
PlotScale = 1e6;
%Sequence to run.  Be sure to check the sequence for syntax requirements...
seq = @(x) CsSingleAtom(x, NumRamanCoolRadialPulsed, doPGC);
Cutoff = 100; %Single atom electron count cutoff
%Parameter values.  Some helpful custom functions might be stack, scramble,
%QuasirandomList.  Parameter values are in the units used in the sequence,
%i.e. not scaled by PlotScale
Param = [   -21.320e6 + 65e3 + 1e3*(-30:5:30), ...
            -21.320e6 - 65e3 + 1e3*(-30:5:30)];
Param =(-21.310e6 - 65e3 - 40e3):(10e3):(-21.310e6 + 65e3 + 40e3);
Param = -21.23e6:10e3:-21.1e6;

%Perform a fit?  Options: 'None','Gaussian', 'Lorentzian', 'DecaySine'
FitType = 'None';
%Number of times to scan through parameters.
NumRepeats = 50;

%To save time, this script uses runSeq to generate and run many sequences
%at once.  How many should we group together?  20 is a reasonable number,
%since that means the graphs will update every ~minute.
NumGroup = 5;

%How many images does the sequence take?  We will only look at the first
%and last, but we need to get all of them.
NumImages = 2;


%% Begin Script - DO NOT EDIT

disp(['Scanning over ' int2str(length(Param)) ' parameters.' ])
disp(['With 50% loading, 2 sec per sequence, this will take ~' ...
    int2str(length(Param)*NumRepeats*2*2/60) ' minutes.'])

% close all
TakeAScan = 1;
Survived = [];
Loaded = [];
SingleAtom = [];
ParamList = [];
AcqImage = [];
Counts = [];
FitFn = [];

fname = DateTimeStampFilename;

%Get a copy of the text of the sequence to save
SeqFilename = [GetSequenceNameFromFunctionHandle(seq) '.m'];
SeqText = fileread(SeqFilename);
%Get a copy of the text of this file as well to save
ScanText = fileread('ScanSurvivalRate.m');

%We cannot group together more sequences than we plan on running!
NumGroup = min(NumGroup, NumRepeats*length(Param));

%Initialize and configure Andor
FrameSize = 15;
op = AndorConfigure('Bulb', 'Frame', FrameSize, 'Kinetics', NumGroup*NumImages);

while TakeAScan
    %Build a list of all parameters that we will scan over, including
    %repeats.  We will eliminate elements from this list as we get
    %successful single atom loaded measurments.
    RemainingParams = stack(scramble(Param), NumRepeats);
    %Continue running as long as their are parameters left to scan
    while ~isempty(RemainingParams)
        tic;
        %Parameters to scan over now.
        NumToScan = min(length(RemainingParams), NumGroup);
        ScanParams = RemainingParams(1:NumToScan);

        disp(['Starting scan of ' int2str(NumToScan) ' parameters'])

        %If we are reducing the number of values to scan over, then we must
        %reconfigure the Andor.
        if NumToScan < NumGroup
            op = AndorConfigure('Bulb','Frame',FrameSize,'Kinetics',NumImages*NumToScan);
        end


        ParamList = [ParamList, ScanParams];
        %Tell Andor to start acquiring
        [ret] = StartAcquisition();
        CheckError(ret);
        %Run sequence
        runSeq(seq, 1, ScanParams);

        %Get images
        NewImages = AndorGetPictures(op);

        %Use only first and last image from each sequence execution
        NewIndices = sort([1:NumImages:size(NewImages,3), ...
            NumImages:NumImages:size(NewImages,3)]);
        NewImages = NewImages(:, :, NewIndices);

        [NewSingleAtom, ~, NewCounts] = find_single_atoms(NewImages, Cutoff);

        Counts = [Counts, NewCounts'];

        if all(NewSingleAtom == 0)
            warning('No atoms loaded for last image set!')
            beep
        end

        %Parameters where we have successfully loaded a single atom may be
        %removed.  The first image is the loading test, so only look at
        %that.
        NewLoads = NewSingleAtom(1:2:end);
        IndicesToRemove = find( NewLoads == 1);
        RemainingParams(IndicesToRemove) = [];

        AcqImage = cat(3, AcqImage, NewImages);

        SingleAtom = [SingleAtom; NewSingleAtom];

        subplot(4,2,1)
        imagesc(AcqImage(:,:,end-1))
        title(['Before.  Single atom? = ' int2str(SingleAtom(end-1))])

        subplot(4,2,2)
        imagesc(AcqImage(:,:,end))
        title(['After.  Single atom? = ' int2str(SingleAtom(end))])
        drawnow;
        colormap(gray(64))

        Survived = SingleAtom(1:2:end).*SingleAtom(2:2:end);
        Loaded = SingleAtom(1:2:end);

        SIndex = find(Survived);
        LIndex = find(Loaded);

        subplot(4,1,2)
        hist(Counts,25);
        hold on
        plot(Cutoff*[1,1], ylim,'r-')
        xlabel('Electrons')
        ylabel('Occurances')
        hold off

%         disp('Starting next group, hit ctrl+c now to cancel')
%         pause(1.5)

        %Only generate survival plots if more than two parameter values have
        %survivors
        if length(unique(ParamList(LIndex))) < 2
            continue
        end

        [PSurvive, PSurviveErr, UniqueParams] =...
            BernoulliTrialMeanError(Survived(LIndex), ParamList(LIndex));
        TotalLoads = hist(ParamList(LIndex),unique(ParamList(LIndex)));

        PSurviveErr(find(PSurviveErr==0)) = Inf;

        subplot(4,1,3)
        errorbar(UniqueParams/PlotScale, PSurvive, PSurviveErr, 'ks',...
            'Marker','none')
        xl = xlim;
        xlabel([ParamName ' [' ParamUnits ']'])
        ylabel('Survival Probability')
        ylim([0, 1])

        switch FitType
            case 'None'
                FitFn = [];
            case 'Gaussian'
                try
                    % Guess that center is middle of x limits, width is
                    % about 1/10 of x limits, offset and height are 0.5
                    FitFn = fit(UniqueParams'/PlotScale, PSurvive',fittype(...
                        'a+b*exp(-(x-x0).^2./(2*s.^2))'),...
                        'start',[0.5, 0.5, diff(xlim)/10, mean(xlim)],...
                        'lower',[-1, -1, 0, -Inf],...
                        'upper',[1, 1, diff(xlim), +Inf],...
                        'weights', PSurviveErr.^-2)
                    FitStr = ['Gaussian Center = ' num2str(FitFn.x0) ...
                        ', \sigma = ' num2str(FitFn.s)];
                catch
                end
            case 'Lorentzian'
                try
                    % Guess that center is middle of x limits, FWHM is
                    % about 1/5 of x limits, offset and height are 0.5
                    FitFn = fit(UniqueParams'/PlotScale, PSurvive',fittype(...
                        'a+b*0.25*g.^2./((x-x0).^2 + 0.25*g.^2)'),...
                        'start',[0.5, 0.5, diff(xlim)/10, mean(xlim)],...
                        'lower',[0, 0, 0, -Inf],...
                        'upper',[1, 1, diff(xlim), +Inf],...
                        'weights', PSurviveErr.^-2)
                    FitStr = ['Lorentzian Center = ' num2str(FitFn.x0) ...
                        ', FWHM = ' num2str(FitFn.g)];
                catch
                end
            case 'DecaySine'
                try
                    FitFn = fit(UniqueParams'/PlotScale, PSurvive',fittype(...
                        'a+b*(1-cos(2*pi*x./per + theta)*exp(-x./tau))'),...
                        'start',[0.5, 1,diff(xlim)/5, diff(xlim)/5, 0],...
                        'lower',[-1, -1, 0, 0, -pi],...
                        'upper',[1, 1, diff(xlim), Inf, +pi],...
                        'weights', PSurviveErr.^-2)
                    FitStr = ['Decaying Sine Half-period = ' num2str(FitFn.per/2) ...
                        ', Decay constant = ' num2str(FitFn.tau)];
                catch
                end
            otherwise
                warning('Unrecognized fit function!')
        end

        if ~isempty(FitFn)
            PlotPoints = linspace(min(UniqueParams'/PlotScale), max(UniqueParams'/PlotScale), 1000);
            hold on
            plot(PlotPoints, FitFn(PlotPoints), 'r-')
            hold off
            title(FitStr)
        end


        subplot(4,1,4)
        stem(UniqueParams/PlotScale, TotalLoads)
        xlim(xl);
        set(xlabel({[ParamName ' [' ParamUnits ']' ], fname}), 'interpreter', 'none')
        ylabel('Loading Events')
        save(fname, 'AcqImage', 'SingleAtom', 'ParamList', 'FitFn',...
            'SeqText', 'Counts', 'ParamName', 'PlotScale', 'ScanText')
        disp(['Saved as ' fname ])

        TotalLoadingProb = sum(Loaded)/length(Loaded);
        title(['Total loading probability: ' int2str(100*TotalLoadingProb) '%'])

        TDelayAvg = toc/NumToScan;
        NewLoadingProb = sum(NewLoads)/length(NewLoads);

        disp(['Average delay between sequence starts: ' int2str(TDelayAvg*1e3) ' ms'])
        disp(['Loading for this scan: ' int2str(100*NewLoadingProb) '%'])
        disp(['Estimated completion time: ' int2str(TDelayAvg*length(RemainingParams)/TotalLoadingProb/60) ' min'])


        try
            print_portrait_stretch([fname '.pdf']);
        catch
			warning('Unable to save PDF.')
        end

    end
    beep
    disp(['Total loading probability: ' int2str(100*sum(Loaded)/length(Loaded)) '%'])

%     NewScan = input('Input new Param values. Leave empty to repeat previous values. 0 = abort: ');
%     if ~isempty(NewScan)
%         if NewScan == 0
            TakeAScan = 0;
%         else
%             Param = NewScan;
%         end
%     end

end

