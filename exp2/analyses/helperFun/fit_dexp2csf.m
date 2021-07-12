% Purpose:  This function will fit the double-exponential function to contrast sensivitity at various spatial frequencies.

function csfParams = fit_dexp2csf(sfVal,cs)

% set up solver
options = optimoptions(@fmincon,'Algorithm','interior-point','Display','none','MaxIter',1e5,...
   'FunctionTolerance',1e-6,'StepTolerance',1e-50,'MaxFunctionEvaluations',1e50);
lb = [0 0.5 1];
ub = [1e2 8 3e2];
init = rand(1,3).*(ub-lb)+lb;

for e = 1:size(cs,2)
   thisCS = cs(:,e);
   fitFun = @(params)fitDEXP(sfVal,thisCS,params);
   problem = createOptimProblem('fmincon','objective',fitFun,'x0',init,'lb',lb,'ub',ub,'options',options);
   ms = MultiStart('FunctionTolerance',1e-6,'XTolerance',1e-3,'Display','off','StartPointsToRun','bounds','UseParallel',0);
   csfParams(e,:) = run(ms,problem,20);
end


%% objective function for fitting double-exponential function
function cost = fitDEXP(sfVal,thresh,p)

if size(thresh,1)>1
   thresh = thresh';
end

% set lower bound to contrast sensitivity values
thresh(thresh<=1) = nan;

% get dexp model output
model = evalCSF('dexp',sfVal,p);

% compute cost
if ~isequal(size(model),size(thresh))
end
%cost = sqrt(nanmean((log(model)-log(thresh)).^2));
cost = nansum(((model)-(thresh)).^2);
%cost = nansum((log(model)-log(thresh)).^2);
