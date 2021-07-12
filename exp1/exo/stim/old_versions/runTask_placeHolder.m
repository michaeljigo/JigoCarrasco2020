% usage:    runTask(subj,eyetracking,prac_maskCheck)
% by:       Michael Jigo
% date:     07/01/18
% purpose:  Run CSF task with the parameters returned by initParams 
%           (see initParams.m for more info)
%
% INPUTS:
% subj            string containing subject identifier
%
% eyetracking     eyetracking on/off (default=1)
%
% prac_maskCheck  practice block (1) or check for masking (2) (default=0) 

function runTask_placeHolder(subj,eyetracking,prac_maskCheck)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
   eyetracking = 1;
end
if ~exist('prac_maskCheck','var')
   prac_maskCheck = 0;
end

%% Initialize parameters for main task
[stimulus.taskParams, stimulus.stimParams, stimulus.stairParams, stimulus.eyeParams] = initParams_placeHolder;
% generate/load staircases
[stimulus.stair, stairInfo] = initStair(subj,stimulus.taskParams,stimulus.stairParams);

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [7 45]; % [z ?]
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if prac_maskCheck
   if prac_maskCheck==1
      myscreen.datadir = ['../data/',subj,'/practice/'];
   elseif prac_maskCheck==2
      myscreen.datadir = ['../data/',subj,'/maskCheck/'];
   end
else
   myscreen.datadir = ['../data/',subj,'/'];
end
% create save directory if undefined
if ~exist(myscreen.datadir,'dir')
   mkdir(myscreen.datadir);
end
% set eyelink parameters
if eyetracking
   load('./eyelinkParams.mat');
   myscreen.eyelinkParams = eyelinkParams;
end
% initialize screen
myscreen = initScreen(myscreen);
% initialize stimulus variable within myscreen
myscreen = initStimulus('stimulus',myscreen);

%% Run task
% set parameters for practice
if prac_maskCheck
   nBlocks = 1;
   if prac_maskCheck==1
      stimulus.taskParams.nTrials = 72;
   elseif prac_maskCheck==2
      % set parameters for quickly checking for masking
      stimulus.taskParams.sfs = 0.75;
      stimulus.taskParams.loc = 1; % [left right] hemifield
      stimulus.taskParams.ecc = [0 14];
      stimulus.stairParams.nTrials = 30;

      % disregard these fields when determining # of trials
      notThese = {'duration' 'tilt' 'getResponse' 'nTrials'};
      stimulus.taskParams.nTrials = prod(structfun(@(x) ...
         length(x),removeFields(stimulus.taskParams,notThese)))*...
         stimulus.stairParams.nTrials;

      % re-initialize staircase
      [stimulus.stair, stairInfo] = initStair(subj,stimulus.taskParams,stimulus.stairParams);
   end
else
   nBlocks = 25; % # of blocks needed to complete a full staircase for each condition
end
stimulus.isprac = prac_maskCheck;

% run blocks
for b = 2:nBlocks
   % set-up eyetracking
   if eyetracking
      myscreen = eyeCalibDisp(myscreen,sprintf('%.0f%% complete. Press SPACEBAR to calibrate or ENTER when ready.',((b-1)/nBlocks)*100));
   else
      mglTextDraw(sprintf('%.0f%% complete. Press ENTER when ready.',((b-1)/nBlocks)*100),[0 0]);
      mglFlush;
      while ~mglGetKeys(37)
         mglWaitSecs(0.1);
      end
   end

   % run task
   csfTask_placeHolder(myscreen);

   % update staircase info
   stairInfo.threshCollected = stairInfo.threshCollected+(1/nBlocks);

   % save staircase
   stair = stimulus.stair;
   save([myscreen.datadir,'stair.mat'],'stair','stairInfo');
end
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;

%% Analyze mask check data
if prac_maskCheck==2
   addpath('../anal/');
   subjCSF_v2(subj,1);
end
