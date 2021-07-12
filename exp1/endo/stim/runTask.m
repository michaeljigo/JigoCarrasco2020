% UPDATE HELP LATER!!!!!!!!!!!!!!!!
%
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

function runTask(subj,session,eyetracking)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
    eyetracking = 1;
end
if ~exist('session','var')
    session = input('Threshold (0) or Main (1) session? \n');
end

%% Initialize parameters for main task
[stimulus.taskParams, stimulus.stimParams, stimulus.stairParams, stimulus.eyeParams] = ...
    initParams(session);

if ismember(subj,{'LH' 'AS' 'SX'})
    stimulus.eyeParams.fixWindow = 1.5;
end

if ~session
    % generate/load staircases
    [stimulus.stair, stimulus.stairInfo] = initStair(subj,stimulus.taskParams,stimulus.stairParams);
    stimulus.stairParams = stimulus.stairInfo.stairParams;
end

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [124 125]; % [<- ->] arrow keys
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

% store session flag
stimulus.session = session;

%% Run task
% # of blocks subject will run in each session
if ~session
     nBlocks = 10; % # of blocks needed to complete a full staircase for each condition
    %nBlocks = 5;
else
    nBlocks = 15;
    
    % load thresholds estimated from thresholding session
    load([myscreen.datadir,'threshold/threshEstimate.mat']);
    stimulus.thresh = thresh; clear thresh
end


% run blocks
fprintf('nBlocks = %i\n',nBlocks);

for b = 1:nBlocks
    % set-up eyetracking
    if eyetracking
              myscreen = eyeCalibDisp(myscreen,...
                 sprintf('%i/%i complete.\n Press SPACEBAR to calibrate or ENTER when ready.',b-1,nBlocks));
%         myscreen = eyeCalibDisp(myscreen,...
%             sprintf('When ready, press SPACEBAR to calibrate or ENTER to start.'));
    else
        %       mglTextDraw(sprintf('%i/%i complete.\n Press ENTER when
        %       ready.',b-1,nBlocks),[0 0]);
        mglTextDraw(sprintf('When ready, press ENTER.'),[0 0]);
        mglFlush;
        while ~mglGetKeys(37)
            mglWaitSecs(0.1);
        end
    end
    
    
    % options necessary for CRF experiment
    if session
        % reset random number generator in the event parameter combination
        % order needs to be re-shuffled
        stream = RandStream('mt19937ar','seed',sum(100*clock));
        RandStream.setDefaultStream(stream);
        
        % create fake parameter variable
        stimulus.taskParams.dummyParam = 1:5e2;
        
        % load file specifying # of trials subject has completed
        if exist([myscreen.datadir,'trialsCompleted.mat'],'file')
            load([myscreen.datadir,'trialsCompleted.mat']);
            stimulus.trialsCompleted = trialsCompleted; clear trialsCompleted;
            stimulus.currentParamOrder = currentParamOrder; clear currentParamOrder;
            stimulus.allTrialsCompleted = allTrialsCompleted; clear allTrialsCompleted
        else
            stimulus.trialsCompleted = 0;
            stimulus.allTrialsCompleted = 0;
        end
        
        % run CRF task
        crfTask(myscreen);
        
        % save the # of trials that were completed in the current block and the current parameter order
        allTrialsCompleted = stimulus.allTrialsCompleted;
        trialsCompleted = stimulus.trialsCompleted;
        currentParamOrder = stimulus.currentParamOrder;
        save([myscreen.datadir,'trialsCompleted.mat'],'trialsCompleted','currentParamOrder','allTrialsCompleted')
    end
    
    
    if ~session
        % run staircase task
        estimateThresh(myscreen);
        
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
