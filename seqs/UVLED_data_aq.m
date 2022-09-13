function rst = UVLED_data_aq()
close all
clear

growthExp = @(a, tau, y0, x) ...
    y0 + a.*(1-exp(-(x)./tau));
rst = [];

nRun = 1;

tUVExposure = 2; % how long is the UV light on before MOT 
nAvg = 1; % number of traces to be averaged (useful for K data)
fitRb = 1; % initial guess choice; 1 = fit Rb, 2 = fit K
uv_light = 1; % 1 = turn ON UV, 0 = turn OFF

if uv_light
    plot_title = strcat('Rb, with UV light, #avg = ', num2str(nAvg), ', t UVexposure = ', num2str(tUVExposure), ' s');
else
    plot_title = strcat('Rb, NO UV light, #avg = ', num2str(nAvg));
end
taus = [];
y_temp = [];
tic
for cnt = 1:nRun
    for i = 1:nAvg
        disp(['Run # ' num2str(i)]);
        pause(4);
        tic
        mainUVLED(tUVExposure, uv_light);
        pause(8 + tUVExposure); % Wait time for the mainUVLED routine to finish (otherwise scope won't update data)
        toc
        data = scopeData(2);
        x = data(:,1);
        y_temp = [y_temp data(:,2)];
    end

    y_full = mean(y_temp, 2); % average over nAvg traces
    x_full = x;
    
    % Plot the whole scope trace
    subplot(nRun, 1, cnt);
    plot(x_full, y_full, 'ok');
    
    % Only fit the MOT signal part of the trace (no background)
    y_min = 1.2;
    y_start_ix = find(y_full>y_min, 1);
    x_2_fit = x_full(y_full>=y_full(y_start_ix));   

    y_2_fit = y_full(y_start_ix:end);
    max_size = min(size(y_2_fit), size(x_2_fit));
    y_2_fit = y_2_fit(1:max_size) - y_min;
    x_2_fit = x_2_fit(1:max_size);
    
    title(plot_title);
    xlabel('time (s)');
    ylabel('MOT signal (V)');

    % Fitting code
    if fitRb
        f = fit(x_2_fit,y_2_fit,growthExp, 'StartPoint', [y_2_fit(end)-0.9 1 y_2_fit(1)]);
        xfit = x_2_fit - x_2_fit(1);
        fitres = coeffvalues(f);
        a = fitres(1);
        tau = fitres(2);
        y0 = fitres(3);
        taus = [taus, tau];
    %     b = fitres(3);
    %     x0 = fitres(4);
        disp('----------fit result----------');
        disp(['1/tau = ', num2str(1/tau),' Hz']);
    %     disp(['y offset = ', num2str(b),' V']);
        disp('----------end----------');
        yfit = a.*(1-exp(-xfit./tau)) + y0 + y_min; %for plotting
        xfit = x_2_fit + x_2_fit(1); % for plotting, add the x offset
        Xdim=min(xfit)+(max(xfit)-min(xfit))*1/10;
        Ydim=0+(max(yfit))*2/10;
        string1 = strcat('\tau = ',num2str(tau),' s, Amp = ', num2str(a), ' V, y0 = ', num2str(y0), ' V');
        string2 = strcat('Signal (w/o bg) = Amp + y0 = ',num2str(a+y0), ' V');
        text(Xdim,Ydim,string1,'Color','red');
        text(Xdim,Ydim-0.3,string2,'Color','red');
        hold on
        plot(xfit, yfit, '-r','LineWidth',2);
        hold off
    else
        f = fit(x_2_fit,y_2_fit,growthExp, 'StartPoint', [y_2_fit(end)-0.05 1 y_2_fit(1)]);
        xfit = x_2_fit - x_2_fit(1); % fit from x = 0
        disp(xfit(1:10));
        fitres = coeffvalues(f);
        a = fitres(1);
        tau = fitres(2);
        y0 = fitres(3);
        taus = [taus, tau];
        disp('----------fit result----------');
        disp(['1/tau = ', num2str(1/tau),' Hz']);
        disp('----------end----------');
        yfit = a.*(1-exp(-xfit./tau)) + y0;
        xfit = x_2_fit + x_2_fit(1); % for plotting, add the x offset
        Xdim=min(xfit)+(max(xfit)-min(xfit))*1/10;
        Ydim=0+(max(yfit))*2/10;
        string1 = strcat('\tau = ',num2str(tau),' s, Amp = ',num2str(a), ' V, y0 = ', num2str(y0));
        text(Xdim,Ydim,string1,'Color','red');
        hold on
        plot(xfit, yfit, '-r','LineWidth',2);
        hold off
    end
%     mainUVLED(0,9);
%     data = scopeData();
%     x = data(:,1);
%     y = data(:,2);
%     g = fit(x,y,growthExp, 'StartPoint', [y(end)-y(1) 1 y(1)]);
%
%     mainUVLED(10,9);
%     data = scopeData();
%     x = data(:,1);
%     y = data(:,2);
%     h = fit(x,y,growthExp, 'StartPoint', [y(end)-y(1) 1 y(1)]);

%     [coeffvalues(f) coeffvalues(g) coeffvalues(h)]
%     rst(cnt,:) = [coeffvalues(f)]; %coeffvalues(g) coeffvalues(h)];

end
toc

disp(['Mean tau = ', num2str(mean(taus)) , 's +- ', num2str(std(taus)), 's' ]);

figure
plot(x_2_fit, y_2_fit + y_min, 'or');
hold on
plot(xfit, yfit, '-k','LineWidth',2);
hold off

end

