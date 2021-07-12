% This function will take an inputted size (x,y) in degrees and eccentricities. 
% The inputted size is the size of the stimulus at the reference eccentricity. 
% Then, the function will  M-scale the size (using equations in Rovamo & Virsu, 1979)
% so that the image will cover the same cortical space at the other eccentricities.

function scaledSize = Mscale(imSize,refEcc,testEcc)

%% Set equations
M0 = 7.99; % mm/deg @ fovea
% temporal visual field
temp = @(ecc)(1+0.29*ecc+0.000055*ecc.^3).^-1*M0;
% nasal visual field
nas = @(ecc)(1+0.33*ecc+0.00007*ecc.^3).^-1*M0;
% superior visual field
sup = @(ecc)(1+0.42*ecc+0.00012*ecc.^3).^-1*M0;
% inferior visual field
inferior = @(ecc)(1+0.42*ecc+0.000055*ecc.^3).^-1*M0;

%% Determine cortical area devoted to each eccentricitiy
% all units: mm/deg
testTemp = temp(testEcc);
testNas = nas(testEcc);
testSup = sup(testEcc);
testInf = inferior(testEcc);

% cortical area at reference eccentricity
refTemp = temp(refEcc);
refNas = nas(refEcc);
refSup = sup(refEcc);
refInf = inferior(refEcc);

%% Convert from cortical area to final image size
% mm covered by image @ reference eccentricity
refTemp = refTemp*imSize;
refNas = refNas*imSize;
refSup = refSup*imSize;
refInf = refInf*imSize;

% converted to units: deg
testTemp = repmat(1./testTemp',1,size(refTemp,2)).*repmat(refTemp,length(testTemp),1);
testNas = repmat(1./testNas',1,size(refNas,2)).*repmat(refNas,length(testNas),1);
testSup = repmat(1./testSup',1,size(refSup,2)).*repmat(refSup,length(testSup),1);
testInf = repmat(1./testInf',1,size(refInf,2)).*repmat(refInf,length(testInf),1);

%% Average across temporal and nasal visual field
% taking the average because the stimuli will be presented in either hemifield
scaledSize(1,:,:) = testTemp;
scaledSize(2,:,:) = testNas;
%scaledSize(3,:,:) = testSup;
%scaledSize(4,:,:) = testInf;
scaledSize = squeeze(mean(scaledSize,1));
if size(scaledSize,2)==1
   scaledSize = scaledSize';
end
