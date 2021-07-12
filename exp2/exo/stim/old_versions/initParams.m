% usage:    [taskParams stimParams stairParams eyeParams] = initParams
% by:       Michael Jigo
% date:     05/22/19
% purpose:  Initialize parameters used in the attention experiment (distractTask.m)
%
% OUTPUTS
%%%%%% UPDATE THIS
% taskParams
%     sfs         spatial frequency (cycles/degree)
%     loc         hemifield: left (-1) and/or right (1) hemifield
%     ecc         eccentricity (degrees of visual angle)
%     cues        cue conditions: neutral (0) and/or peripheral (1)
%     nTrials     trials per block
%     tilt        gabor tilt magnitude (degrees from vertical)
%     duration    segment durations
%                 [fixation checkDrift cue isi stim isi respCue
%                 respMessage]
%     getResponse segment to collect button press
%
%
% stimParams
%     fixation    coordinates for drawing fixation cross (degrees of visual angle)
%     gabor       diameter of gabor (degrees of visual angle)
%     cue         coordinates for drawing cues (degrees of visual angle)
%     feedback    sound used for feedback
%
%
% stairParams
%     see nDown1Up.m for information about parameters
%
%
% eyeParams
%     fixWindow      radius of window for stable fixation
%     fixRef         reference coordinates for fixation point
%     fixTime        time required for fixation to be held for drift correction
%     frames2Break   # of consecutive frames to signal a fixation break
%     breakCounter   counts the number of frames in which fixation exceeded the window

function [taskParams, stimParams, eyeParams] = initParams(subj,session,verifyThresh)

%% Task parameters
% taskParams.sfs = 2.^(0:0.5:4);
taskParams.sfs = [0.5 2.^([0 0.5 1 1.5 2 3 3.5 4])];
taskParams.ecc = [2 6];
taskParams.loc = [-1 1]; % -1=left; 1=right hemifield
if session
   taskParams.cues = [0 1]; % 0=neutral; 1=valid
   taskParams.tilt = [-1 1]; % -1 = CCW; 1 = CW
   taskParams.paramNames = {'sfs' 'loc' 'ecc' 'cues' 'tilt'};
   % create matrix with all combinations of parameters
   taskParams.allParams = allcomb(taskParams.sfs,taskParams.loc,taskParams.ecc,...
      taskParams.cues,taskParams.tilt);
   taskParams.nTrials = 144; % 144 trials/block x 20 blocks = 2160 trials (60 trials per SF x ecc x cue)
   taskParams.nBlocks = 10; % ideally 20 blocks/session;
else
   taskParams.paramNames = {'sfs' 'loc' 'ecc'};
   taskParams.allParams = allcomb(taskParams.sfs,taskParams.loc,taskParams.ecc);
   taskParams.nTrials = 108; % 108 trials/block x 5 blocks = 540 trials (30 trials per SF x ecc)
   taskParams.nBlocks = 5; % ideally 10 blocks/session
   taskParams.startContrast = log10(0.5);
   taskParams.psiM = initPsi(subj,taskParams);
   if verifyThresh
       taskParams.nBlocks = 8;
   end
   taskParams.verifyThresh = verifyThresh;
end

% duration labels: [fix driftCheck cue isi stim isi respCue respMessage]
taskParams.duration = [0.1 inf 0.06 0.04 0.15 0.1 2.5 inf 0.35];
% taskParams.duration = [0.1 inf 0.06 0.04 inf 0.1 2.5 inf 0.35];
taskParams.getResponse = [0 0 0 0 0 0 1 0 0];

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
stimParams.fixation.intensity = 0.35;

% gabor
stimParams.gabor.size = 4; % gabor diameter in visual degrees
stimParams.gabor.tiltMagnitude = 45; % tilt off vertical

% circular cue
stimParams.cue.radius = 0.5;
stimParams.cue.color = [1 1 1];
stimParams.cue.elevation = (stimParams.gabor.size/2)+1.75; % degrees from midline 
stimParams.cue.elevation = [stimParams.cue.elevation -1*stimParams.cue.elevation];

% feedback
stimParams.feedbackSound = mglInstallSound('./feedback.wav');

%% Eyetracking parameters
eyeParams.fixWindow = 1.5;
eyeParams.fixRef = [0 0]; % fixation reference point, initialized at center of screen
eyeParams.fixTime = 0.1; % time needed to maintain fixation at center of screen before drift-correction can be accepted
eyeParams.frames2Break = 3; % number of consecutive frames before a fixation break is considered
eyeParams.breakCounter = 0; % counts the number of frames in which fixation exceeded the window
eyeParams.recalibWaitTime = 0.75; % seconds before re-calibrating eyetracker
eyeParams.recalibrate = 0;
