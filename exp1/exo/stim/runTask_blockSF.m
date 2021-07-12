function runTask_blockSF(subj,session,eyetracking)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
   eyetracking = 1;
end
if ~exist('session','var') || isempty(session)
   % check if the blockOrder file has been created
   blockOrderFile = ['../data/',subj,'/blockOrder.mat'];
   if exist(blockOrderFile,'file')
      session = load(blockOrderFile,'sessionCompleted');
      session = session.sessionCompleted+1
   else
      session = 0;
   end
end

%% Initialize parameters for main task
[stimulus.taskParams, stimulus.stimParams, stimulus.stairParams, stimulus.eyeParams] = ...
   initParams_blockSF(session);

if ~session
   % generate/load staircases
   [stimulus.stair, stimulus.stairInfo] = initStair(subj,stimulus.taskParams,stimulus.stairParams);
   stimulus.stairParams = stimulus.stairInfo.stairParams;
end

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [7 45]; % [z ?]
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if ~session
   myscreen.datadir = ['../data/',subj,'/threshold/'];
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
% # of blocks subject will run in each session
if ~session
   nBlocks = 12; % # of blocks needed to get 40 trials/condition
   
   % also create order in which SFs will be presented
   % initialize random number generator
   stream = RandStream('mt19937ar','seed',sum(100*clock));
   RandStream.setDefaultStream(stream);

   % create random order of SF presentation
   blockOrder{1} = stimulus.taskParams.all_sfs(randperm(length(stimulus.taskParams.all_sfs)));
   for i = 2:4
      temp = repmat(stimulus.taskParams.all_sfs,1,3);
      blockOrder{i} = temp(randperm(length(temp)));
   end
   sessionCompleted = 0;
   save(['../data/',subj,'/blockOrder.mat'],'blockOrder','sessionCompleted');
  
  % create block order for the threshold session 
   temp = repmat(stimulus.taskParams.all_sfs,1,2);
   blockOrder = temp(randperm(length(temp)))
else
   % load thresholds estimated from thresholding session
   load([myscreen.datadir,'threshold/threshEstimate.mat']);
   stimulus.thresh = thresh; clear thresh

   % load block order
   load(['../data/',subj,'/blockOrder.mat']);
   
   if session==1
      nBlocks = 6; % These initial 6 blocks will be used to reach 20 blocks/SF (20 blocks/SF will give me 40 trials/condition)
   else
      nBlocks = 18; % 160 trials/block * 18 blocks = 2880 trials * 3 sessions = 8640 trials + 960 trials (from session #1) = 9600 trials
   end
end

% run blocks
for b = 1:nBlocks
   % set-up eyetracking
   if eyetracking
      myscreen = eyeCalibDisp(myscreen,...
         sprintf('%i/%i complete.\n Press SPACEBAR to calibrate or ENTER when ready.',b-1,nBlocks));
   else
      mglTextDraw(sprintf('%i/%i complete.\n Press ENTER when ready.',b-1,nBlocks),[0 0]);
      mglFlush;
      while ~mglGetKeys(37)
         mglWaitSecs(0.1);
      end
   end
   

   % options necessary for CRF experiment
   if session
      % get the SF that will be tested based on blockOrder
      stimulus.taskParams.sfs = blockOrder{session}(b);
      
      % run CRF task
      crfTask_blockSF(myscreen);
   end
   
   
   if ~session
      stimulus.taskParams.sfs = blockOrder(b);
      
      % run staircase task
      estimateThresh_blockSF(myscreen);

      % update staircase info
      stimulus.stairInfo.threshCollected = stimulus.stairInfo.threshCollected+(1/nBlocks);
      stairInfo = stimulus.stairInfo;
   
      % save staircase
      stair = stimulus.stair;
      save([myscreen.datadir,'stair.mat'],'stair','stairInfo');
   end
end
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;

% save the # of sessions subject has completed
if session
   sessionCompleted = sessionCompleted+1;
    save([myscreen.datadir,'blockOrder.mat'],'blockOrder','sessionCompleted');
end
