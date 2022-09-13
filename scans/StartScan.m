function StartScan()
% Run a scan over parameters.  This function is designed to be run in one
% MATLAB instance, while MonitorAndSaveAndorScans is running in another
% instance.  This function sets up and runs runSeq for some set of
% parameters (currently only works for varying one parameter), while
% MonitorAndSaveAndorScans grabs the data from the camera and saves it.
% Note that this function does not save the data at all;
% MonitorAndSaveAndorScans must be running, but this function will not
% start (or will pause) if MonitorAndSaveAndorScans is not running (or
% crashes.) This function uses a memory map (see MemoryMap) to communicate
% between the MATLAB instances.  See NaCs2015\"Running runSeq/ExpSeq and
% acquiring images on separate MATLAB instances" for details.   Nick
% Hutzler, 2 April 2015.

%% EDIT THESE TO SET UP YOUR SCAN
%Name of parameter to scan over
Scan.ParamName = 'tPrecess';
%Units of the parameter
Scan.ParamUnits = 'us';
%x-axis scale for plots.  Enter 1e-6 for micro, 1e3 for kilo, etc.
Scan.PlotScale = 1e-6;
%Sequence to run.  Be sure to check the sequence for syntax requirements.
Scan.seq = @(x) CsSingleAtom(x, 0, 0, 0);
%Parameter values to scan over.  Some helpful custom functions might be
%stack, scramble, QuasirandomList.  Parameter values are in the units used
%in the sequence.
Scan.Params = 1:3;
Scan.Params = scramble(Scan.Params);
%Average number of loaded atoms per parameter.  Sequence will keep running
%until this condition is fulfilled!  Input 0 to just run through one group.
Scan.NumPerParamAvg = 3;
%How many images does the sequence take?
Scan.NumImages = 2;
% Single atom electron cutoff
Scan.Cutoff = 0.5;
% Number of sequences to run between acquisitions of images from the
% camera.  Must be >1.  Set this to be such that the time delay between
% group is one to a few minutes.
Scan.NumPerGroup = 5;


%% Run the scan.  These things should not need editing.

%Grab a string of what you just ran from the command line.  This way we can
%record the parameters that you may have just fed in to this script.
CommandHistory = com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory;
Scan.StartScanArgs = char(CommandHistory(end));

%Load memory mapped variable m for communication with
%MontiorAndSaveAndorScans
m = MemoryMap;

if Scan.NumPerGroup < 2
    error('NumPerGroup must be greater than 1.  If you want to run sequences one-at-a-time, use the command line.')
end

% AndorConfigured is set to 0 when MontiorAndSaveAndorScans finishes saving
% a scan.  If it is still 1, then something is wrong.
if m.Data(1).AndorConfigured
    error('MonitorAndSaveAndorScans is in the middle of running, or was aborted.  Abort it, and run ResetMemoryMap.')
end

m.Data(1).Cutoff = Scan.Cutoff;
m.Data(1).ScanParamsSet = 0;
m.Data(1).NumImages = Scan.NumImages;
m.Data(1).ScanComplete = 0;
m.Data(1).NumPerParamAvg = Scan.NumPerParamAvg;
m.Data(1).CurrentSeqNum = 0;
m.Data(1).NumPerGroup = Scan.NumPerGroup;

%Save scan parameters.

%Get a copy of the text of the sequence to save:
SeqFilename = [GetSequenceNameFromFunctionHandle(Scan.seq) '.m'];
Scan.Text.Seq = fileread(SeqFilename);
%Get a copy of the text of this file as well to save:
Scan.Text.Scan = fileread('StartScan.m');

[fname, CurrentDate, CurrentTime] = DateTimeStampFilename;
m.Data(1).TimeStamp = str2num(CurrentTime);
m.Data(1).DateStamp = str2num(CurrentDate);

if exist(fname, 'file')
    error('Filename already exists!')
end

save(fname, 'Scan');

%% Scan

% Indicate to MonitorAndSaveAndorScan that we are ready to scan.
if m.Data(1).AbortRunSeq
    error('AbortRunSeq is set to 1.  Run ResetMemoryMap and try again.')
end
if m.Data(1).PauseRunSeq
    error('PauseRunSeq is set to 1.  Run ResetMemoryMap and try again.')
end
m.Data(1).ScanParamsSet = 1;
% Once MonitorAndSaveAndorScan see that we are ready, it will configure the
% Andor and let us know when the acquisition has started.
tic
disp('Waiting for MonitorAndSaveAndorScans to set AndorConfigured = 1...')
while m.Data(1).AndorConfigured == 0
    pause(0.5)
    if toc > 10
        beep
        m.Data(1).ScanParamsSet = 0;
        warning('StartScan is aborting due to timeout.  Check that MonitorAndSaveAndorScan is running.')
        return
    end
end
%Set back to 0 in case we have to abort sequence.

m.Data(1).ScanParamsSet = 0;
disp(['Andor is configured and acquiring.  Starting scan ' CurrentDate '-' CurrentTime])

pause(1)

%Run the sequences.  This will run forever until the average number of
%loads per point is NumPerParamAvg.
runSeq(Scan.seq, 0, Scan.Params);

%Scan is now finished.
m.Data(1).ScanComplete = 1;
m.Data(1).NumPerGroup = 0;
disp(['Finished scan ' CurrentDate '-' CurrentTime])


end