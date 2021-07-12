% Run the 2AFC orientation discrimination task

function csfTask_v13(myscreen)
global stimulus

%% Set up task variable for MGL
task{1}.seglen = stimulus.taskParams.duration;
task{1}.getResponse = stimulus.taskParams.getResponse;
task{1}.parameter = removeFields(stimulus.taskParams,{'duration' 'getResponse' 'nTrials' 'tilt'});
task{1}.random = 1;
task{1}.numTrials = stimulus.taskParams.nTrials;
task{1}.waitForBacktick = 0;

%% Variable for broken fixations
stimulus.brokenTrial = [];
stimulus.brokenTrial.orgNumTrials = task{1}.numTrials;
stimulus.brokenTrial.trialIdx = [];

%% Variables to store accuracy and tilt
stimulus.accuracy = [];
stimulus.tilt = [];

%% Display task instructions
taskInstructions

%% Run tasks
[task{1}, myscreen] = initTask(task{1},myscreen,@startSegmentCallback, ...
   @screenUpdateCallback,@trialResponseCallback,@startTrialCallback,...
   @endTrialCallback);
tnum = 1;
while (tnum<=length(task)) && ~myscreen.userHitEsc
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

% initialize index for whether the trial is broken or not
stimulus.brokenTrial.trialIdx(task.trialnum) = 0;
% re-initialize break counter
stimulus.eyeParams.breakCounter = 0;

% determine stimulus parameters for this trial
[~,thisCue] = ismember(task.thistrial.cues,task.parameter.cues);
[~,thisSF] = ismember(task.thistrial.sfs,task.parameter.sfs);
[~,thisLoc] = ismember(task.thistrial.loc,task.parameter.loc);
[~,thisEcc] = ismember(task.thistrial.ecc,task.parameter.ecc);

% determine which staricase to use
whichRep = arrayfun(@(x) length(x.allLevels)==stimulus.stairParams.nTrials,...
    squeeze(stimulus.stair(:,:,:,:,end)));
if all(whichRep(:)==1)
    stimulus.stairInfo.stairParams.stairRep = stimulus.stairInfo.stairParams.stairRep+1;
end
whichRep = stimulus.stairInfo.stairParams.stairRep;
if whichRep>size(stimulus.stair,5)
    newStair = initStair_v13(myscreen.subj,stimulus.taskParams,stimulus.stairInfo.stairParams,1);
    stimulus.stair(:,:,:,:,end+1) = newStair;
end
thisStair = stimulus.stair(thisCue,thisSF,thisLoc,thisEcc,whichRep);

% transform contrast back into linear units
c = 10^thisStair.currentLevel;

% save index for staircase
stimulus.currStair = [thisCue thisSF thisLoc thisEcc whichRep];

% adjust contrast if this is a catch trial
if ~isnan(thisStair.boundTrials(length(thisStair.allLevels)+1))
   c = 10^(thisStair.boundTrials(length(thisStair.allLevels)+1));
end

% present high/med/low contrast depending on trial #
if stimulus.isprac==1
   contrastBlock = task.numTrials/3;
   if task.trialnum<=contrastBlock
      c = 1;
   elseif task.trialnum>contrastBlock && task.trialnum<=contrastBlock*2
      c = 0.5;
   else
      c = 0.1;
   end
end

% select tilt
stimulus.currentTilt = thisStair.tilts(length(thisStair.allLevels)+1); % -1=CCW; 1=CW

% select spatial frequency based on current eccentricity
currentSF = stimulus.stimParams.eccSF(thisEcc,thisSF);

% generate Gabor stimulus for this trial
gaborSize = stimulus.stimParams.gabor.size;
gr = c*mglMakeGrating(gaborSize,gaborSize,currentSF,90-...
   (stimulus.taskParams.tilt*stimulus.currentTilt),180);
window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
gabor = 255*(gr.*window+1)/2;
stimulus.target = mglCreateTexture(gabor);

% generate circular cue
disc = filledDisc(stimulus.stimParams.cue.radius*2,stimulus.stimParams.cue.radius,...
   unique(myscreen.background),unique(stimulus.stimParams.cue.color));
winSize = stimulus.stimParams.cue.radius*2;
window = raisedCosWindow_mgl(winSize,winSize,winSize,winSize);
disc = 255*(disc.*window+1)/2;
stimulus.cue = mglCreateTexture(disc);

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
            mglClearScreen; drawFixation; mglFlush
            mglClearScreen; drawFixation; mglFlush
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

% check if responses were made in time
if task.thistrial.thisseg==8 && ~task.thistrial.gotResponse
   % display message to respond in time
   mglClearScreen; drawFixation;
   mglTextDraw('Please respond in time',[0 0]); mglFlush;
   mglClearScreen; drawFixation;
   mglTextDraw('Please respond in time',[0 0]); mglFlush;

   % re-do the trial at end of block
   stimulus.brokenTrial.trialIdx(task.trialnum) = 1;
   mglWaitSecs(0.5);
   task = jumpSegment(task);
elseif task.thistrial.gotResponse
   task = jumpSegment(task);
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

% fixation
drawFixation

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
               if mglGetSecs(stimulus.eyeParams.waitTime)>=...
                  stimulus.eyeParams.recalibWaitTime
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
               % store eye position and use average as reference when fixation time 
               % window is exceeded
               while goodFix
                  fixTime = mglGetSecs(fixStart);
                  stimulus.eyeParams.fixPos = [stimulus.eyeParams.fixPos eyePos];
                  if fixTime>=stimulus.eyeParams.fixTime
                     stimulus.eyeParams.fixRef = nanmean(stimulus.eyeParams.fixPos,1);

                     % remove text, give a short pause, then continue with experiment
                     mglClearScreen; drawFixation;
                     mglFlush; mglClearScreen; drawFixation; mglFlush;
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
      if task.thistrial.cues
         % valid cue
         % choose correct cue size for eccentricity
         cueLoc = repmat(task.thistrial.ecc*task.thistrial.loc,1,2);
         elevation = stimulus.stimParams.cue.elevation;
         mglBltTexture(repmat(stimulus.cue,1,length(cueLoc)),...
            [cueLoc' elevation']);
      else
         % neutral cue
         % display all cues
         placeX = unique([stimulus.taskParams.ecc*stimulus.taskParams.loc(1) ...
            stimulus.taskParams.ecc*stimulus.taskParams.loc(2)]);
         elevation = repmat(stimulus.stimParams.cue.elevation,length(placeX),1);
         mglBltTexture(repmat(stimulus.cue,1,length(placeX)),...
            [placeX' elevation(:,1)]);
         mglBltTexture(repmat(stimulus.cue,1,length(placeX)),...
            [placeX' elevation(:,2)]);
      end
   case 5 % stimulus
      mglBltTexture(stimulus.target,[task.thistrial.ecc*task.thistrial.loc 0]);
      drawFixation;
   case 7 % response cue
      % choose correct cue size for eccentricity
      cueLoc = repmat(task.thistrial.ecc*task.thistrial.loc,1,2);
      elevation = stimulus.stimParams.cue.elevation;
      mglBltTexture(repmat(stimulus.cue,1,length(cueLoc)),...
         [cueLoc' elevation']);
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
      mglClearScreen; drawFixation;
      mglTextDraw('Do not move your eyes from the X',[0 0]);
      mglFlush; mglClearScreen; drawFixation;
      mglTextDraw('Do not move your eyes from the X',[0 0]); mglFlush;
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
   if resp==1 && stimulus.currentTilt==-1
      correct = 1; % CCW tilt, CCW response
   elseif resp==2 && stimulus.currentTilt==1
      correct = 1; % CW tilt, CW response
   end
   
   % store accuracy & tilts
   stimulus.accuracy(task.trialnum) = correct;
   stimulus.tilt(task.trialnum) = stimulus.currentTilt;

   % update staircase
   idx = stimulus.currStair;
   thisStair = stimulus.stair(idx(1),idx(2),idx(3),idx(4),idx(5));
   stimulus.stair(idx(1),idx(2),idx(3),idx(4),idx(5)) = nDown1Up(thisStair,correct);

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


if stimulus.brokenTrial.trialIdx(task.trialnum)
   % update accuracy and tilt
   stimulus.accuracy(task.trialnum) = nan;
   stimulus.tilt(task.trialnum) = nan;

   % keep track of the parameters on this trial and then move on to the next trial
   parameters = fieldnames(task.block(task.blocknum).parameter);
   for p = 1:length(parameters)
      if ~isfield(stimulus.brokenTrial,parameters{p})
         stimulus.brokenTrial.(parameters{p}) = [];
      end
      stimulus.brokenTrial.(parameters{p})(end+1) = ...
         task.block(task.blocknum).parameter.(parameters{p})(task.blockTrialnum);
   end

   % add a trial to the end of the block
   task.numTrials = task.numTrials+1;
end

% if we've reached the end of the original number of trials, start presenting trial
% that need to be re-done
if task.trialnum>=stimulus.brokenTrial.orgNumTrials
   parameters = fieldnames(task.block(task.blocknum).parameter);

   % if just done with the original trials, then update the block info to show a
   % division between original and re-done trials
   if task.trialnum==stimulus.brokenTrial.orgNumTrials
      task.block(task.blocknum).trialn = task.blockTrialnum;

      % make a new block for the re-done trials
      if isfield(stimulus.brokenTrial,(parameters{1}))
         task.blocknum = task.blocknum+1;
         task.block(task.blocknum).trialn = inf;
         task.blockTrialnum = 0;
      end
   end

   % update block field to reflect trials that will be re-done
   if task.block(task.blocknum).trialn==inf && ~isempty(stimulus.brokenTrial.(parameters{1}))
      for p = 1:length(parameters)
         % replace block field with parameters of the trial that needs to be re-done
         if ~isfield(task.block(task.blocknum).parameter,parameters{p})
            task.block(task.blocknum).parameter.(parameters{p}) = [];
         end
         task.block(task.blocknum).parameter.(parameters{p}) = ...
            [task.block(task.blocknum).parameter.(parameters{p}) ...
            stimulus.brokenTrial.(parameters{p})];

         % clear that trial, showing that it has been re-done
         stimulus.brokenTrial.(parameters{p}) = [];
      end
   end
end


function drawFixation
global stimulus

% draw fixation cross
x = stimulus.stimParams.fixation.x;
y = stimulus.stimParams.fixation.y;
fixSize = stimulus.stimParams.fixation.size;
mglLines2(zeros(1,length(x)),zeros(1,length(y)),x,y,fixSize,...
   stimulus.stimParams.fixation.color);


function taskInstructions

ready = 0;
mglWaitSecs(0.1);
while ~ready
   mglClearScreen
   
   drawFixation
   
   mglTextDraw('TILTS',[0 3.5]);
   mglTextDraw('z = left   ? = right',[0 2.5]);
   mglTextDraw('Please keep your eyes on the X',[0 -2.5]);
   mglTextDraw('Press any key when ready',[0 -3.5]);
   
   % draw Gabors of each tested SF
%    mglTextDraw('TARGETS',[0 10]);
%    gaborPos = linspace(-14,14,length(stimulus.taskParams.sfs));
%    for s = 1:length(stimulus.taskParams.sfs)
%       thisSF = stimulus.stimParams.eccSF(1,s);
%       gaborSize = stimulus.stimParams.gabor.size;
%       gr = mglMakeGrating(gaborSize,gaborSize,thisSF,90,180);
%       window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
%       gabor = 255*(gr.*window+1)/2;
%       target = mglCreateTexture(gabor);
%       mglBltTexture(target,[gaborPos(s),7]);
%    end
   mglFlush

   % wait for key press
   if any(mglGetKeys)
      ready = 1;
   end
end
