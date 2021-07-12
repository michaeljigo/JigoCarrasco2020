% usage:    [taskParams stimParams stairParams eyeParams] = initParams
% by:       Michael Jigo
% date:     07/01/18
% purpose:  Initialize parameters in the main experiment (csfTask.m).
%
% OUTPUTS
% taskParams
%     sfs         spatial frequency (cycles/degree)
%     loc         hemifield: left (-1) and/or right (1) hemifield
%     ecc         eccentricity (degrees of visual angle)
%     cues        cue conditions: neutral (0) and/or peripheral (1)
%     nTrials     trials per block
%     tilt        gabor tilt magnitude (degrees from vertical)
%     duration    segment durations
%                 [fixation checkDrift cue isi stim isi respCue respMessage]
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

function [taskParams, stimParams, stairParams, eyeParams] = initParams_stairHL

%% Task parameters
% parameters interleaved within a block
taskParams.sfs = [0.75 1.5 3 6 9 12];
taskParams.loc = [-1 1]; 
taskParams.ecc = [0 7 14];
taskParams.cues = [0 1];

% determine # of trials by taking product of # of conditions
taskParams.nTrials = prod(structfun(@(x) length(x),taskParams))*2;

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

% cue (cue size will change with eccentricity)
foveaSize = [0.7 0.1];
%stimParams.cue.size = Mscale(foveaSize,0,taskParams.ecc);
stimParams.cue.size = repmat(foveaSize,length(taskParams.ecc),1);
stimParams.cue.elevation = (stimParams.gabor.size/2)+1.75; % degrees from midline 
stimParams.cue.elevation = [stimParams.cue.elevation -1*stimParams.cue.elevation];
stimParams.cue.color = [1 1 1];

% circular cue
stimParams.cue.radius = 0.35;
stimParams.cue.color = -1;

% feedback
stimParams.feedbackSound = mglInstallSound('./feedback.wav');

%% Stair parameters
stairParams.n = 2;
stairParams.stepDown = 0.1; % small step down (log units) to finely sample CRF
stairParams.stepUp = stairParams.stepDown/0.5488; % step ratio chosen for 80.35% perf
stairParams.nTrials = 50;
stairParams.nBoundTrials = 5;
stairParams.boundLevel = 0;
stairParams.stayWithinBounds = [log10(1e-3) 0];
stairParams.stairRep = 1; % counter keeping track of the current staircase repition

% set the start levels for the two interleaved staircases that will be run
allStartLevels = log10([0.3 0.005]);
allStartLevels = unique(nchoosek(repmat(allStartLevels,1,4),2),'rows');
for c = 1:length(taskParams.cues)
   for s = 1:length(taskParams.sfs)
      for e = 1:length(taskParams.ecc)
         startLevels(c,s,e,:,:) = allStartLevels(randperm(size(allStartLevels,1)),:); 
      end
   end
end
stairParams.startLevels = permute(startLevels,[4 1 2 5 3]);

%% Eyetracking parameters
eyeParams.fixWindow = 1;
eyeParams.fixRef = [0 0]; % fixation reference point, initialized at center of screen
eyeParams.fixTime = 0.5; % time needed to maintain fixation at center of screen before drift-correction can be accepted
eyeParams.frames2Break = 3; % number of consecutive frames before a fixation break is considered
eyeParams.breakCounter = 0; % counts the number of frames in which fixation exceeded the window
eyeParams.recalibWaitTime = 0.75; % seconds before re-calibrating eyetracker
eyeParams.recalibrate = 0;
