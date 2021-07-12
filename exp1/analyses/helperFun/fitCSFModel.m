% Purpose:  Fit contrast sensitivity function to sensitivity estimates across several SFs and eccentricities. 
%           Currently, only the double-exponential function is supported.

function [params cost] = fitCSFModel(currentCS,csf,varargin)

%% Parse optional inputs
optionalIn = {'dispFig'};
optionalVal = {0};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);


%% Perform fit
% set random starting point within bounds
switch csf.name
   case 'dexp'
      init = repmat([1 2 200],size(csf.bnd,2),1);
   case 'apf'
      init = repmat(log10([200 4 1e-2 1e-2]),size(csf.bnd,2),1);
   case 'asymGaus'
      init = repmat([2 3 3 200],size(csf.bnd,2),1);
   otherwise
      error('%s not supported.',csf.name);
end

% set up solver
csfFun = @(params)fit_CSF(currentCS,params,csf);
problem = createOptimProblem('fmincon','objective',csfFun,'x0',init,'lb',squeeze(csf.bnd(1,:,:)),'ub',squeeze(csf.bnd(2,:,:)),'options',csf.options);
ms = MultiStart('FunctionTolerance',1e-3,'XTolerance',1e-3,'Display','off','StartPointsToRun','bounds','UseParallel',0);
[params cost] = run(ms,problem,1);%csf.nStartPoints);

% reformat parameters to a cue x eccentricity x parameter matrix
for e = 1:numel(csf.eccVal)
   for c = 1:numel(csf.cueVal)
      newParams(c,e,:) = params(ismember(csf.condCombos,[e c],'rows'),:);
   end
end
params = newParams;

%% Display fit
if opt.dispFig
   subplotN = 0;
   colors = [0 0 0; 25 87 148]./255;
   fitSF = logspace(log10(0.45),log10(24),1e3);

   figure('Name','Contrast Sensitivity Function')
   for e = 1:numel(csf.eccVal)
      subplotN = subplotN+1;
      for c = 1:numel(csf.cueVal)
         subplot(2,2,subplotN)

         % plot raw data
         loglog(csf.sfVal,squeeze(currentCS(c,:,e)),'.','MarkerSize',20,'Color',colors(c,:)); hold on

         % plot fit
         switch csf.name
            case 'asymGaus'
               p = squeeze(params(c,e,:)); p = [p(1) p(2) p(3) 2 p(4) 1];
               peakSF = 2.^params(c,e,1); peakCS = params(c,e,4);
               fitCS = evalCSF(csf.name,log2(fitSF),p);
            otherwise
               p = squeeze(params(c,e,:));
               peakSF = p(2); peakCS = p(3);
               fitCS = evalCSF(csf.name,fitSF,p);
         end
         loglog(fitSF,fitCS,'-','Linewidth',3,'Color',colors(c,:));

         % plot vertical line @ peak SF
         line([peakSF peakSF],[1 peakCS],'Color',colors(c,:),'Linewidth',2);
      end
      % pretty up figure
      set(gca,'XLim',[0.4 20],'YLim',[1 250],'box','off','TickDir','out');
      xlabel('Spatial frequency (cpd)'); ylabel('Contrast sensitivity');
      title(sprintf('%i deg',csf.eccVal(e)));
   end
end



%% Objective function
function cost = fit_CSF(cs,params,opt)

% loop through each eccentricity and cue to extract their respective parameters
for e = 1:size(cs,3)
   for c = 1:size(cs,1)
      % create vector indicating the current condition combination
      condCombo = [e c];
     
      % find which row in opt.condCombos holds this condition combination 
      condCombo = ismember(opt.condCombos,condCombo,'rows');

      % evaluate model with given parameters
      switch opt.name
         case 'asymGaus'
            p = params(condCombo,:); newP = [p(1) p(2) p(3) 2 p(4) 1];
            tmp = evalCSF(opt.name,log2(opt.sfVal),newP);
         otherwise
            tmp = evalCSF(opt.name,opt.sfVal,params(condCombo,:));
      end
      model(c,:,e) = tmp;
   end
end

% log-transform values to give roughly equal weighting to each SF
model = log(model(:));
cs = log(cs(:));

% sse
cost = sum((model(:)-cs(:)).^2);
