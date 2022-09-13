function mainMCPDataMonitor(filename)
% close all
if(~exist('filename','var'))
    filename = '20200624_100V_30G_REMPI_scan_2';
end
h4 = figure();
scrsz = get(groot, 'Screensize' );
set(h4, 'Position', [scrsz(3)/2 00 scrsz(3)/2 scrsz(4)-80]);%[left bottom width height]

% cd('\\krb1-pc\d\Data analysis scripts\MCP Image Analysis\MCP Shot by Shot');
folderpath = 'd:\Data analysis scripts\MCP Image Analysis\MCP Shot by Shot\lmf2txt\';
% filename = '20190513_700nm';

% filename = '2019_04_07_1';
filepath = [folderpath, filename];

if (~exist([filepath,'.dat'],'file'))
    error([filepath,'.dat',' needs to be created using mainMCPtxtAnalysisTiming.m first!'])
else
    realHit = dlmread([filepath,'.dat'],'\t');
end

% Name columns of realHit
TOFAllShots = realHit(:,1);
xPosAllShots = realHit(:,2);
yPosAllShots = realHit(:,3);
shotNumAllShots = realHit(:,4);

% Calculate the total number of experimental cycles
totCycleNum = 1;
cycleNumAllShots = zeros(length(realHit),1);
cycleNumAllShots(1) = 1;

for i = 2:length(shotNumAllShots)
    if shotNumAllShots(i) < shotNumAllShots(i-1)
        totCycleNum = totCycleNum + 1;
    end
    cycleNumAllShots(i) = totCycleNum;
end

cyclesCut = [0 0]; % [38 651]
% Comments about "cyclesCut"
% Each pair of values specify an interval of cycles to be cut out of the data analysis
% To not cut anything, put [0 0]
cycleNumInd = [];
for i = 1:length(cyclesCut)/2
    tmp = find((cycleNumAllShots <= cyclesCut(i))|(cycleNumAllShots >= cyclesCut(i+1))); % find indices of shots that will survice the cyclesCut
    cycleNumInd = union(cycleNumInd,tmp);
end

%% Save a new .dat file with the null shots cut away
if sum(cyclesCut) ~= 0
    
    realHitFiltered = zeros(length(cycleNumInd),4);
    
    realHitFiltered(:,1) = TOFAllShots(cycleNumInd);
    realHitFiltered(:,2) = xPosAllShots(cycleNumInd);
    realHitFiltered(:,3) = yPosAllShots(cycleNumInd);
    realHitFiltered(:,4) = shotNumAllShots(cycleNumInd);
    realHitFiltered(:,5) = cycleNumAllShots(cycleNumInd);
    
    save([filename,'_filtered.dat'],'realHitFiltered');
    
end
%%

maxShot = max(shotNumAllShots);
maxShot = 3000*2;

% shotNumStart = 1;
% shotNumEnd = 5;

shotNumStart = 50;
shotNumEnd = maxShot/2;

if shotNumEnd > maxShot
    error(['shotNumEnd must be <= ',num2str(maxShot)]);
end

% Define data vectors filtered by shot numbers
shotNumIndAll = find((shotNumAllShots >= shotNumStart)&(shotNumAllShots <= shotNumEnd));

filterNumIndAll = intersect(shotNumIndAll, cycleNumInd);

TOFAll = TOFAllShots(filterNumIndAll);
xPosAll = xPosAllShots(filterNumIndAll);
yPosAll = yPosAllShots(filterNumIndAll);
shotNumAll = shotNumAllShots(filterNumIndAll);
cycleNumAll = cycleNumAllShots(filterNumIndAll);

totCycleNumEff = length(unique(cycleNumAll));

% shotNumBkgdStart = 16;
% shotNumBkgdEnd = 20;

shotNumBkgdStart = maxShot/2+1;
shotNumBkgdEnd = maxShot;

if shotNumEnd > maxShot
    error(['shotNumBkgdEnd must be <= ',num2str(maxShot)]);
end

% Define data vectors filtered by shot numbers
shotNumIndBkgd = find((shotNumAllShots >= shotNumBkgdStart)&(shotNumAllShots <= shotNumBkgdEnd));

filterNumIndBkgd = intersect(shotNumIndBkgd, cycleNumInd);

TOFBkgd = TOFAllShots(filterNumIndBkgd);
xPosBkgd = xPosAllShots(filterNumIndBkgd);
yPosBkgd = yPosAllShots(filterNumIndBkgd);
shotNumBkgd = shotNumAllShots(filterNumIndBkgd);
% eventNumBkgd = cycleNumAllShots(shotNumInd);

%% Assign species names and correspnding TOFs

speciesNames = {'K','K_2','Rb','KRb','K_2Rb','Rb_2','KRb_2','K_2Rb_2'};

speciesMasses = [40,80,87,127,167,174,214,254];

% TOFs = [15713, 22212, 23163, 27981, 32083. 32748, 36315, 39562];
% TOFs = [15713, 22212, 23163, 27981, 32083. 32748, 36315, 39562] -30; %for VR = 992V
% TOFs = [15713, 22212, 23163, 27981, 32083. 32748, 36315, 39562]*sqrt(992/100) + 500;
% TOFs = mod([15713, 22212, 23163, 27981, 32083. 32748, 36315, 39562], 20000) + 15;
TOFs = [48930, 69196, 72150, 87180, 99971, 102045, 113167, 123290]-30000+100;   %VR = 99V , 5G
% TOFs = [11640, 16206, 16870, 20260, 23186, 23656, 26179, 28400];        %VR = 2000V , 30G
% TOFs = [46350, 86274, 92120, 121700, 146901, 150985, 172896, 192837];

colorCodes = {'k','r','k','k','g','c','m','b'};

TOFbinSizeAll = 50; %in ns

TOFWindow = 12000;   %[ns]

TOFBinSizeSpecies = [1, 10, 1, 1, 1, 10, 1, 1];

% TOFMin = 0;
% TOFMax = 45000; % [ns]
TOFMin = 1000;
TOFMax = 100000; % [ns]
TOFEdgesAll = TOFMin:TOFbinSizeAll:TOFMax;

TOFCountsAll = histcounts(TOFAll,TOFEdgesAll);
TOFCountsBkgd = histcounts(TOFBkgd,TOFEdgesAll);
TOFTimeAll = (TOFEdgesAll(1:length(TOFEdgesAll)-1) + TOFEdgesAll(2:length(TOFEdgesAll)))./2;

totCountsSpecies = zeros(1, length(speciesNames));
totCountsSpeciesBkgd = zeros(1, length(speciesNames));

spatialBinSizeSpecies = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];

MCPRadius = 40;
xMin = -MCPRadius;
xMax = MCPRadius;
yMin = -MCPRadius;
yMax = MCPRadius;

% Use an ROI to spatially select data
% xMinROISpecies = [-13.5, -14.0, -17.0, -40, -40, -18.5, -40, -40];
% xMaxROISpecies = [-03.5, -09.0, -07.0, +40, +40, -08.5, +40, +40];
% yMinROISpecies = [-07.0, -04.0, -06.5, -40, -40, -05.5, -40, -40];
% yMaxROISpecies = [+03.0, +01.0, +03.5, +40, +40, +03.5, +40, +40];

% For 992 V
% xMinROISpecies = [-31.75, -14.0, -32.0, -40, -40, -18.5, -18.5, -16.5];
% xMaxROISpecies = [+12.75, -09.0, +10.0, +40, +40, -08.5, -8.5, -12.5];
% yMinROISpecies = [-23.75, -04.0, -20.0, -40, -40, -05.5, -06.0, -03.0];
% yMaxROISpecies = [+21.75, +01.0, +17.0, +40, +40, +03.5, +04.0, +01.0];

% xMinROISpecies = [-31.75, -14.0, -00.5, -00.5, -40, -05.0, -02.5, -03.0];
% xMaxROISpecies = [+12.75, -09.0, +07.5, +07.5, +40, +10.0, +03.5, +03.0];
% yMinROISpecies = [-23.75, -04.0, -04.5, -04.5, -40, -09.0, -04.0, -04.0];
% yMaxROISpecies = [+21.75, +01.0, +05.5, +03.5, +40, +06.0, +02.0, +02.0];

%% ROI window parameters for 99 V and 10 G
% xCentROISpecies = [0, 0, -7.75, -8.5, 0, -9.35, -9.25, -9.95];
% yCentROISpecies = [0, 0, -1, -1, 0, -1, -1, -1];
% windowROISpecies = [80, 80, 8, 8, 80, 15, 8, 8];

%% ROI window parameters for 99 V and 5 G
xCentROISpecies = [-11.181, -11.44, -10.9494, -11.333, -11.55, -11.55, -11.55, -11.55];
yCentROISpecies = [-1.2188, -0.971, -0.5559,  -0.8894, -0.8,   -0.8,   -0.75,  -0.75];
windowROISpecies = [20, 10, 10, 20, 10, 10, 10, 5];

% %% ROI window parameters for 99 V and 30 G
% xCentROISpecies = [12.95, 5.85, 5.05, 2.25, 0, 0.65, 0, 0];
% yCentROISpecies = [-0.85, -0.85, -0.85, -0.85, 0, -0.85, 0, 0];
% windowROISpecies = [10, 10, 10, 10, 10, 10, 10, 10];

%% ROI window parameters for 992 V and 30 G
% xCentROISpecies = [-9.75, -12.25, -12.25, -13.25, 0, -13.85, 0, 0];
% yCentROISpecies = [-1.25, -1.25, -1.25, -1.25, 0, -1.25, 0, 0];
% windowROISpecies = [8, 8, 8, 8, 8, 8, 8, 8];

%% Calculate
xMinROISpecies = xCentROISpecies - windowROISpecies./2;
xMaxROISpecies = xCentROISpecies + windowROISpecies./2;
yMinROISpecies = yCentROISpecies - windowROISpecies./2;
yMaxROISpecies = yCentROISpecies + windowROISpecies./2;

speciesROIFlag = [1, 1, 1, 1, 0, 1, 0, 0];%{'K','K_2','Rb','KRb','K_2Rb','Rb_2','KRb_2','K_2Rb_2'};

shotNumBinSizeSpecies = [1, 1, 1, 1, 1, 1, 1, 1];

%% Create vectors for centroid calculation
xCentSpecies = zeros(1, length(speciesNames));
yCentSpecies = zeros(1, length(speciesNames));

%% Plotting flags
plotTOFAllFlag = 0;
plotTOFFlag = 0;
plotSpatialFlag = 0;
plotShotDstrnFlag = 0;
plotIonOverTimeFlag = 1;
plotCentroidsFlag = 0;
plotVMIRingsFlag = 0; % Must enable plotSpatialFlag and plotCentroidsFlag

%% Fitting flags
fitShotDstrnFlag = 1;

%% Calculate VMI ring radius based on kinetic energy and VMI voltage
A = 46.7; % [mm/meV/V] VMI calibration constant
VR = 99; % [V] repeller voltage
Emax = 1.24; % [meV] exhothermicy of KRb + KRb
KER_sum = linspace(0.05/10*Emax,Emax,10); % [meV]
KER_K2 = KER_sum.*174./(80 + 174); % [meV]
KER_Rb2 = KER_sum.*80./(80 + 174); % [meV]
RVMI_K2 = A.*sqrt(KER_K2./VR); % [mm]
RVMI_Rb2 = A.*sqrt(KER_Rb2./VR); % [mm]

%% Define TOF vectors for each species
scrsz = get(groot, 'Screensize' );

% if plotTOFFlag
%     h1 = figure(); % Indivial TOF window figure
%     set(h1, 'Position', [scrsz(3) 1 scrsz(3) scrsz(4)])
% end

% if plotSpatialFlag
%     h2 = figure(); % Spatial figure
%     set(h2, 'Position', [scrsz(3) + scrsz(3) 1 scrsz(3) scrsz(4)])
% %     set(h2, 'Position', [scrsz(3) 1 scrsz(3) scrsz(4)])
%     %set colormap for MCP spatial image
%     cmap = jet(5000);
%     cmap(1,:) = zeros(1,3);
% end
%
% if plotShotDstrnFlag
%     h3 = figure(); % shot analysis figure
%     set(h3, 'Position', [scrsz(3) 1 scrsz(3) scrsz(4)])
% end
%
% if plotIonOverTimeFlag
%     h4 = figure(); % ion over time figure
%     set(h4, 'Position', [scrsz(3) 1 scrsz(3) scrsz(4)])
% end

for i = 1:length(speciesNames)
    
    %% TOF analysis
    TOFCountsSpeciesName = ['TOFCounts',speciesNames{i}];
    TOFTimeSpeciesName = ['TOFTime',speciesNames{i}];
    totCountsSpeciesName = ['totCounts',speciesNames{i}];
    
    TOFSpeciesInd = find((TOFAll >= TOFs(i) - TOFWindow/2) & (TOFAll <= TOFs(i) + TOFWindow/2));
    TOFSpecies = TOFAll(TOFSpeciesInd);
    totCountsSpecies(i) = length(TOFSpecies);
    assignin('base',totCountsSpeciesName,totCountsSpecies(i));
    xPosSpecies = xPosAll(TOFSpeciesInd);
    yPosSpecies = yPosAll(TOFSpeciesInd);
    shotNumSpecies = shotNumAllShots(TOFSpeciesInd);
    cycleNumSpecies = cycleNumAll(TOFSpeciesInd);
    
    TOFSpeciesBkgdInd = find((TOFBkgd >= TOFs(i) - TOFWindow/2) & (TOFBkgd <= TOFs(i) + TOFWindow/2));
    TOFSpeciesBkgd = TOFBkgd(TOFSpeciesBkgdInd);
    totCountsSpeciesBkgd(i) = length(TOFSpeciesBkgd);
    
    TOFEdgesSpecies = (TOFs(i) - TOFWindow/2):TOFBinSizeSpecies(i):(TOFs(i) + TOFWindow/2);
    TOFCountsSpecies = histcounts(TOFSpecies, TOFEdgesSpecies);
    assignin('base',TOFCountsSpeciesName,TOFCountsSpecies);
    TOFTimeSpecies = TOFEdgesSpecies(1:length(TOFEdgesSpecies)-1);
    assignin('base',TOFTimeSpeciesName,TOFTimeSpecies);
    
    if plotTOFFlag
        figure(h1)
        subplot(length(speciesNames)/2,2,i)
        plot(TOFTimeSpecies, TOFCountsSpecies, 'Color', colorCodes{i});
        hold off
        xlabel('Time-of-flight (ns)', 'FontSize', 14)
        ylabel('Ion counts', 'FontSize', 14)
        grid on
        grid minor
        xlim([min(TOFTimeSpecies),max(TOFTimeSpecies)])
        ylim([0,max(1.2*max(TOFCountsSpecies),1)])
        text(min(TOFTimeSpecies), max(1.1*max(TOFCountsSpecies),0.90), [speciesNames{i},'^+'], 'FontSize', 14)
        text(min(TOFTimeSpecies), max(0.90*max(TOFCountsSpecies),0.75), ['(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14)
        title([filename, ', TOF spectrum of shot # ',num2str(shotNumStart),'-',num2str(shotNumEnd)], 'Interpreter', 'none')
    end
    
    %% Spatial analysis
    xEdgesSpecies = xMin:spatialBinSizeSpecies(i):xMax;
    yEdgesSpecies = yMin:spatialBinSizeSpecies(i):yMax;
    xSpecies = (xEdgesSpecies(1:length(xEdgesSpecies)-1) + xEdgesSpecies(2:length(xEdgesSpecies)))/2;
    ySpecies = (yEdgesSpecies(1:length(yEdgesSpecies)-1) + yEdgesSpecies(2:length(yEdgesSpecies)))/2;
    spatialCountsSpecies = histcounts2(xPosSpecies, yPosSpecies, xEdgesSpecies, yEdgesSpecies);
    
    theta = 45;
    xPosSpeciesRot = cos(theta/180*pi)*xPosSpecies - sin(theta/180*pi)*yPosSpecies;
    yPosSpeciesRot = sin(theta/180*pi)*xPosSpecies + cos(theta/180*pi)*yPosSpecies;
    spatialCountsSpeciesRot = transpose(histcounts2(xPosSpeciesRot, yPosSpeciesRot, xEdgesSpecies, yEdgesSpecies));
    %     spatialCountsSpeciesRot = imrotate(spatialCountsSpecies,theta,'crop');
    xCentSpecies(i) = mean(xPosSpeciesRot);
    yCentSpecies(i) = mean(yPosSpeciesRot);
    
    if speciesROIFlag(i) % In this section, do thing that requires a ROI
        speciesROIInd = find((xPosSpeciesRot >= xMinROISpecies(i)) & (xPosSpeciesRot <= xMaxROISpecies(i))...
            & (yPosSpeciesRot >= yMinROISpecies(i)) & (yPosSpeciesRot <= yMaxROISpecies(i)));
        %         yPosSpeciesROIInd = find((yPosSpeciesRot >= yMinROISpecies(i)) & (yPosSpeciesRot <= yMaxROISpecies(i)));
        xPosSpeciesROI = xPosSpeciesRot(speciesROIInd);
        yPosSpeciesROI = yPosSpeciesRot(speciesROIInd);
        xCentSpecies(i) = mean(xPosSpeciesROI);
        yCentSpecies(i) = mean(yPosSpeciesROI);
    end
    
    if plotSpatialFlag
        figure(h2)
        subplot(2,length(speciesNames)/2,i)
        colormap(cmap);
        %         spatialCountsSpeciesRot(spatialCountsSpeciesRot>20)=20;
        imagesc(xSpecies, ySpecies, spatialCountsSpeciesRot);
        %         imagesc(spatialCountsSpeciesRot);
        set(gca,'YDir','normal','XDir','normal')
        hold on
        k = linspace(0,2*pi);
        plot(MCPRadius.*cos(k),MCPRadius.*sin(k),'w');
        if speciesROIFlag(i)
            plot([xMinROISpecies(i),xMinROISpecies(i)],[yMinROISpecies(i),yMaxROISpecies(i)],'w')
            hold on
            plot([xMaxROISpecies(i),xMaxROISpecies(i)],[yMinROISpecies(i),yMaxROISpecies(i)],'w')
            hold on
            plot([xMinROISpecies(i),xMaxROISpecies(i)],[yMinROISpecies(i),yMinROISpecies(i)],'w')
            hold on
            plot([xMinROISpecies(i),xMaxROISpecies(i)],[yMaxROISpecies(i),yMaxROISpecies(i)],'w')
            hold on
        end
        if plotCentroidsFlag
            plot(xCentSpecies(i),yCentSpecies(i),'+w');
            if plotVMIRingsFlag && strcmp(speciesNames{i},'K_2')
                for j = 1:length(RVMI_K2)
                    plot(RVMI_K2(j).*cos(k) + xCentSpecies(i),RVMI_K2(j).*sin(k)+ yCentSpecies(i),'Color',[0.5 0.5 0.5]);
                end
            elseif plotVMIRingsFlag && strcmp(speciesNames{i},'Rb_2')
                for j = 1:length(RVMI_Rb2)
                    plot(RVMI_Rb2(j).*cos(k) + xCentSpecies(i),RVMI_Rb2(j).*sin(k)+ yCentSpecies(i),'Color',[0.5 0.5 0.5]);
                end
            end
        end
        axis square
        hold off
        colorbar('east','Color','w')
        xlabel('x (mm)', 'FontSize', 14)
        ylabel('y (mm)', 'FontSize', 14)
        if speciesROIFlag(i)
            xlim([xMinROISpecies(i), xMaxROISpecies(i)])
            ylim([yMinROISpecies(i), yMaxROISpecies(i)])
            text(xMinROISpecies(i) + 0.01*(xMaxROISpecies(i) - xMinROISpecies(i)), yMinROISpecies(i) + 0.15*(yMaxROISpecies(i) - yMinROISpecies(i)), ['N_{ROI} = ',num2str(length(speciesROIInd))], 'FontSize', 14, 'Color','w')
            text(xMinROISpecies(i) + 0.01*(xMaxROISpecies(i) - xMinROISpecies(i)), yMinROISpecies(i) + 0.95*(yMaxROISpecies(i) - yMinROISpecies(i)), [speciesNames{i},'^+'], 'FontSize', 14, 'Color','w')
            text(xMinROISpecies(i) + 0.01*(xMaxROISpecies(i) - xMinROISpecies(i)), yMinROISpecies(i) + 0.05*(yMaxROISpecies(i) - yMinROISpecies(i)), ['N = ',num2str(totCountsSpecies(i))], 'FontSize', 14, 'Color','w')
        else
            xlim([xMin, xMax])
            ylim([yMin, yMax])
            text(xMin + 0.01*(xMax - xMin), yMin + 0.95*(yMax - yMin), [speciesNames{i},'^+'], 'FontSize', 14, 'Color','w')
            text(xMin + 0.01*(xMax - xMin), yMin + 0.05*(yMax - yMin), ['N = ',num2str(totCountsSpecies(i))], 'FontSize', 14, 'Color','w')
        end
        title([filename, ', MCP Image of shot # ',num2str(shotNumStart),'-',num2str(shotNumEnd)], 'Interpreter', 'none')
    end
    
    %% shot number analysis
    shotNumEdgesSpecies = 1:shotNumBinSizeSpecies(i):(maxShot+1);
    shotNumCountsSpecies = histcounts(shotNumSpecies,shotNumEdgesSpecies);
    shotNumCountsSpeciesNorm = shotNumCountsSpecies./shotNumBinSizeSpecies(i); % Normalize by bin size
    shotNumCtrSpecies = (shotNumEdgesSpecies(1:end-1) + shotNumEdgesSpecies(2:end) - 1)./2;
    repRate = 1000; % [Hz]
    tOffSet = 0e-3; % STIRAP-to-UV time offset
    ionExpTimeSpecies = (shotNumCtrSpecies - 1)./repRate + tOffSet;
    
    if plotShotDstrnFlag
        figure(h3)
        subplot(length(speciesNames)/2,2,i)
        plot(ionExpTimeSpecies, shotNumCountsSpeciesNorm, 'Color', colorCodes{i});
        hold on
        %         xlabel('Shot Number', 'FontSize', 14)
        xlabel('Time (s)', 'FontSize', 14)
        ylabel('Ion counts', 'FontSize', 14)
        grid on
        grid minor
        xlim([0,shotNumEnd./repRate])
        ylim([0,1.2*max(max(shotNumCountsSpeciesNorm),1)])
        %     ylim([0,100])
        %         text(0.85*shotNumEnd, 0.90*max(1.2*max(shotNumCountsSpecies),1), [speciesNames{i},'^+'], 'FontSize', 14)
        %         text(0.85*shotNumEnd, 0.75*max(1.2*max(shotNumCountsSpecies),1), ['(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14)
        text(0.85*shotNumEnd./repRate, 0.90*1.2*max(max(shotNumCountsSpeciesNorm),1), [speciesNames{i},'^+'], 'FontSize', 14)
        text(0.85*shotNumEnd./repRate, 0.75*1.2*max(max(shotNumCountsSpeciesNorm),1), ['N = ',num2str(totCountsSpecies(i))], 'FontSize', 14)
        text(0.85*shotNumEnd./repRate, 0.60*1.2*max(max(shotNumCountsSpeciesNorm),1), ['N_{cyc} = ',num2str(totCountsSpecies(i)./totCycleNumEff,3)], 'FontSize', 14)
        text(0.85*shotNumEnd./repRate, 0.45*1.2*max(max(shotNumCountsSpeciesNorm),1), [num2str(totCycleNumEff),' cycles'], 'FontSize', 14)
        title([filename, ', Shot distribution'], 'Interpreter', 'none')
        
        twoBodyFitFlag = 1;
        expFitFlag = 0;
        if fitShotDstrnFlag && strcmp(speciesNames{i},'KRb')
            
            if twoBodyFitFlag
                
                ionExpTimeMin = 0;
                ionExpTimeMax = max(ionExpTimeSpecies);
                
                ionExpTimeFit = ionExpTimeSpecies(intersect(find(ionExpTimeSpecies > ionExpTimeMin),find(ionExpTimeSpecies < ionExpTimeMax)));
                shotNumCountsNormFit = shotNumCountsSpeciesNorm(intersect(find(ionExpTimeSpecies > ionExpTimeMin),find(ionExpTimeSpecies < ionExpTimeMax)));
                
                averageFlag = 0;
                
                xcurve = linspace(0, max(ionExpTimeFit), 1000);
                
                [b, b_Err, ycurve] = ionSigDecayFit(ionExpTimeFit, shotNumCountsNormFit, [], averageFlag, xcurve);
                
                subplot(length(speciesNames)/2,2,i)
                plot(xcurve, ycurve, '-b', 'LineWidth', 2);
                string1= ['n_0 = ',num2str(b(1), '%.3g'), ' \pm', num2str(b_Err(1), '%.2g')];
                string2= ['t_{1/2} = ',num2str(b(2), '%.3g'), ' \pm', num2str(b_Err(2), '%.2g'), 's'];
                text(0.45*shotNumEnd./repRate,0.90*1.2*max(max(shotNumCountsSpeciesNorm),1),string1,'Color','blue','FontSize',14)
                text(0.45*shotNumEnd./repRate,0.75*1.2*max(max(shotNumCountsSpeciesNorm),1),string2,'Color','blue','FontSize',14)
                
            end
            
            if expFitFlag
                
                ionExpTimeMin = 0;
                ionExpTimeMax = 0.01;
                
                ionExpTimeFit = ionExpTimeSpecies(intersect(find(ionExpTimeSpecies > ionExpTimeMin),find(ionExpTimeSpecies < ionExpTimeMax)));
                shotNumCountsNormFit = shotNumCountsSpeciesNorm(intersect(find(ionExpTimeSpecies > ionExpTimeMin),find(ionExpTimeSpecies < ionExpTimeMax)));
                
                averageFlag = 0;
                
                xcurve = linspace(0, max(ionExpTimeFit), 1000);
                
                [b, b_Err, ycurve] = expFit(ionExpTimeFit, shotNumCountsNormFit, [], averageFlag, xcurve);
                
                subplot(length(speciesNames)/2,2,i)
                plot(xcurve, ycurve, '-r', 'LineWidth', 2);
                string1= ['n_0 = ',num2str(b(1), '%.3g'), ' \pm', num2str(b_Err(1), '%.2g')];
                string2= ['lifetime= ',num2str(b(2), '%.3g'), ' \pm', num2str(b_Err(2), '%.2g'), ' s'];
                text(0.45*shotNumEnd./repRate,0.60*1.2*max(max(shotNumCountsSpeciesNorm),1),string1,'Color','red','FontSize',14)
                text(0.45*shotNumEnd./repRate,0.45*1.2*max(max(shotNumCountsSpeciesNorm),1),string2,'Color','red','FontSize',14)
                
            end
            
        end
        
        hold off
        
    end
    
    %% Ion counts over time analysis
    cycleNumEdgesSpecies = 0.5:1:totCycleNum + 0.5;
    cycleNumCountsSpecies = histcounts(cycleNumSpecies,cycleNumEdgesSpecies);
    cycleNumCountsCumSpecies = cumsum(cycleNumCountsSpecies);
    cycleNumCtrSpecies = 1:1:totCycleNum;
    
    if plotIonOverTimeFlag
        figure(h4);
        subplot(length(speciesNames)/2,length(speciesNames)/2,2.*i - 1)
        plot(cycleNumCtrSpecies, cycleNumCountsSpecies, 'Color', colorCodes{i});
        for j = 1:length(cyclesCut)/2
            patch([cyclesCut(j) cyclesCut(j) cyclesCut(j + 1) cyclesCut(j + 1)], ...
                [-1 1.3*max(max(cycleNumCountsSpecies),1) 1.3*max(max(cycleNumCountsSpecies),1) -1], ...
                'k', 'EdgeColor', [0.2 0.2 0.2])
            alpha(0.20)
        end
        hold off
        xlabel('Cycle Number', 'FontSize', 14)
        ylabel('Ion counts', 'FontSize', 14)
        grid on
        grid minor
        xlim([0,totCycleNum])
        ylim([0,1.2*max(max(cycleNumCountsSpecies),1)])
        text(0.01*totCycleNum, 0.90*1.2*max(max(cycleNumCountsSpecies),1), [num2str(totCycleNum),' cycles'], 'FontSize', 14, 'Color', 'r')
        
        if i == 2
            title(filename, 'Interpreter', 'none','FontSize',16, 'Color', 'b')
        end
        
        subplot(length(speciesNames)/2,length(speciesNames)/2,2.*i)
        plot(cycleNumCtrSpecies, cycleNumCountsCumSpecies, 'Color', colorCodes{i});
        hold off
        xlabel('Cycle Number', 'FontSize', 14)
        ylabel('Cum. ion counts', 'FontSize', 14)
        grid on
        grid minor
        xlim([0,totCycleNum])
        ylim([0,max(1.2*max(cycleNumCountsCumSpecies),1)])
        
        text(0.01*totCycleNum, 0.90*max(1.2*max(cycleNumCountsCumSpecies),1), [speciesNames{i},'^+'], 'FontSize', 14)
        text(0.01*totCycleNum, 0.75*max(1.2*max(cycleNumCountsCumSpecies),1), ['(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14)
    end
    
end

%% Plot overall TOF spectrum and zoomed in overall TOF spectrum
if plotTOFAllFlag
    
    figure(h5);
    %     scrsz = get( groot, 'Screensize' );
    % %     set(h5, 'Position', [scrsz(3) 1 scrsz(3) scrsz(4)])
    %     set(h5, 'Position', [scrsz(3)/2 00 scrsz(3)/2 scrsz(4)-80]);%[left bottom width height]
    subplot(3,1,1)
    plot(TOFTimeAll,TOFCountsAll,'k')
    hold off
    xlim([TOFMin,TOFMax])
    ylim([0,1.2*max(TOFCountsAll)])
    grid on
    grid minor
    set(gca,'FontSize',14);
    % xlabel('Time-of-flight (ns)', 'FontSize', 16)
    ylabel('Ion counts', 'FontSize', 16)
    title([filename, ', TOF spectrum of shot # ',num2str(shotNumStart),'-',num2str(shotNumEnd)], 'Interpreter', 'none')
    text(TOFMin, 1.1*max(TOFCountsAll), [num2str(totCycleNum), ' total cycles'], 'FontSize', 16);
    text(TOFMin, 0.95*max(TOFCountsAll), [num2str(totCycleNumEff), ' useful cycles'], 'FontSize', 16);
    text(TOFMin, 0.80*max(TOFCountsAll), [num2str(maxShot), ' shots/cycle'], 'FontSize', 16);
    
    for i = 1:length(speciesNames)
        patch([TOFs(i)-TOFWindow/2 TOFs(i)-TOFWindow/2 TOFs(i)+TOFWindow/2 TOFs(i)+TOFWindow/2], ...
            [-1 1.3*max(TOFCountsAll) 1.3*max(TOFCountsAll) -1], ...
            colorCodes{i}, 'EdgeColor', [1 1 1])
        alpha(0.20)
        if isequal(speciesNames{i},'K') || isequal(speciesNames{i},'K_2') || isequal(speciesNames{i},'K_2Rb')
            text(TOFs(i)+TOFWindow/2, 1.1*max(TOFCountsAll), [speciesNames{i},'^+','(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        else
            text(TOFs(i)+TOFWindow/2, 1.0*max(TOFCountsAll), [speciesNames{i},'^+','(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        end
    end
    
    subplot(3,1,2)
    plot(TOFTimeAll,TOFCountsAll,'k')
    hold off
    xlim([TOFMin,TOFMax])
    ymaxzoom = 1000;
    %     ymaxzoom = 1.2*max([totCountsK_2, totCountsRb_2, totCountsK_2Rb,totCountsKRb_2,totCountsK_2Rb_2]); % Zoom in over the y-axis (ion counts) of the TOF spectrum
    %     ymaxzoom = 1.2*max([totCountsK_2, totCountsRb_2]);
    ylim([0 ymaxzoom])
    grid on
    grid minor
    set(gca,'FontSize',14);
    % xlabel('Time-of-flight (ns)', 'FontSize', 16)
    ylabel('Ion counts', 'FontSize', 16)
    title([filename, ', TOF spectrum of shot # ',num2str(shotNumStart),'-',num2str(shotNumEnd)], 'Interpreter', 'none')
    text(TOFMin, 1.1*max(TOFCountsAll), [num2str(totCycleNum), ' cycles'], 'FontSize', 16);
    text(TOFMin, 0.95*max(TOFCountsAll), [num2str(maxShot), ' shots/cycle'], 'FontSize', 16);
    
    for i = 1:length(speciesNames)
        patch([TOFs(i)-TOFWindow/2 TOFs(i)-TOFWindow/2 TOFs(i)+TOFWindow/2 TOFs(i)+TOFWindow/2], ...
            [-1 1.3*max(TOFCountsAll) 1.3*max(TOFCountsAll) -1], ...
            colorCodes{i}, 'EdgeColor', [1 1 1])
        alpha(0.20)
        if isequal(speciesNames{i},'K') || isequal(speciesNames{i},'K_2') || isequal(speciesNames{i},'K_2Rb')
            text(TOFs(i)+TOFWindow/2, 0.95*ymaxzoom, [speciesNames{i},'^+','(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        else
            text(TOFs(i)+TOFWindow/2, 0.85*ymaxzoom, [speciesNames{i},'^+','(N = ',num2str(totCountsSpecies(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        end
    end
    
    subplot(3,1,3)
    plot(TOFTimeAll,TOFCountsBkgd,'k')
    hold off
    xlim([TOFMin,TOFMax])
    ylim([0 ymaxzoom])
    grid on
    grid minor
    set(gca,'FontSize',14);
    xlabel('Time-of-flight (ns)', 'FontSize', 16)
    ylabel('Ion counts', 'FontSize', 16)
    title([filename, ', TOF spectrum of shot # ',num2str(shotNumBkgdStart),'-',num2str(shotNumBkgdEnd)], 'Interpreter', 'none')
    
    
    for i = 1:length(speciesNames)
        patch([TOFs(i)-TOFWindow/2 TOFs(i)-TOFWindow/2 TOFs(i)+TOFWindow/2 TOFs(i)+TOFWindow/2], ...
            [-1 1.3*max(TOFCountsAll) 1.3*max(TOFCountsAll) -1], ...
            colorCodes{i}, 'EdgeColor', [1 1 1])
        alpha(0.20)
        if isequal(speciesNames{i},'K') || isequal(speciesNames{i},'K_2') || isequal(speciesNames{i},'K_2Rb')
            text(TOFs(i)+TOFWindow/2, 0.95*ymaxzoom, [speciesNames{i},'^+','(N = ',num2str(totCountsSpeciesBkgd(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        else
            text(TOFs(i)+TOFWindow/2, 0.85*ymaxzoom, [speciesNames{i},'^+','(N = ',num2str(totCountsSpeciesBkgd(i)),')'], 'FontSize', 14, 'Color', colorCodes{i})
        end
    end
    
end

%% Centroid analysis
% if plotCentroidsFlag
%
%     h6 = figure();
%     scrsz = get(groot, 'Screensize');
%     set(h6, 'Position', [scrsz(3) 1 0.6*scrsz(3) 0.6*scrsz(4)])
%
%     subplot(2,1,1)
%     for i = 1:length(speciesNames)
%         if ~strcmp(speciesNames{i},'K_2') && ~strcmp(speciesNames{i},'K_2Rb') %Exclude species from the centroid plots
%             plot(xCentSpecies(i),yCentSpecies(i),'o','Color',colorCodes{i},'MarkerSize',10,'LineWidth',2);
%             text(xCentSpecies(i) + 0.2,yCentSpecies(i),[speciesNames{i},'^+'],'Color',colorCodes{i},'FontSize',14);
%             hold on
%         end
%     end
%     hold off
%     grid on
%     grid minor
%     axis image
%     xlim([min(xCentSpecies)-0.2*range(xCentSpecies),max(xCentSpecies)+0.2*range(xCentSpecies)])
%     ylim([min(yCentSpecies)-0.2*range(yCentSpecies),max(yCentSpecies)+0.2*range(yCentSpecies)])
%     xlabel('x (mm)','FontSize',14)
%     ylabel('y (mm)','FontSize',14)
%     title([filename, ', Centroids of various species on the MCP'], 'Interpreter', 'none','FontSize',14)
%
%     subplot(2,1,2)
%     for i = 1:length(speciesNames)
%         if ~strcmp(speciesNames{i},'K_2') && ~strcmp(speciesNames{i},'K_2Rb') %Exclude species from the centroid plots
%            plot(speciesMasses(i),xCentSpecies(i),'o','Color',colorCodes{i},'MarkerSize',10,'LineWidth',2);
%            text(speciesMasses(i) + 5,xCentSpecies(i),[speciesNames{i},'^+'],'Color',colorCodes{i},'FontSize',14);
%            hold on
%         end
%     end
%     hold off
%     grid on
%     grid minor
%     xlim([0 300])
%     ylim([min(xCentSpecies)-0.2*range(xCentSpecies),0])
% %     ylim([min(xCentSpecies)-0.2*range(xCentSpecies),max(xCentSpecies)+0.2*range(xCentSpecies)])
%     xlabel('Mass (amu)','FontSize',14)
%     ylabel('x (mm)','FontSize',14)
%
% end


%% Fit functions (timing)
    function [b, b_Err, ycurve] = expFit(xdata,ydata,ydata_Err, averageFlag,xcurve)
        
        % Define fit function
        fun = @(b,x) b(1).*exp(-x./b(2));
        
        % Define default initial guess
        if ~exist('b0','var')
            b0 = [400,0.01];
        end
        
        if averageFlag  % Fit with weight
            W = ydata_Err.^(-2);
            [b,residual,jacobian,~,~,~] = nlinfit(xdata,ydata,fun,b0,'Weights',W);
        else
            [b,residual,jacobian,~,~,~] = nlinfit(xdata,ydata,fun,b0);
        end
        
        % Calculate 95% confidence interval of the fitted parameters
        ci = nlparci(b,residual,'Jacobian',jacobian);
        
        b = b';
        b_Err = b - ci(:,1);
        
        ycurve = fun(b,xcurve);
        
    end


    function [b, b_Err, ycurve] = ionSigDecayFit(xdata,ydata,ydata_Err, averageFlag,xcurve)
        
        % Define fit function
        fun = @(b,x) b(1)./(1 + x./b(2));
        %b(1) initial value;
        %b(2) half-life
        
        % Define default initial guess
        b0 = [max(ydata),1];
        
        if averageFlag  % Fit with weight
            W = ydata_Err.^(-2);
            [b,residual,jacobian,~,~,~] = nlinfit(xdata,ydata,fun,b0,'Weights',W);
        else
            [b,residual,jacobian,~,~,~] = nlinfit(xdata,ydata,fun,b0);
        end
        
        % Calculate 95% confidence interval of the fitted parameters
        ci = nlparci(b,residual,'Jacobian',jacobian);
        
        b = b';
        b_Err = b - ci(:,1);
        
        ycurve = fun(b,xcurve);
        
    end
end