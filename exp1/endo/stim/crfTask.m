% Purpose: Run Method Of Constant Stimuli (MOCS) experiment

function crfTask(myscreen)
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


%% Display task instructions
taskInstructions


%% Run tasks
[task{1}, myscreen] = initTask(task{1},myscreen,@startSegmentCallback, ...
    @screenUpdateCallback,@trialResponseCallback,@startTrialCallback,...
    @endTrialCallback);
tnum = 1;
while (tnum<=length(task)) %&& ~myscreen.userHitEsc
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


% get threshold estimate for current condition
thisTrial = stimulus.thistrial;
thresh = stimulus.thresh(thisTrial.sfs.idx,thisTrial.ecc.idx);

% now determine which spacing to use (I'm assuming a minimum spacing of 0.15 log units)
if thresh+0.225<0
    spacing = [-0.225 -0.075 0.075 0.225];
else
    spacing = [-0.6 -0.45 -0.3 -0.15];
end
allContrasts = [0 thresh+spacing];
c = 10^allContrasts(thisTrial.contrast.val);

% store contrast level
stimulus.contrast(task.trialnum) = c;


% generate Gabor stimulus for this trial
gaborSize = stimulus.stimParams.gabor.size;
gr = c*mglMakeGrating(gaborSize,gaborSize,thisTrial.sfs.val,...
    90-(stimulus.stimParams.gabor.tiltMagnitude*thisTrial.tilt.val),180);
window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
gabor = 255*(gr.*window+1)/2;
stimulus.target = mglCreateTexture(gabor);



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
                    
                    % store eye position and use average as reference when fixation time
                    % window is exceeded
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
            % valid cue -- number
            cueParams = stimulus.stimParams.endoCue;
            cueNum = num2str(find(stimulus.thistrial.ecc.val==stimulus.taskParams.ecc)-1);
            mglTextDraw(cueNum,[0 cueParams.y(1)]);
            
            if str2double(cueNum)>0
                % valid cue -- line
                cueParams.x = cueParams.x*stimulus.thistrial.loc.val;
                mglLines2(cueParams.x(1),cueParams.y(1),cueParams.x(2),cueParams.y(2),...
                    cueParams.size,cueParams.intensity);
            end
        else
            % neutral cue -- lines
            cueParams = stimulus.stimParams.endoCue;
            mglLines2(cueParams.x(1),cueParams.y(1),cueParams.x(2),cueParams.y(2),...
                cueParams.size,cueParams.intensity);
            mglLines2(-cueParams.x(1),cueParams.y(1),-cueParams.x(2),cueParams.y(2),...
                cueParams.size,cueParams.intensity);
            
            % valid cue -- number
            cueNum = 'N';
            mglTextDraw(cueNum,[0 cueParams.y(1)]);
        end
    case 5 % stimulus
        mglBltTexture(stimulus.target,[stimulus.thistrial.ecc.val*stimulus.thistrial.loc.val 0]);
        drawFixation(stimulus.stimParams.fixation.intensity);
    case 7 % response cue
        cueLoc = repmat(stimulus.thistrial.ecc.val*stimulus.thistrial.loc.val,1,2);
        elevation = stimulus.stimParams.cue.elevation;
        mglFillOval(cueLoc,elevation,repmat(stimulus.stimParams.cue.radius,1,2),...
            stimulus.stimParams.cue.color);
        
%         % valid cue -- number
%         cueParams = stimulus.stimParams.endoCue;
%         cueNum = num2str(find(stimulus.thistrial.ecc.val==stimulus.taskParams.ecc)-1);
%         mglTextDraw(cueNum,[0 cueParams.y(1)]);
%         
%         if str2double(cueNum)>0
%             % valid cue -- line
%             cueParams.x = cueParams.x*stimulus.thistrial.loc.val;
%             mglLines2(cueParams.x(1),cueParams.y(1),cueParams.x(2),cueParams.y(2),...
%                 cueParams.size,cueParams.intensity);
%         end
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
    mglTextDraw('Press any key when ready',[0 -3.5]);
    
    % draw Gabors of each tested SF
    mglTextDraw('TARGETS',[0 10]);
    maxEcc = max(stimulus.taskParams.ecc);
    gaborPos = linspace(-maxEcc,maxEcc,length(stimulus.taskParams.sfs));
    for s = 1:length(stimulus.taskParams.sfs)
        thisSF = stimulus.taskParams.sfs(s);
        gaborSize = stimulus.stimParams.gabor.size;
        gr = mglMakeGrating(gaborSize,gaborSize,thisSF,90,180);
        window = raisedCosWindow_mgl(gaborSize,gaborSize,gaborSize,gaborSize);
        gabor = 255*(gr.*window+1)/2;
        target = mglCreateTexture(gabor);
        mglBltTexture(target,[gaborPos(s),7]);
    end
    
    % draw numbers at the desired eccentricities
    nonZeroEcc = setdiff(stimulus.taskParams.ecc,0);
    for l = 1:length(stimulus.taskParams.loc)
        for e = 1:length(nonZeroEcc)
            mglTextDraw(num2str(find(nonZeroEcc(e)==nonZeroEcc)),[nonZeroEcc(e)*stimulus.taskParams.loc(l) 0]);
        end
    end
    % draw fovea cue
    mglTextDraw('0',[0 0]);
    mglFlush
    
    % wait for key press
    if any(mglGetKeys)
        ready = 1;
    end
end

