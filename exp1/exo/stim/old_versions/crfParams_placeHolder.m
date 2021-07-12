% Initialize task parameters.

function [taskParams, stimParams, eyeParams] = crfParams_placeHolder

%% Task parameters
% parameters interleaved within a block
taskParams.sfs = 0.75;
taskParams.loc = 1; % [left right] hemifield
taskParams.ecc = [0 14];
taskParams.cues = [0 1]; % 0=neutral; 1=exo
taskParams.contrast = logspace(log10(0.01),log10(0.25),6);

% determine # of trials by taking product of # of conditions
taskParams.nTrials = prod(structfun(@(x) length(x),taskParams))*10;

% parameters fixed across blocks
taskParams.tilt = 8; % tilt off vertical
% duration labels: [fix driftCheck cue isi stim isi respCue respMessage]
taskParams.duration = [0.3 inf 0.04 0.06 0.05 0.06 1.5 inf];
taskParams.getResponse = [0 0 0 0 0 0 1 0];

%% Stimulus parameters
% fixation cross
fixLength = 0.5; % length of each line in cross in degrees of visual angle
[x0_up,y0_up] = pol2cart(5*pi/4,fixLength/2);
[x1_up,y1_up] = pol2cart(pi/4,fixLength/2);
[x0_down,y0_down] = pol2cart(3*pi/4,fixLength/2);
[x1_down,y1_down] = pol2cart(7*pi/4,fixLength/2);
stimParams.fixation.x = [x0_up x0_down x1_up x1_down];
stimParams.fixation.y = [y0_up y0_down y1_up y1_down];
stimParams.fixation.size = 3;
stimParams.fixation.color = [0 0 0];

% gabor
stimParams.gabor.size = 3; % gabor diameter in visual degrees

% placeholder
thickness = 0.025;
placeHolderR = 1.625;
stimParams.placeHolder.innerR = placeHolderR-thickness/2;
stimParams.placeHolder.outerR = placeHolderR+thickness/2;
stimParams.placeHolder.medR = placeHolderR;
stimParams.placeHolder.color = [0 0 0];

% cue
thickness = 0.05;
stimParams.cue.thick = thickness;
stimParams.cue.innerR = placeHolderR-thickness/2;
stimParams.cue.outerR = placeHolderR+thickness/2;
stimParams.cue.color = [1 1 1];

%% Eyetracking parameters
eyeParams.fixWindow = 1;
eyeParams.fixRef = [0 0]; % fixation reference point, initialized at center of screen
eyeParams.fixTime = 0.5; % time needed to maintain fixation at center of screen before drift-correction can be accepted
eyeParams.frames2Break = 3; % number of consecutive frames before a fixation break is considered
eyeParams.breakCounter = 0; % counts the number of frames in which fixation exceeded the window

%% Feedback
stimParams.feedbackSound = mglInstallSound('./feedback.wav');
