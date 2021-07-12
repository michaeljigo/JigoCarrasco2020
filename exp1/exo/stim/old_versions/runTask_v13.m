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
% prac_maskCheck  practice block (1) (default=0) 

function runTask_v13(subj,eyetracking,prac_maskCheck)
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
[stimulus.taskParams, stimulus.stimParams, stimulus.stairParams, stimulus.eyeParams] = ...
   initParams_v13;
% generate/load staircases
[stimulus.stair, stimulus.stairInfo] = initStair_v13(subj,stimulus.taskParams,stimulus.stairParams);
stimulus.stairParams = stimulus.stairInfo.stairParams;

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [7 45]; % [z ?]
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if prac_maskCheck
   myscreen.datadir = ['../data/',subj,'/practice/'];
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
   stimulus.taskParams.nTrials = 72;
else
   nBlocks = 20; % # of blocks needed to complete a full staircase for each condition
end
stimulus.isprac = prac_maskCheck;

% run blocks
for b = 1:nBlocks
   % set-up eyetracking
   if eyetracking
      myscreen = eyeCalibDisp(myscreen,sprintf('%i/%i complete.\n Press SPACEBAR to calibrate or ENTER when ready.',b-1,nBlocks));
   else
      mglTextDraw(sprintf('%i/%i complete.\n Press ENTER when ready.',b-1,nBlocks),[0 0]);
      mglFlush;
      while ~mglGetKeys(37)
         mglWaitSecs(0.1);
      end
   end

   % run task
   csfTask_v13(myscreen);

   % update staircase info
   stimulus.stairInfo.threshCollected = stimulus.stairInfo.threshCollected+(1/nBlocks);
   stairInfo = stimulus.stairInfo;
   stairInfo.stairParams.stairRep = stimulus.stairInfo.stairParams.stairRep;

   % save staircase
   stair = stimulus.stair;
   save([myscreen.datadir,'stair.mat'],'stair','stairInfo');
end
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;
