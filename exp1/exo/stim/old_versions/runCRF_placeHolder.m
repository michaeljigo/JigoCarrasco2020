% run the psychophysical task
function runCRF_placeHolder(subj,eyetracking,practice)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
   eyetracking = 1;
end
if ~exist('practice','var')
   practice = 0;
end

%% Initialize parameters
[stimulus.taskParams, stimulus.stimParams, stimulus.eyeParams] = crfParams_placeHolder;

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [7 45]; % [z ?]
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if practice
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
if practice
   nBlocks = 1;
   stimulus.taskParams.nTrials = 30;
else
   nBlocks = 6; % # of blocks needed to complete a full staircase for each condition
end

for b = 1:nBlocks
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
   crfTask_placeHolder(myscreen);
end
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;

