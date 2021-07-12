% Purpose:  If inputs are two separate structures, put all parameter values into a vector for input into optimization algorithm. 
%           If there are 3 inputs, re-structure the vector input (3rd input) into the original two structures for each component of the model.

function [params_vec bnd_vec attn] = vectorize_parameters(attn,params_vec)

if nargin==1
   %% Vectorize parameters
   % initialize parameter vector
   params_vec = [];
   bnd_vec = [];

   % add attention modulation parameters into vector
   fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      params_vec = [params_vec; attn.(fields{f})']; 
      bnd_vec = [bnd_vec attn.bnd.(fields{f})];
   end
   bnd_vec = bnd_vec';
elseif nargin==2
   bnd_vec = [];
   %% Re-structure parameters
   % attention modulation
   fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      attn.(fields{f}) = reshape(params_vec(1:numel(attn.(fields{f}))),size(attn.(fields{f})));
      params_vec(1:numel(attn.(fields{f}))) = [];
   end
end
