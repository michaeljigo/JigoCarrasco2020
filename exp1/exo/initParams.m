% Initialize task parameters.

function [taskParams, stimParams, stairParams, eyeParams] = initParams

%% Task parameters
% parameters interleaved within a block
taskParams.sfs = [0.75 1.5 3 6 12];
taskParams.loc = [-1 1]; % [left right] hemifield
taskParams.ecc = [0 3.5 7 14];
taskParams.cues = [0 1]; % 0=neutral; 1=exo

% parameters fixed across blocks
taskParams.tilt = 10; % tilt off vertical
% duration labels: [fix driftCheck cue isi stim isi respCue respMessage]
taskParams.duration = [0.3 inf 0.04 0.06 0.05 0.1 1.5 inf];
taskParams.getResponse = [0 0 0 0 0 0 1 0];
taskParams.nTrials = 160; % trials/block

%% Stair parameters
stairParams.n = 1;
stairParams.stepUp = 0.1;
stairParams.stepDown = stairParams.stepUp/3;
stairParams.startLevel = 0.3;
stairParams.startAtReversal = 1;
stairParams.nTrials = 50;
stairParams.nThresh = 5; % # of thresholds per SF and ecc

%% Stimulus parameters
% fixation point
stimParams.fixation.size = [0.4 0.05]; % [width height]
stimParams.fixation.loc = [0 0];
stimParams.fixation.color = [0 0 0];

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

% gabor
stimParams.gabor.size = placeHolderR*2; % make window as large as placeholder

%% Eyetracking parameters
eyeParams.fixWindow = 1;
eyeParams.fixRef = [0 0]; % fixation reference point, initialized at center of screen
eyeParams.fixTime = 0.5; % time needed to maintain fixation at center of screen before drift-correction can be accepted
eyeParams.frames2Break = 3; % number of consecutive frames before a fixation break is considered
eyeParams.breakCounter = 0; % counts the number of frames in which fixation exceeded the window

%% Feedback
stimParams.feedbackSound = mglInstallSound('./feedback.wav');
