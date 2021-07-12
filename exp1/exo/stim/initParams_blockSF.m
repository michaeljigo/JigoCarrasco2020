% usage:    [taskParams stimParams stairParams eyeParams] = initParams_blockSF
% by:       Michael Jigo
% date:     10/31/18
% purpose:  Initialize parameters for the thresholding and mein experimental sessions
%

function [taskParams, stimParams, stairParams, eyeParams] = initParams_blockSF(session)

%% Task parameters
% blocked parameters
taskParams.all_sfs = [0.5 1 2 4 8 11]; 

% interleaved parameters
taskParams.loc = [-1 1]; 
taskParams.ecc = [0 3 6 12];
if ~session
   % initialization session: a rough estimate of threshold will be determined
   taskParams.cues = 0; % only neutral condition will be tested
else
   % main session: method of constant stimuli (MOCS) will be used
   taskParams.cues = [0 1];

   % -1 = CCW; 1 = CW; equal presentation of tilts will facilitate d' calculation
   taskParams.tilt = [-1 1]; 

   % indices for the actual contrast levels that will be tested
   % (0 = 100% contrast, 1-4 will be log units of contrast away from the threshold estimate found in session 0)
   taskParams.contrast = [1 2 3 4 5]; 
end

% determine # of trials by taking product of # of conditions
if ~session
   taskParams.nTrials = 160; % 160 trials/block
else
   taskParams.nTrials = prod(structfun(@(x) length(x),removeFields(taskParams,{'all_sfs'}))); % 160 trials/block
end

% duration labels: [fix driftCheck cue isi stim isi respCue respMessage]
taskParams.duration = [0.1 inf 0.06 0.04 0.12 0.1 1 inf 0.2];
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
stimParams.gabor.size = ceil(1/min(taskParams.all_sfs)*2); % gabor diameter in visual degrees
stimParams.gabor.tiltMagnitude = 45; % tilt off vertical

% circular cue
stimParams.cue.radius = 0.5;
stimParams.cue.color = [0 0.5 0.13];
stimParams.cue.elevation = (stimParams.gabor.size/2)+1.75; % degrees from midline 
stimParams.cue.elevation = [stimParams.cue.elevation -1*stimParams.cue.elevation];

% feedback
stimParams.feedbackSound = mglInstallSound('./feedback.wav');

%% Stair parameters
stairParams = [];
if ~session
   stairParams.n = 1; % 1up-1down
   stairParams.stepDown = 0.1; % small step down (log units) to finely sample CRF
   stairParams.stepUp = stairParams.stepDown/0.4142; % step ratio chosen for 70.71% perf
   stairParams.nTrials = 1e3; % There will be ideally only 40 trials, but increasing nTrials will allow me to resume staircases if they don't converge
   stairParams.nBoundTrials = 0;
   stairParams.boundLevel = 0;
   stairParams.stayWithinBounds = [log10(1e-3) 0];
   stairParams.startLevel = 0;
end

%% Eyetracking parameters
eyeParams.fixWindow = 1;
eyeParams.fixRef = [0 0]; % fixation reference point, initialized at center of screen
eyeParams.fixTime = 0.1; % time needed to maintain fixation at center of screen before drift-correction can be accepted
eyeParams.frames2Break = 3; % number of consecutive frames before a fixation break is considered
eyeParams.breakCounter = 0; % counts the number of frames in which fixation exceeded the window
eyeParams.recalibWaitTime = 0.75; % seconds before re-calibrating eyetracker
eyeParams.recalibrate = 0;
