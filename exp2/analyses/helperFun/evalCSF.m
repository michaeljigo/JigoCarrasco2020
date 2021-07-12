% usage:    contrastSensitivity = evalCSF(model,sfs,params)
% by:       Michael Jigo
% date:     07/08/18
% purpose:  Evaluate a contrast senstivity function (CSF) model given the inputted
%           spatial frequencies and parameters.
%
% INPUTS:
% model        string specifying which model to evaluate; can input the output of 
%              fitCSF script to use those parameters
%  'emg'       exponential minus gaussian
%  'hmg'       hyperbolic secant minus gaussian
%  'hpmg'      hyperbolic secant raised to power minus gaussian
%  'ms'        Mannos & Sakrison, 1974
%  'yqm'       Yang, Qi, & Makous, 1995
%  'dexp'      double exponential (following Rohaly & Owsley, 1993; Equation 3)
%  'apf'       asymmetric parabolic function (Chung & Legge, 2016)
%  'rgaus'     raised Gaussian
%
% sfs          vector of tested spatial frequencies
%
% params       vector of parameters that will be used to evaluate the models

function cs = evalCSF(model,sfs,params)

%% Parse inputs
if isstruct(model)
   params = model.params;
   model = model.model;
end
if size(sfs,1)>1 && any(size(sfs)==1)
   sfs = sfs';
end

%% Select model to use
switch lower(model)
case 'emg'
      % exponential minus gaussian
      fun = @(p) p(4)*(exp(-sfs/p(1))-p(3)*exp(-(sfs/p(2)).^2)); 
   case 'hmg'
      % hyperbolic secant minus gaussian
      fun = @(p) p(4)*(sech(sfs/p(1))-p(3)*exp(-(sfs/p(2)).^2));
   case 'hpmg'
      % hyperbolic secant, raised to power, minus gaussian
      fun = @(p) p(5)*(sech((sfs/p(1)).^p(4))-p(3)*exp(-(sfs/p(2)).^2));
   case 'hmh'
      % hyperbolic secant minus hyperbolic secant
      fun = @(p) p(4)*(sech(sfs/p(1))-p(3)*sech(sfs/p(2)));
   case 'hpmh'
      % hyperbolic secant, raised to power, minus hyperbolic secant
      fun = @(p) p(5)*(sech((sfs/p(1)).^p(4))-p(3)*sech(sfs/p(2)));
   case 'ms'
      % Mannos & Sakrison, 1974 
      fun = @(p) 10.^(p(4)*((1-p(2)+sfs/p(1)).*exp(-(sfs/p(1)).^p(3))));
   case 'yqm'
      % Yang, Qi, & Makous, 1995
      fun = @(p) p(4)*(exp(-(sfs/p(1)))./(1+(p(3)./(1+(sfs/p(2)).^2))));
   case 'dexp'
      % double exponential (Movshon & Kiorpes, 1988; Wang et al., 2017)
      fun = @(p) p(3)*sfs.^(p(2)/p(1)).*exp(-sfs./p(1)); % p(3) = amplitude; p(2) = peak frequency; p(1) = bandwidth
   case 'dexp_v2'
      % double exponential (Movshon & Kiorpes, 1988; Wang et al., 2017)
      if numel(params)==3
         fun = @(p) p(3)./(p(2).^(p(2)./p(1)).*exp(-(p(2)./p(1)))).*sfs.^(p(2)/p(1)).*exp(-sfs./p(1));
      else
         % input parameters are for an eccentricity matrix
         fun = @(p) p(:,:,:,:,:,3)./(p(:,:,:,:,:,2).^(p(:,:,:,:,:,2)./p(:,:,:,:,:,1)).*exp(-(p(:,:,:,:,:,2)./p(:,:,:,:,:,1)))).*sfs.^(p(:,:,:,:,:,2)./p(:,:,:,:,:,1)).*exp(-sfs./p(:,:,:,:,:,1));
      end
   case 'apf'
      % asymmetric double exponential function
      p = params;
      if numel(p)==4
         cs_low = p(4)./(p(3).^(p(3)./p(1)).*exp(-(p(3)./p(1)))).*sfs.^(p(3)/p(1)).*exp(-sfs./p(1)); % low sfs
         cs_hi = p(4)./(p(3).^(p(3)./p(2)).*exp(-(p(3)./p(2)))).*sfs.^(p(3)/p(2)).*exp(-sfs./p(2)); % high sfs
         % combine into one vector
         cs = nan(1,numel(sfs)); 
         cs(sfs<p(3)) = cs_low(sfs<p(3));
         cs(sfs>=p(3)) = cs_hi(sfs>=p(3));
         return
      else
         % make sure sfs is a column vector
         %if size(sfs,2)>1
            %sfs = sfs';
         %end
         % in this case, we are evaluating a multi-dimensional image
         %p = params;
         %loSF = sfs<p(:,2);
         %hiSF = sfs>=p(:,2);
         %cs(loSF) = 10.^(p(loSF,1)-(sfs(loSF)-p(loSF,2)).^2.*p(loSF,3).^2);
         %cs(hiSF) = 10.^(p(hiSF,1)-(sfs(hiSF)-p(hiSF,2)).^2.*p(hiSF,4).^2);
         %cs = cs';
         
         % input parameters are for an eccentricity matrix
         cs_low = p(:,:,:,:,:,4)./(p(:,:,:,:,:,3).^(p(:,:,:,:,:,3)./p(:,:,:,:,:,1)).*exp(-(p(:,:,:,:,:,3)./p(:,:,:,:,:,1)))).*sfs.^(p(:,:,:,:,:,3)./p(:,:,:,:,:,1)).*exp(-sfs./p(:,:,:,:,:,1));
         cs_hi = p(:,:,:,:,:,4)./(p(:,:,:,:,:,3).^(p(:,:,:,:,:,3)./p(:,:,:,:,:,1)).*exp(-(p(:,:,:,:,:,3)./p(:,:,:,:,:,2)))).*sfs.^(p(:,:,:,:,:,3)./p(:,:,:,:,:,2)).*exp(-sfs./p(:,:,:,:,:,2));
         % combine into one matrix
         cs = nan(size(cs_low));
         low_idx = sfs<p(:,:,:,:,:,3);
         hi_idx = sfs>=p(:,:,:,:,:,3);
         cs(low_idx) = cs_low(low_idx);
         cs(hi_idx) = cs_hi(hi_idx);
         return
      end
   case 'logparab' % (parabola on log-axis, from Watson & Ahuamada, 2005; Watson & Solomon, 1997)
      if numel(params)==3
         % input parameters: [peak_freq bandwidth amplitude]
         fun = @(p) p(3)*exp(-(log2(sfs./p(1))./p(2)).^2);
      else
         % input parameters are for an eccentricity matrix
         fun = @(p) p(:,:,:,:,:,3).*exp(-(log2(sfs./p(:,:,:,:,:,1))./p(:,:,:,:,:,2)).^2);
      end
   case 'raised_cosine'
      %%% NEED TO MAKE THIS WORK WITH AN IMAGE

   case 'rgaus'
      fun = @(p) p(1)*makeGaussian(sfs,p(2),p(3),1).^p(4)+p(5);
   case 'asymgaus'
      fun = @(p) asymGaussian(sfs,p);
   otherwise
      error([model,' has not been implemented.']);
end

%% Evaluate CS
cs = fun(params);

% constrain values to be above or equal to 1
%cs(cs<1) = 1;
