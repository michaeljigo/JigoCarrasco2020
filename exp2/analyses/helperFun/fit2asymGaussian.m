%% Objective function
function params = fit2asymGaussian(sfs,data,shape)
options = optimoptions(@fmincon,'Algorithm','active-set','Display','none','MaxIter',1e6,'FunctionTolerance',1e-6,'StepTolerance',1e-10,'MaxFunctionEvaluations',1e50);
init = [0 1 1 2 1 0];

if strcmp(shape,'symmetric')
   lb = [-1 0.5 0.5 2 0 0];
   ub = [3 3 3 2 2 0];
elseif strcmp(shape,'uniform')
   lb = [-1 0.5 0.5 10 0 0];
   ub = [3 3 3 10 2 0];
end

fitFun = @(params)objectiveFun(sfs,data,params);
problem = createOptimProblem('fmincon','objective',fitFun,'x0',init,'lb',lb,'ub',ub,'options',options);
ms = MultiStart('FunctionTolerance',1e-10,'XTolerance',1e-6,'Display','off','StartPointsToRun','bounds','UseParallel',0);
[params cost] = run(ms,problem,10);


function cost = objectiveFun(sfs,data,params)

params(3) = params(2);
model = asymGaussian(sfs,params)';
cost = sum((data-model).^2);
