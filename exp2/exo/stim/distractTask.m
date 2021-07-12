% Purpose: Run distractor task @ a single contrast level.

function distractTask(myscreen)
global stimulus

%% Set up task variable for MGL
task{1}.seglen = stimulus.taskParams.duration;
task{1}.getResponse = stimulus.taskParams.getResponse;
task{1}.parameter.dummy = stimulus.taskParams.dummyParam;
task{1}.numTrials = stimulus.taskParams.nTrials;
task{1}.waitForBacktick = 0;


%% Variable for broken fixations
stimulus.brokenTrial = [];
stimulus.brokenTrial.orgNumTrials = task{1}.numTrials;
stimulus.brokenTrial.trialIdx = [];


%% Variables to store accuracy and the parameters tested on each trial
stimulus.accuracy = [];
stimulus.contrast = [];
paramNames = stimulus.taskParams.paramNames;
for p = 1:length(paramNames)
   stimulus.(paramNames{p}) = [];
end
stimulus.distractorSF = [];


%% Display task instructions
taskInstructions


%% Run tasks
[task{1}, myscreen] = initTask(task{1},myscreen,@startSegmentCallback,@screenUpdateCallback,@trialResponseCallback,@startTrialCallback,@endTrialCallback);
tnum = 1;
while (tnum<=length(task))
   [task, myscreen, tnum] = updateTask(task,myscreen,tnum);
   myscreen = tickScreen(myscreen,task);
end


%% Save stimfile
mglClearScreen; mglFlush; mglClearScreen;
perf = nanmean(stimulus.accuracy);
mglTextDraw(sprintf('%.0f%% accuracy',perf*100),[0 1]);
mglTextDraw('Give your eyes a short rest',[0 0]);
mglWaitSecs(1);
mglFlush;
mglWaitSecs(1.5);
endTask(myscreen,task);



%% startTrial
function [task, myscreen] = startTrialCallback(task,myscreen)
global stimulus

% re-initialize order of conditions if we've exhausted all parameter
% combinations or if subject has just started experiment
totalParamComb = size(stimulus.taskParams.allParams,1);
if ~mod(stimulus.trialsCompleted,totalParamComb)
    stimulus.currentParamOrder = stimulus.taskParams.allParams(randperm(totalParamComb),:);
    stimulus.allTrialsCompleted = stimulus.allTrialsCompleted+stimulus.trialsCompleted;
    stimulus.trialsCompleted = 0;
end
      
% get the parameters that will be tested in the current trial
trialn = stimulus.trialsCompleted+1;
paramNames = stimulus.taskParams.paramNames;
for p = 1:length(paramNames)
   thisParamVal = stimulus.currentParamOrder(trialn,p);
   stimulus.thistrial.(paramNames{p}).val = thisParamVal;
   % also store index of the parameter value for ease of indexing
   [~,stimulus.thistrial.(paramNames{p}).idx] = ismember(thisParamVal,stimulus.taskParams.(paramNames{p}));
end


% initialize index for whether the trial is broken or not
stimulus.brokenTrial.trialIdx(task.trialnum) = 0;
% re-initialize break counter
stimulus.eyeParams.breakCounter = 0;


% get threshold estimate for target
thisTrial = stimulus.thistrial;
c = 10^stimulus.thresh(thisTrial.sfs.idx,thisTrial.ecc.idx);
c = min(c,1);

% store contrast of target
stimulus.contrast(task.trialnum) = c;

% generate target grating stimulus for this trial
gaborSize = stimulus.stimParams.gabor.size;
gr = c*mglMakeGrating(gaborSize,gaborSize,thisTrial.sfs.val,...
   90-(stimulus.stimParams.gabor.tiltMagnitude*thisTrial.tilt.val),180);
window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
gabor = 255*(gr.*window+1)/2;
stimulus.target = mglCreateTexture(gabor);


% generate distractor gratings; distractors will be presented at remaining eccentricities in both hemifields
% first, create matrix of possible target locations [hemifield; ecc]
distLoc = [ones(1,numel(stimulus.taskParams.ecc))*-1 ones(1,numel(stimulus.taskParams.ecc)); ...
   fliplr(stimulus.taskParams.ecc) stimulus.taskParams.ecc];
% special case: remove 0 degree distractor if target is presented at fovea
if thisTrial.ecc.val==0
    distLoc = distLoc(:,~ismember(distLoc(2,:),thisTrial.ecc.val));
end
distLoc = distLoc(:,~all(ismember(distLoc,[thisTrial.loc.val; thisTrial.ecc.val])));
[~,distEccIdx] = ismember(distLoc(2,:),stimulus.taskParams.ecc);
% randomize tilts of distractors
distTilts = rand(1,numel(distEccIdx)); tmp = distTilts; tmp(distTilts<0.5) = -1; tmp(distTilts>=0.5) = 1;
distTilts = tmp;

if ~stimulus.distractorType
   % get contrasts for homogenous distractors (i.e., same SF)
   distSF = repmat(thisTrial.sfs.idx,1,numel(distEccIdx));
   c = 10.^stimulus.thresh(thisTrial.sfs.idx,distEccIdx);
else
   % get contrasts for heterogenous distractors (i.e., randomly chosen SFs)
   distSF = randi(numel(stimulus.taskParams.sfs),1,numel(distEccIdx));
   threshIdx = sub2ind(size(stimulus.thresh),distSF,distEccIdx);
   c = 10.^stimulus.thresh(threshIdx);
end
% generate distractor gratings
for i = 1:numel(c)
    thisC = min(c(i),1);
   gr = thisC*mglMakeGrating(gaborSize,gaborSize,stimulus.taskParams.sfs(distSF(i)),...
      90-(stimulus.stimParams.gabor.tiltMagnitude*distTilts(i)),180);
   window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
   gabor = 255*(gr.*window+1)/2;
   stimulus.distractors(i) = mglCreateTexture(gabor);
end

% store SF of distractors
stimulus.thistrial.distractorSF.idx = distSF;
stimulus.thistrial.distractorSF.val = stimulus.taskParams.sfs(distSF);

% store tilts of distractors
stimulus.thistrial.distractorTilt.idx = distSF;
stimulus.thistrial.distractorTilt.val = distTilts;

% store location and eccentricity of each distractor for ease of presentation
stimulus.thistrial.distLoc = distLoc;


%% startSegment
function [task, myscreen] = startSegmentCallback(task,myscreen)
global stimulus

% initialize fixation tracker or recalibrate the eyetracker
if myscreen.eyetracker.init
   switch task.thistrial.thisseg
   case 1 % mandatory fixation period
         % initialize matrix that will hold the x and y eye positions during the 
         % fixation period
         stimulus.eyeParams.fixPos = [];

         % if the trial was broken (due to eye postions outside the fixation window),
         % recalibrate the eyetracker
         if stimulus.eyeParams.recalibrate
            myscreen = eyeCalibDisp(myscreen,...
            'Ask experimenter to re-calibrate eyetracker');
            stimulus.eyeParams.recalibrate = 0;
            stimulus.eyeParams.fixPos = [0 0];
            mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity); mglFlush
            mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity); mglFlush
            mglWaitSecs(1);
         end
      case 2 % drift-check period
         % compute average eye position during fixation period (i.e., segment 1)
         avgPos = nanmean(stimulus.eyeParams.fixPos,1);

         % calculate distance of average eye position to the fixation point
         % NOTE: by default, stimulus.eyeParams.fixRef = [0 0]. on most trials it will
         % equal the average eye position during the mandatory fixation period
         if calcDistance(avgPos,stimulus.eyeParams.fixRef)<=stimulus.eyeParams.fixWindow
            % perform automatic drift correction (i.e., use avg position as new fixation point)
            stimulus.eyeParams.fixRef = avgPos;
            stimulus.eyeParams.driftCorrect = 0;
         else
            % reset the fixation reference point and have the subject recalibrate
            stimulus.eyeParams.fixRef = [0 0];
            stimulus.eyeParams.fixPos = [];
            stimulus.eyeParams.driftCorrect = 1;
            stimulus.eyeParams.waitTime = mglGetSecs;
         end
   end
end

% events that occur regardless of eyetracking
switch task.thistrial.thisseg
   case 8 % after response period
      if task.thistrial.thisseg==8 && ~task.thistrial.gotResponse
         % display message to respond in time
         mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity);
         mglTextDraw('Please respond in time',[0 0]); mglFlush;
         mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity);
         mglTextDraw('Please respond in time',[0 0]); mglFlush;

         % re-do the trial at end of block
         stimulus.brokenTrial.trialIdx(task.trialnum) = 1;
         mglWaitSecs(0.5);
         task = jumpSegment(task);
      elseif task.thistrial.gotResponse
         task = jumpSegment(task);
      end
end


%% screenUpdate
function [task, myscreen] = screenUpdateCallback(task,myscreen)
global stimulus
mglClearScreen

% initialize tracking
if myscreen.eyetracker.init
   eyePos = mglEyelinkGetCurrentEyePos;
   eyeDist = calcDistance(eyePos,stimulus.eyeParams.fixRef);
end


% draw fixation with the given intensity
drawFixation(stimulus.stimParams.fixation.intensity)


% draw stimuli for each segment
switch task.thistrial.thisseg
case 1 % fixation
      % collect eye position during fixation for use during drift correct
      if myscreen.eyetracker.init
         stimulus.eyeParams.fixPos = [stimulus.eyeParams.fixPos; eyePos];
      end
   case 2 % drift-correction
      switch myscreen.eyetracker.init
      case 1
            if stimulus.eyeParams.driftCorrect
               % check whether the subject has fixated within the fixation window for
               % an acceptable period of time (by default: recalibWaitTime = 0.5s)
               if mglGetSecs(stimulus.eyeParams.waitTime)>=stimulus.eyeParams.recalibWaitTime
                  stimulus.eyeParams.recalibrate = 1;
                  % break trial in order to initiate calibration procedure
                  stimulus.brokenTrial.trialIdx(task.trialnum) = 1;
                  mglWaitSecs(1);
                  task = jumpSegment(task,inf);
               end

               % start timer that keeps track of how long the eye has been at fixation
               goodFix = 0;
               if eyeDist<=stimulus.eyeParams.fixWindow
                  goodFix = 1;
                  fixStart = mglGetSecs;
               end
               
               % store eye position and use average as reference when fixation time window is exceeded
               while goodFix
                  fixTime = mglGetSecs(fixStart);
                  stimulus.eyeParams.fixPos = [stimulus.eyeParams.fixPos eyePos];
                  if fixTime>=stimulus.eyeParams.fixTime
                     stimulus.eyeParams.fixRef = nanmean(stimulus.eyeParams.fixPos,1);

                     % remove text, give a short pause, then continue with experiment
                     mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity);
                     mglFlush; mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity); mglFlush;
                     mglWaitSecs(0.5);
                     task = jumpSegment(task);
                     break
                  end
               end
            else
               task = jumpSegment(task);
            end
         otherwise
            task = jumpSegment(task);
      end
    case 3 % cue
        if stimulus.thistrial.cues.val
            % valid cue
            cueLoc = repmat(stimulus.thistrial.ecc.val*stimulus.thistrial.loc.val,1,2);
            elevation = stimulus.stimParams.cue.elevation;
            mglFillOval(cueLoc,elevation,repmat(stimulus.stimParams.cue.radius,1,2),...
                stimulus.stimParams.cue.color);
        else
            % neutral cue
            cueLoc = unique([stimulus.taskParams.ecc*stimulus.taskParams.loc(1) ...
                stimulus.taskParams.ecc*stimulus.taskParams.loc(2)]);
            cueLoc = repmat(cueLoc',1,2);
            elevation = repmat(stimulus.stimParams.cue.elevation,length(cueLoc),1);
            mglFillOval(cueLoc,elevation,repmat(stimulus.stimParams.cue.radius,1,2),...
                stimulus.stimParams.cue.color);
        end
    case 5 % stimulus
        % target
        mglBltTexture(stimulus.target,[stimulus.thistrial.ecc.val*stimulus.thistrial.loc.val 0]);

        % distractors
        xEcc = stimulus.thistrial.distLoc(1,:).*stimulus.thistrial.distLoc(2,:);
        yEcc = zeros(1,numel(xEcc));
        mglBltTexture(stimulus.distractors,[xEcc' yEcc']);

        drawFixation(stimulus.stimParams.fixation.intensity);
    case 7 % response cue
        cueLoc = repmat(stimulus.thistrial.ecc.val*stimulus.thistrial.loc.val,1,2);
        elevation = stimulus.stimParams.cue.elevation;
        mglFillOval(cueLoc,elevation,repmat(stimulus.stimParams.cue.radius,1,2),...
            stimulus.stimParams.cue.color);
end

% implement gaze-contingency
if myscreen.eyetracker.init && ~any(task.thistrial.thisseg==[1 2 7 8 9])
   if eyeDist>stimulus.eyeParams.fixWindow
      stimulus.eyeParams.breakCounter = stimulus.eyeParams.breakCounter+1;
   else
      stimulus.eyeParams.breakCounter = 0;
   end

   % break trial condition
   if stimulus.eyeParams.breakCounter>=stimulus.eyeParams.frames2Break
      stimulus.brokenTrial.trialIdx(task.trialnum) = 1;
      % pause task to make sure subject is ready for next trial
      mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity);
      mglTextDraw('Please fixate',[0 0]);
      mglFlush; mglClearScreen; drawFixation(stimulus.stimParams.fixation.intensity);
      mglTextDraw('Please fixate',[0 0]); mglFlush;
      % play sound for broken fixation
      mglPlaySound('Submarine');
      mglWaitSecs(0.5);
      task = jumpSegment(task,inf);
   end
end


%% trialResponse
function [task, myscreen] = trialResponseCallback(task,myscreen)
global stimulus

% determine accuracy
correct = 0;
resp = find(task.thistrial.buttonState); % 1=CCW; 2=CW

% break trial if two response buttons are pressed
if length(resp)>1
   stimulus.brokenTrial.trialIdx(task.trialnum) = 1;
   mglClearScreen; mglTextDraw('Please respond with one key',[0 0]);
   mglFlush; mglClearScreen;
   mglTextDraw('Please respond with one key',[0 0]); mglFlush;
   mglWaitSecs(0.5);
else
   % record and update staircase if one response key was pressed
   if resp==1 && stimulus.thistrial.tilt.val==-1
      correct = 1; % CCW tilt, CCW response
   elseif resp==2 && stimulus.thistrial.tilt.val==1
      correct = 1; % CW tilt, CW response
   end

   % store accuracy
   stimulus.accuracy(task.trialnum) = correct;

   % feedback
   if ~correct
      mglPlaySound(stimulus.stimParams.feedbackSound);
   end
end

% go to next trial
task = jumpSegment(task);

%% endTrialCallback
function [task, myscreen] = endTrialCallback(task,myscreen)
global stimulus

% store the parameters that were presented in this trial
paramNames = stimulus.taskParams.paramNames;
paramNames(ismember(paramNames,'contrast')) = [];
for p = 1:length(paramNames)
   stimulus.(paramNames{p})(task.trialnum) = stimulus.thistrial.(paramNames{p}).val;
end
% store distractor information
stimulus.distLoc(task.trialnum,:) = stimulus.thistrial.distLoc(1,:);
stimulus.distEcc(task.trialnum,:) = stimulus.thistrial.distLoc(2,:);
stimulus.distSF(task.trialnum,:) = stimulus.thistrial.distractorSF.val;
stimulus.distTilt(task.trialnum,:) = stimulus.thistrial.distractorTilt.val;

% do necessary adjustments if the trial was broken
if stimulus.brokenTrial.trialIdx(task.trialnum)
   % update accuracy and contrast
   stimulus.accuracy(task.trialnum) = nan;
   stimulus.contrast(task.trialnum) = nan;

   % move parameters tested on this trial to the end of the current param order
   stimulus.currentParamOrder(end+1,:) = stimulus.currentParamOrder(stimulus.trialsCompleted+1,:);
   stimulus.currentParamOrder(stimulus.trialsCompleted+1,:) = [];
   
   % add a trial to the end of the block
   task.numTrials = task.numTrials+1;
else
   % if trial was not broken, update the # of trials completed
   stimulus.trialsCompleted = stimulus.trialsCompleted+1;
end


%% Helper functions
function drawFixation(intensity)
global stimulus

% make sure intensity is a 1x3 vector
if length(intensity)==1
   intensity = repmat(intensity,1,3);
end

% draw fixation cross
x = stimulus.stimParams.fixation.x;
y = stimulus.stimParams.fixation.y;
fixSize = stimulus.stimParams.fixation.size;
mglLines2(zeros(1,length(x)),zeros(1,length(y)),x,y,fixSize,intensity);


function taskInstructions
global stimulus

ready = 0;
mglWaitSecs(0.1);
while ~ready
   mglClearScreen

   drawFixation(stimulus.stimParams.fixation.intensity);

   mglTextDraw('Please keep your eyes on the X',[0 -2.5]);
   mglTextDraw('Press any key when ready',[0 -1.5]);

   % draw Gabors of each tested SF
   mglTextDraw('TARGETS',[0 6]);
   maxEcc = 8;
   gaborPos = linspace(-maxEcc,maxEcc,numel(1:2:length(stimulus.taskParams.sfs)));
   sfIdx = 1:2:numel(stimulus.taskParams.sfs);
   for s = 1:numel(1:2:length(stimulus.taskParams.sfs))
      thisSF = stimulus.taskParams.sfs(sfIdx(s));
      gaborSize = stimulus.stimParams.gabor.size;
      gr = mglMakeGrating(gaborSize,gaborSize,thisSF,90,180);
      window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
      gabor = 255*(gr.*window+1)/2;
      target = mglCreateTexture(gabor);
      mglBltTexture(target,[gaborPos(s) 3.5]);
   end
   mglFlush

   % wait for key press
   if any(mglGetKeys)
      ready = 1;
   end
end
