%% UPDATE HELP LATER!!!!!!!!!!!!!!!!
%
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

function runTask(subj,session,eyetracking,distractorType)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
   eyetracking = 1;
end

if ~exist('distractorType','var')
   distractorType = 0; % 0=homogenous; 1=heterogenous
end
if distractorType
    distString = 'hetero';
else
    distString = 'homo';
end
stimulus.distractorType = distractorType;

%% Initialize parameters for main task
[stimulus.taskParams, stimulus.stimParams, stimulus.eyeParams, stimulus.stairParams] = initParams(session);
stimulus.stair = initStair(subj,stimulus,session);

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [124 125]; % [<- ->] arrow keys
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if session
    myscreen.datadir = ['../data/',subj,'/homo/tmp/'];
    myscreen.maindir = ['../data/',subj,'/homo/'];
else
    myscreen.datadir = ['../data/',subj,'/threshold/'];
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

% change mglScreenParams file to set correct distance for experiment
tmp = load('~/.mglScreenParams.mat');
possibleDisplays = cellfun(@(x) x.displayName,tmp.screenParams,'UniformOutput',0);
currentDisplay = ismember(possibleDisplays,myscreen.displayName);
tmp.screenParams{currentDisplay}.displayDistance = 115;
screenParams = tmp.screenParams;
save('~/.mglScreenParams.mat','screenParams'); clear screenParams tmp

% initialize screen
myscreen = initScreen(myscreen);

% initialize stimulus variable within myscreen
myscreen = initStimulus('stimulus',myscreen);

% load thresholds estimated from thresholding session
if session
    load(['../data/',subj,'/threshold/threshEstimate.mat']);
    stimulus.thresh = thresh; clear thresh
end

% change size of text
mglTextSet('Helvetica',38,[1 1 1]);

%% Run blocks
fprintf('nBlocks = %i\n',stimulus.taskParams.nBlocks);
for b = 1:stimulus.taskParams.nBlocks
   % set-up eyetracking
   if eyetracking
      myscreen = eyeCalibDisp(myscreen,...
         sprintf('%i/%i complete.\n Press ENTER when ready.',b-1,stimulus.taskParams.nBlocks));
   else
      mglTextDraw(sprintf('%i/%i complete.\n Press ENTER when ready.',b-1,stimulus.taskParams.nBlocks),[0 0]);
      mglFlush;
      while ~mglGetKeys(37)
         mglWaitSecs(0.1);
      end
   end

   if session
      % reset random number generator when the order of condition presentation needs to be re-shuffled
      stream = RandStream('mt19937ar','seed',sum(100*clock));
      RandStream.setDefaultStream(stream);
   
      % create fake parameter variable
      stimulus.taskParams.dummyParam = 1:5e2;

      % load file specifying # of trials subject has completed
      if exist([myscreen.maindir,'trialsCompleted_distract.mat'],'file')
         load([myscreen.maindir,'trialsCompleted_distract.mat']);
         stimulus.trialsCompleted = trialsCompleted; clear trialsCompleted;
         stimulus.currentParamOrder = currentParamOrder; clear currentParamOrder;
         stimulus.allTrialsCompleted = allTrialsCompleted; clear allTrialsCompleted
      else
         stimulus.trialsCompleted = 0;
         stimulus.allTrialsCompleted = 0;
      end
   
      % run CRF task
      distractTask(myscreen);
   
      % save the # of trials that were completed in the current block and the current parameter order
      allTrialsCompleted = stimulus.allTrialsCompleted;
      trialsCompleted = stimulus.trialsCompleted;
      currentParamOrder = stimulus.currentParamOrder;
      save([myscreen.maindir,'trialsCompleted_distract.mat'],'trialsCompleted','currentParamOrder','allTrialsCompleted')

      % give subjects a mandatory minute break at the halfway mark of the session...during this time update thresholds
      if b==ceil(stimulus.taskParams.nBlocks/2)
         % start break timer
         breakTime = mglGetSecs;
         % display message to subject
         mglClearScreen;
         mglTextDraw('Take a break. Stretch. Rest your eyes.',[0 0]);
         mglTextDraw('You can continue the experiment in 1 minute',[0 -1]);
         mglFlush;

         % do analysis
         addpath('../anal');
         pCorr_distractTask(subj,1);

         % move the files from the temporary folder to the main folder with
         % all blocks
         movefile([myscreen.datadir,'*.*'],myscreen.maindir);
         
         
         % allow subject to continue after desired time
         while mglGetSecs(breakTime)<=60
            % don't do anything
         end
         mglClearScreen; mglFlush; mglClearScreen; mglFlush;
      end
   else
      % thresholding session
      threshSess(myscreen);
      
      if b==ceil(stimulus.taskParams.nBlocks/2)
         % start break timer
         breakTime = mglGetSecs;
         % display message to subject
         mglClearScreen;
         mglTextDraw('Take a break. Stretch. Rest your eyes.',[0 0]);
         mglTextDraw('You can continue the experiment in 1 minute',[0 -1]);
         mglFlush;
         
         % allow subject to continue after desired time
         while mglGetSecs(breakTime)<=60
            % don't do anything
         end
         mglClearScreen; mglFlush; mglClearScreen; mglFlush;
      end
   end
end
if session
    % update thresholds at the end of the session as well
    pCorr_distractTask(subj,1);
    
    
    % move the files from the temporary folder to the main folder with
    % all blocks
    movefile([myscreen.datadir,'*.*'],myscreen.maindir);
end


mglClearScreen;
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;
