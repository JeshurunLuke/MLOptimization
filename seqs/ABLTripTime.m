function Ttot = ABLTripTime(Magnification,Pquic,PIntOffset,PScienceOffset,Vel1,Vel2,ARate,DRate,stageNum,ABLTrajPlotFlag)
%%%%------------------------Explanation of parameters---------------------
% Ratio4f = 2.4;            ' conversion ratio of our 4f system
% Pquic = 55.0;             ' QUIC trap position [mm]
% PIntOffset = 0./Ratio4f;  % If stageNum > 1, put in PIntOffset;
% TransDist = 10;           % [mm] transfer distance of ODT
% PScienceOffset = TransDist/Ratio4f; % [mm]  transfer distance of ABL cart
% Vel1 = 50;                % velocity for stage 1
% Vel2 = 200;               % velocity for stage 2, inactive if stageNum = 1
% ARate = 700;              ' accel rate [mm/s^2] < 13,000 mm/s^2 (spec), Tested (<42, 000 mm/s^2), 200
% DRate = 500;              ' decel rate [mm/s^2] < 13,000 mm/s^2 (tested), 200
% stageNum = 1; % If stageNum > 1, put in PIntOffset;
% ABLTrajPlotFlag = 1;    %0 mean not plot, 1 means plot
%%%%------------------------------------------------------------------------
    PInt = Pquic + PIntOffset;
    Pscience = Pquic + PScienceOffset;	%	' Science chamber position [mm] <205 mm

    if stageNum == 1
        x1 = Pscience - Pquic;
        ta1 = Vel1./ARate;
        xa1 = 0.5.*ARate.*ta1.^2;
        td1 = Vel1./DRate;
        xd1 = Vel1.*td1 - 0.5.*DRate.*td1.^2;
        xv1 = x1 - xa1 - xd1;
        if xv1 > 0
            ConstVelFlag = 1;
            tv1 = xv1./Vel1;
            Ttot = ta1 + tv1 + td1;
        else
            ConstVelFlag = 0;
            tv1 = 0;
            ta1 = sqrt(2.*x1./(ARate + ARate.^2./DRate));
            td1 = ARate./DRate.*ta1;
            Ttot = ta1 + td1;
        end
    elseif stageNum == 2
        x1 = PInt - Pquic;
        x2 = Pscience - PInt;
        ta1 = Vel1./ARate;
        xa1 = 0.5.*ARate.*ta1.^2;
        ta2 = (Vel2 - Vel1)./ARate;
        xa2 = Vel1.*ta2 + 0.5.*ARate.*ta2.^2;
        td2 = Vel2./DRate;
        xd2 = 0.5.*DRate.*(Vel2./DRate).^2;
        tv1 = (x1 - xa1)./Vel1;
        tv2 = (x2 - xa2 - xd2)./Vel2;
        Ttot = ta1 + tv1 + ta2 + tv2 + td2;
    end

    %% Plot the acceleration, velocity, and position profiles
    dt = 1e-3; % [s] Define time step for the plots
    t = 0:dt:Ttot; % Define the time axis
    a = zeros(1,length(t));
    v = zeros(1,length(t));
    x = zeros(1,length(t));
    for i = 1:(floor(ta1./dt./2))
        a(i) = (4.*ARate./ta1).*t(i);
    end
    for i = (floor(ta1./dt./2) + 1):(floor(ta1./dt))
        a(i) = - (4.*ARate./ta1).*(t(i) - ta1);
    end
    if ConstVelFlag
        for i = ((floor(ta1./dt)) + 1):(floor((ta1 + tv1)./dt))
        a(i) = 0;
        end
    end
    for i = ((floor((ta1 + tv1)./dt)) + 1):floor((ta1 + tv1 + td1./2)./dt)
        a(i) = -(4.*DRate./td1).*(t(i) - (ta1 + tv1));
    end
    for i = (floor((ta1 + tv1 + td1./2)./dt) + 1):length(t)
        a(i) = (4.*DRate./td1).*(t(i) - (ta1 + tv1 + td1));
    end

    for i = 1:length(t)
        v(i) = sum(a(1:i).*dt);
    end

    for i = 1:length(t)
        x(i) = sum(v(1:i).*dt);
    end

    if ABLTrajPlotFlag
        close all
        h1=figure();
        set(h1, 'Position', [-600 750 600 750]);%[left bottom width height] %optimized for single monitor

        ax1 = subplot(3,1,1);
        yyaxis left
        plot(t, x.*Magnification ,'k','LineWidth',2);
        title('Position Profile','FontSize',14);
        xlabel('Time (s)');
        ylabel('Position of ODT (mm)');
        xlim([0 t(length(t))]);
        ylim([0 1.2*max(x.*Magnification)]);
        string1 = ['Total trip time = ',num2str(Ttot.*1e3, '% 100.0f'),' ms'];
        text(0.6.*max(t),0.5.*max(x).*Magnification,string1,'Color','k','FontSize',12)
        yyaxis right
        ylabel('Position of ABL cart (mm)');
        ylim([0 1.2*max(x)]);

        ax2 = subplot(3,1,2);
        yyaxis left
        plot(t, v.*Magnification ,'b','LineWidth',2);
        title('Velocity Profile','FontSize',14);
        xlabel('Time (s)');
        ylabel('Velocity of ODT (mm/s)');
        xlim([0 t(length(t))]);
        ylim([0 1.2*max(v.*Magnification)]);
        string2 = ['Peak velocity = ',num2str(max(v), '% 100.0f'),' mm/s'];
        text(0.6.*max(t),0.75.*max(v).*Magnification,string2,'Color','b','FontSize',12)
        yyaxis right
        ylabel('Velocity of ABL cart (mm/s)');
        ylim([0 1.2*max(v)]);

        ax3 = subplot(3,1,3);
        yyaxis left
        plot(t, a.*Magnification ,'r','LineWidth',2);
        title('Acceleration Profile','FontSize',14);
        xlabel('Time (s)');
        ylabel('Acceleration of ODT (mm/s^2)');
        xlim([0 t(length(t))]);
        ylim([1.2*min(a.*Magnification) 1.2*max(a.*Magnification)]);
        string3 = ['Mean ARate = ',num2str(ARate),' mm/s^2'];
        string4 = ['Mean DRate = ',num2str(DRate),' mm/s^2'];
        text(0.60.*max(t),0.45.*max(a).*Magnification,string3,'Color','r','FontSize',12);
        text(0.60.*max(t),0.30.*max(a).*Magnification,string4,'Color','r','FontSize',12)
        yyaxis right
        ylabel('Acceleration of ABL cart(mm/s^2)');
        ylim([1.2*min(a) 1.2*max(a)]);
    end

    %%
    disp(['ODT transfer takes ',num2str(Ttot.*1000),' ms']);

end