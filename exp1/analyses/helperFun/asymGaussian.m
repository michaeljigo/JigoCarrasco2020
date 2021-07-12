% Purpose:  This function will create an asymmetric Gaussian with a plateau. There will be two sigma terms and a single exponent that will control
%           the curviness of the function. If the exponent is greater than 2, it will become more like a plateau. An exponent equal to 2 
%           corresponds to a normal distribution.

function ag = asymGaussian(x,center,sigmaLeft, sigmaRight, exponent, amplitude, baseline)

% input can be either 5 scalars or 1 vector
if nargin==2
   p = center;
   center = p(1);
   sigmaLeft = p(2);
   sigmaRight = p(3);
   exponent = p(4);
   amplitude = p(5);
   if length(p)==6
      baseline = p(6);
   else
      baseline = 0;
   end
elseif nargin<6
   error('Need to input a vector of 5 values or 5 separate inputs');
end
if ~exist('baseline','var')
   baseline = 0;
end

% evaluate function
ag = nan(1,numel(x));
ag(x<=center) = amplitude*exp(-(abs(x(x<=center)-center)./sigmaLeft).^exponent)+baseline;
ag(x>center) = amplitude*exp(-(abs(x(x>center)-center)./sigmaRight).^exponent)+baseline;
