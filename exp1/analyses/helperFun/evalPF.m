% usage:    F = evalPF(pf,x,params)
% by:       Michael Jigo
% date:     05/04/18
% purpose:  Evaluate the desired psychometric function (PF) at various stimulus levels
%           and with a particular set of parameters.
%
% INPUTS:
% pf        String specifying the PF to evaluate. The function supports:
%           'weibull'
%           'gumbell' or 'log weibull'
%           'probit' or 'cumulative normal' or 'log normal'
%           'logit' or 'logistic'
%           'quick'
%           'log_quick'
% 
% x         Stimulus levels to be evaluated.
%
% params    nx4 matrix where each row contains PF parameters:
%                       [alpha beta gamma lambda]
%
%           For log-based functions (log weibull and log normal) alpha and beta
%           parameters must be log-transformed before being inputted.
%           
%
% OUTPUT:
% F         contains the PF evaluated at each value of x.
%           If params is a nx4 matrix, F will have n rows and length(x) columns.

function F = evalPF(pf,x,params)
if size(params,1)>1
   x = repmat(x,size(params,1),1);
end

%% Parse parameters
a = params(:,1); % alpha
b = params(:,2); % beta
g = params(:,3); % gamma
l = params(:,4); % lambda

%% Evaluate PF
switch lower(pf)
   case 'weibull'
      F = g+(1-g-l).*(1-exp(-(x./a).^b));
   case {'gumbel' 'log weibull'}
      % NOTE: CAN'T SEEM TO GET THE RIGHT PARAMETER RANGE TO MAKE THIS WORK
      F = g+(1-g-l).*(1-exp(-10.^(b.*(x-a))));
   case {'probit' 'cumulative normal'}
      F = g+(1-g-l).*normcdf(x,repmat(a,1,size(x,2)),repmat((1/b)',1,size(x,2)));
   case {'log_normal'}
      x = log10(x); a = log10(a); b = log10(b);
      F = g+(1-g-l).*normcdf(x,repmat(a,1,size(x,2)),repmat((1/b)',1,size(x,2)));
   case {'logit' 'logistic'}
      F = g+(1-g-l).*(1./(1+exp(-b.*(x-a))));
   case {'quick'}
      F = g+(1-g-l).*(1-2.^(-(x./a).^b));
   case 'log_quick'
      F = g+(1-g-l).*(1-2.^(-10.^(b*(x-a))));
   case 'arbweibull'
      if length(params)~=5
         error('5th parameter must be the target performance level');
      end
      base = 1./(1-((params(:,5)-g)./(1-g-l)));
      F = g+(1-g-l).*(1-base.^(-1*(x./a).^b));
   case 'nakarushton'
      F = g+l.*(x.^b./(x.^b+a.^b));
end
