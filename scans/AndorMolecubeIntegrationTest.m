function AndorMolecubeIntegrationTest()
% This is a work in progress.  Nick

%Initialize and configure Andor
op = AndorConfigure('Bulb','Frame',17,'Kinetics',2);

%Tell Andor to start acquiring
[ret] = StartAcquisition();
CheckError(ret);
disp('Ready to Acquire...')

switch op.Kinetics
    case 1 %Run a sequence that takes a single picture
        CsSingleAtomImage;
    case 2 %Run a sequence that takes two pictures
        CsSingleAtomRamanAlignment()
    otherwise
        error('Too many pictures')
end

%Get images from Andor buffer
AcqImage = AndorGetPictures(op);

% AcqImage =
for j = 1:op.Kinetics
    subplot(op.Kinetics,1,j)
    imagesc(AcqImage(:,:,j))
end