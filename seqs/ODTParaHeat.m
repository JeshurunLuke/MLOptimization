function s = ODTParaHeat(s1,VODT,tDrive,AmpV,Freq)

if(~exist('s1','var'))
    s = ExpSeq();
else
    s = s1;
end

if ~exist('tDrive','var')
    tDrive = 1;%[s]
end

if ~exist('AmpV','var')
    AmpV = 0.5;%[A]
end

if ~exist('Freq','var')
    Freq = 10;%[Hz]
end

% Sinusoidal drive parameters
% Period = 1./Freq;
% dt = Period./16; %Using 1/16th of the period as time step

% % Make sure to modulate the correct ODT
%
% N = floor(tDrive./dt);
%
% for i = 1:N
%     V1 = AmpV.*sin(i.*dt.*2.*pi.*Freq) + VODT;
%     s.add('ODT1',V1);
%     s.wait(dt);
% end

if tDrive > 10 %[s]
    error('ODT Parametric heating time > 10s');
end
disp(['ODT Parametric heating takes ',num2str(tDrive),'s']);

s.addStep(tDrive) ...
    .add('ODT1', @(t) AmpV.*sin(t*2*pi.*Freq) + VODT);

if(~exist('s1','var'))
    s.run();
end

end