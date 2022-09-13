function res=runScan(cb, varargin)
% if is(varargin{1}, 'ScanGroup')
%     varargin{1} = sg.get_scanaxis(1, 1);
% end
%%%------------Examples--------------------
% runScan(@(varargin) ExpSeq(), 4, 'random', {1, 2}, {2, 3}) %for testing
% runScan(@mainHighB, 4, 'random', {1, 2});         %This one works 8/3/2018
% runScan(@mainHighB, 4, 'random', [1:1:10]);         %This one works 8/3/2018
% The following needs more work
% x1s = [1, 2, 3];
% x2s = [4, 5, 6];
% xlist = {};
% for x1 = x1s
%     for x2 = x2s
%         xlist{end + 1} = {x1, x2};
%     end
% end
% runScan(@(varargin) ExpSeq(), 1, xlist{:})
% % %-------The following commands are for setting Valon frequency---
% v = Valon.get('COM19');     % open USB port COM19
% Ch = 1; % 1 - Valon channel for 690nm, 2 - Valon channel for 970 nm
% fx = 282.9;   % [MHz]
% v.set_freq(Ch, fx, 1);      % set_freq(self, source, freq_mhz, flag_disp)
% Ch = 2; % 1 - Valon channel for 690nm, 2 - Valon channel for 970 nm
% fx = 345.9;   % [MHz]
% v.set_freq(Ch, fx, 1);      % set_freq(self, source, freq_mhz, flag_disp)
% v.delete();
%% ------end----------------
flag_Ion = 0;       % 0 - disable YAG or Synchronization for ionization, 1 - enable
flag_ODimage = ~flag_Ion;   % 0 - disable OD image, 1 - enable
% flag_ODimage = 1;
flag_Valon = 0;     % STIRAP valon 0 - disable Valon ramp, 1 - enable Valon ramp
flag_Valon_KRb = 0; % KRb rotation transition Valon 2.2GHz
flag_ScanFG = 0;
flag_ScanLiopStar = 0;
flag_ScanREMPI = 1;
flag_ScanKeithley = 0;      %for REMPI intensity
Ch = 2;             % 1 - Valon channel for 690nm, 2 - Valon channel for 970 nm
f690 = 278.14;       % [MHz] center EO frequency for 690 nm N = 0 -> 283.40; N = 2 -> 283.40
f970 = 349.21;     % 344.10 [MHz] center EO frequency for 970 nm (11/12/2018),
if Ch == 1
    f0 = f690;
elseif Ch == 2
    f0 = f970;
end
df = 0.1;                     % [MHz] stepsize for ramping
narginIn = nargin;
    function before_start(seq_num, args)
        % ---set MemoryMap for other matlab instances-----
        m = MemoryMap;
        m.Data(1).numSeq = seq_num;
        % ---Printout sequence number---
        fprintf('Running %d: ', seq_num);
        format longG
        disp(args);
        
%         %%---comment the following for scanning parameters --------
         if (abs(args{1})==0 || abs(args{1})==1)
             flag_Ion = 0;       % 0 - disable YAG or Synchronization for ionization, 1 - enable
             flag_ODimage = ~flag_Ion;   % 0 - disable OD image, 1 - enable         
         else
             flag_Ion = 1;       % 0 - disable YAG or Synchronization for ionization, 1 - enable
             flag_ODimage = ~flag_Ion;   % 0 - disable OD image, 1 - enable
         end        
         if abs(args{1})== 0
             flag_Ion = 0;       % 0 - disable YAG or Synchronization for ionization, 1 - enable
             flag_ODimage = ~flag_Ion;   % 0 - disable OD image, 1 - enable         
         else
             flag_Ion = 1;       % 0 - disable YAG or Synchronization for ionization, 1 - enable
             flag_ODimage = ~flag_Ion;   % 0 - disable OD image, 1 - enable
         end
%         %-------------------------
        
        if flag_ODimage
            m.Data(1).flagCam = 1;
        else
            m.Data(1).flagCam = 0;
        end
        if narginIn > 2
            m.Data(1).scanflag = 1;
        else
            m.Data(1).scanflag = 0;
        end
        % --- Enable YAG or Synchronization for ionization---
%          if flag_Ion
            if flag_ScanLiopStar
                setLiopStar(1,args{1})
            end
            if flag_ScanFG
            %             ThorlabsEll0ControlBack;
                %                 agilentFunGenCtrl('yagBurstOn');%Sync ionization func generator to FPGA 10Hz clock
                %                 agilentFunGenCtrl('edgeWaveBurst');%Sync ionization func generator to FPGA 10Hz clock
                yagFreq = 10e3; %[Hz]
                tBurst = 1;   %[s]
                tkillDelay = -125.*1e-9;       %[s]was -120.*1e-9;
                %                 tkillDelay =args{1}.*1e-9;       %[s]
                tODTOff = 50e-6;
                %                 tBurst = args{1};   %[s]
                %                 tODTLead = 0e-6;
                %                 tODTOff = 71e-6;
                %                 BK_4054B_Ionization(yagFreq, tBurst, tkillDelay, tODTOff)
                ionTimingDelay(yagFreq, tBurst, tkillDelay, tODTOff)
                disp('------------BK 4054B status------------')
                disp(['yag freqency is set to ', num2str(yagFreq), ' Hz'])
                disp(['tBurst is set to ', num2str(tBurst), ' s'])
                disp(['UV delay relative to kill pulse is set to ', num2str(tkillDelay*1e6), ' us'])
                disp(['ODT off time is set to ', num2str(tODTOff*1e6), ' us'])
                disp('---------------------------------------')
            end
%          end
        %%---set KRb N=1 Valon synthesizer--
        if flag_Valon_KRb            
            v = Valon.get('COM24');
            Ch=1;
            if args{1} < 2220
                f0= args{1}+2220;        %[MHz]
            else
                f0= args{1};        %[MHz]
            end
            v.set_freq(Ch, f0, 1);
            v.delete();
        end
        
        % ---set Valon Synthesizer------
        if flag_Valon && (abs(args{1}-f0) < 50)
            v = Valon.get('COM19');     % open USB port COM19
%             v.set_freq(Ch, f0);         % set_freq(Channel, frequency [MHz])
            ftarget = args{1};
            v.set_freq(Ch, ftarget, 1);         % set_freq(Channel, frequency [MHz])
%             fnow = f0;
%             while (abs(ftarget-fnow) > 0)
%                 if abs(ftarget-fnow) > df
%                     fnow = fnow + sign(ftarget-fnow).*df;
%                 else
%                     fnow = ftarget;
%                 end
%                 if abs(ftarget-fnow)==0
%                     v.set_freq(Ch, fnow, 1);         % set_freq(self, source, freq_mhz, flag_disp)
%                 else
%                     v.set_freq(Ch, fnow);         % set_freq(Channel, frequency [MHz])
%                 end
%                 pause(0.01);
%             end
            v.delete();                 % close USBf port, delete this if need faster speed
        end

        % ---- scan REMPI frequency -----
        if flag_Ion
            if flag_ScanREMPI
                m.Data(1).freqREMPISet1 = args{1};
                m.Data(1).freqREMPISet2 = args{2};
            end
            if flag_ScanKeithley
                m.Data(1).Keithley2230GVoltage = args{1};
                disp('=========================================')
                disp(['Keithley 2230 CH3 voltage set to ', num2str(args{1}), ' V'])
                disp('=========================================')
            end
        end
    end
    function after_finish(seq_num, args)
%         hdl.setarg(1, seq_num);
        m = MemoryMap;
        if narginIn > 2
            m.Data(1).x1 = args{1};
            if length(args) > 1
                m.Data(1).x2 = args{2};
            end
        end
        % --- record the datetime of when the sequence finished ---
        m.Data(1).seqFinDateTime = now;
        % --- record wavemeter reading -----
        Dt_avg = 10; %[s] wavemeter reading averaging time
%         f0_670 = 447685.4;
%         f0_690 = 434922.593;
        f0_650 = 462922.6;%462922.6 is for K2 Q6,
        f0_670 = 445002.1;%445002.1 is for Rb2 Q5, 
        f0_690 = 434922.593+0.0375;
        filename = '20200723.csv';
        [~, f_mean_650] = ReadWavemeterNow2(filename, Dt_avg, f0_650 - 5000, f0_650 + 5000);
        [~, f_mean_670] = ReadWavemeterNow2(filename, Dt_avg, f0_670 - 5000, f0_670 + 5000);
        [~, f_mean_690] = ReadWavemeterNow2(filename, Dt_avg, f0_690 - 5000, f0_690 + 5000);
%         m.Data(1).freqREMPIAct = f_mean;
        % --- determine is the laser is locked at the end of the sequence-----
        freqREMPIDev = 0.050;
        flag_690_calibration = 1;
        %%%--incorporate 690 calibration--------
        if flag_690_calibration
%             f690_Now = f_mean_690;
            df690_Now = f_mean_690 - f0_690;
            f_mean_650 = f_mean_650 - df690_Now;
            f_mean_670 = f_mean_670 - df690_Now;
        end
        if abs(m.Data(1).freqREMPISet1 - f_mean_650) < freqREMPIDev && abs(m.Data(1).freqREMPISet2 - f_mean_670) < freqREMPIDev
            flagREMPILock = 1;
        else
            flagREMPILock = 0;
        end
        m.Data(1).flagREMPILock = flagREMPILock;
        % --- display REMPI lock information ---
        if flag_ScanREMPI && flag_Ion
            disp('=========================================')
            disp(['650 nm laser Freq. Set = ',num2str(args{1}), ' GHz'])
            disp(['650 nm laser Freq. Act. = ',num2str(f_mean_650), ' GHz'])
            disp(['650 nm frequency deviation = ',num2str(f_mean_650 - args{1}), ' GHz'])
            disp('-----------------------------------------')
            disp(['670 nm laser Freq. Set = ',num2str(args{2}), ' GHz'])
            disp(['670 nm laser Freq. Act. = ',num2str(f_mean_670), ' GHz'])
            disp(['670 nm frequency deviation = ',num2str(f_mean_670 - args{2}), ' GHz'])
            if flagREMPILock
                disp('REMPI Laser is locked.')
            else
                disp('REMPI Laser is unlocked!')
            end
            disp('=========================================')
        end
        % --- disable YAG or Synchronization for ionization---
        if flag_Ion
            m.Data(1).flagCam = 2;      %trigger cobold
            % % %             ThorlabsEll0ControlForward;
            % % %                         agilentFunGenCtrl('yagBurstOff');
        end
%         % ---set Valon Synthesizer------
%         if flag_Valon && (abs(args{1}-f0) < 100)
%             v = Valon.get('COM19');     % open USB port COM19
%             fnow = args{1};
%             ftarget = f0;
%             %             v.set_freq(Ch, f0);         % set_freq(Channel, frequency [MHz])
%             while (abs(ftarget-fnow) > 0)
%                 if abs(ftarget-fnow) > df
%                     fnow = fnow + sign(ftarget-fnow).*df;
%                 else
%                     fnow = ftarget;
%                 end
%                 if abs(ftarget-fnow)==0
%                     v.set_freq(Ch, fnow, 1);         % set_freq(self, source, freq_mhz, flag_disp)
%                 else
%                     v.set_freq(Ch, fnow);         % set_freq(Channel, frequency [MHz])
%                 end
%                 pause(0.01);
%             end
%             v.delete();                 % close USB port, delete this if need faster speed
%         end
    end
% hdl = FacyOnCleanup(@mainEmailTest, 0);       %sending emails
res = runSeq(cb, 'tstartwait', 0.5, 'pre_cb', @before_start, 'post_cb', @after_finish, varargin{:});
% if flag_Ion
%     agilentFunGenCtrl('yagBurstOff');       %swith ionization func generator to internal 10Hz clock
% end
end
