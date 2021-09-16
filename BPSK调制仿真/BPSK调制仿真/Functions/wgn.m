function y = wgn(varargin)
%WGN Generate white Gaussian noise.
%   Y = WGN(M,N,P) generates an M-by-N matrix of white Gaussian noise.
%   P specifies the power of the output noise in dBW.
%
%   Y = WGN(M,N,P,IMP) specifies the load impedance in Ohms.
%
%   Y = WGN(M,N,P,IMP,STATE) resets the state of RANDN to STATE.
%
%   Additional flags that can follow the numeric arguments are:
%
%   Y = WGN(..., POWERTYPE) specifies the units of P.  POWERTYPE can
%   be 'dBW', 'dBm' or 'linear'.  Linear power is in Watts.
%
%   Y = WGN(..., OUTPUTTYPE); Specifies the output type.  OUTPUTTYPE can
%   be 'real' or 'complex'.  If the output type is complex, then P
%   is divided equally between the real and imaginary components.
%
%   Example 1: 
%       % To generate a 1024-by-1 vector of complex noise with power
%       % of 5 dBm across a 50 Ohm load, use:
%       Y = wgn(1024, 1, 5, 50, 'dBm', 'complex')
%
%   Example 2: 
%       % To generate a 256-by-5 matrix of real noise with power
%       % of 10 dBW across a 1 Ohm load, use:
%       Y = wgn(256, 5, 10, 'real')
%
%   Example 3: 
%       % To generate a 1-by-10 vector of complex noise with power
%       % of 3 Watts across a 75 Ohm load, use:
%       Y = wgn(1, 10, 3, 75, 'linear', 'complex')
%
%   See also RANDN, AWGN.

%   Copyright 1996-2008 The MathWorks, Inc.
%   $Revision: 1.11.4.5 $  $Date: 2008/08/01 12:17:45 $

% --- Initial checks
error(nargchk(3,7,nargin,'struct'));

% --- Value set indicators (used for the strings)
pModeSet    = 0;
cplxModeSet = 0;

% --- Set default values
p        = [];
row      = [];
col      = [];
pMode    = 'dbw';
imp      = 1;
cplxMode = 'real';
seed     = [];

% --- Placeholders for the numeric and string index values
numArg = [];
strArg = [];

% --- Identify string and numeric arguments
%     An empty in position 4 (Impedance) or 5 (Seed) are considered numeric
for n=1:nargin
   if(isempty(varargin{n}))
      switch n
      case 4
         if(ischar(varargin{n}))
            error('comm:wgn:InvalidDefaultImp','The default impedance should be marked by [].');
         end;
         varargin{n} = imp; % Impedance has a default value
      case 5
         if(ischar(varargin{n}))
            error('comm:wgn:InvalidNumericInput','The default seed should be marked by [].');
         end;
         varargin{n} = [];  % Seed has no default
      otherwise
         varargin{n} = '';
      end;
   end;

   % --- Assign the string and numeric vectors
   if(ischar(varargin{n}))
      strArg(size(strArg,2)+1) = n;
   elseif(isnumeric(varargin{n}))
      numArg(size(numArg,2)+1) = n;
   else
      error('comm:wgn:InvalidArg','Only string and numeric arguments are allowed.');
   end;
end;

% --- Build the numeric argument set
switch(length(numArg))

   case 3
      % --- row is first (element 1), col (element 2), p (element 3)

      if(all(numArg == [1 2 3]))
         row    = varargin{numArg(1)};
         col    = varargin{numArg(2)};
         p      = varargin{numArg(3)};
      else
         error('comm:wgn:InvalidSyntax','Illegal syntax.')
      end;

   case 4
      % --- row is first (element 1), col (element 2), p (element 3), imp (element 4)
      %

      if(all(numArg(1:3) == [1 2 3]))
         row    = varargin{numArg(1)};
         col    = varargin{numArg(2)};
         p      = varargin{numArg(3)};
         imp    = varargin{numArg(4)};
      else
         error('comm:wgn:InvalidSyntax','Illegal syntax.')
      end;

   case 5
      % --- row is first (element 1), col (element 2), p (element 3), imp (element 4), seed (element 5)

      if(all(numArg(1:3) == [1 2 3]))
         row    = varargin{numArg(1)};
         col    = varargin{numArg(2)};
         p      = varargin{numArg(3)};
         imp    = varargin{numArg(4)};
         seed   = varargin{numArg(5)};
      else
         error('comm:wgn:InvalidSyntax','Illegal syntax.');
      end;
   otherwise
      error('comm:wgn:InvalidSyntax','Illegal syntax.');
end;

% --- Build the string argument set
for n=1:length(strArg)
   switch lower(varargin{strArg(n)})
   case {'dbw' 'dbm' 'linear'}
      if(~pModeSet)
         pModeSet = 1;
         pMode = lower(varargin{strArg(n)});
      else
         error('comm:wgn:TooManyPowerTypes','The Power mode must only be set once.');
      end;
   case {'db'}
      error('comm:wgn:InvalidPowerType','Incorrect power mode passed in.  Please use ''dBW'', ''dBm'', or ''linear.''');
   case {'real' 'complex'}
      if(~cplxModeSet)
         cplxModeSet = 1;
         cplxMode = lower(varargin{strArg(n)});
      else
         error('comm:wgn:TooManyOutputTypes','The complexity mode must only be set once.');
      end;
   otherwise
      error('comm:wgn:InvalidArgOption','Unknown option passed in.');
   end;
end;

% --- Arguments and defaults have all been set, either to their defaults or by the values passed in
%     so, perform range and type checks

% --- p
if(isempty(p))
   error('comm:wgn:InvalidPowerVal','The power value must be a real scalar.');
end;

if(any([~isreal(p) (length(p)>1) (length(p)==0)]))
   error('comm:wgn:InvalidPowerVal','The power value must be a real scalar.');
end;

if(strcmp(pMode,'linear'))
   if(p<0)
      error('comm:wgn:NegativePower','In linear mode, the required noise power must be >= 0.');
   end;
end;

% --- Dimensions
if(any([isempty(row) isempty(col) ~isscalar(row) ~isscalar(col)]))
   error('comm:wgn:InvalidDims','The required dimensions must be real, integer scalars > 1.');
end;

if(any([(row<=0) (col<=0) ~isreal(row) ~isreal(col) ((row-floor(row))~=0) ((col-floor(col))~=0)]))
   error('comm:wgn:InvalidDims','The required dimensions must be real, integer scalars > 1.');
end;

% --- Impedance
if(any([~isreal(imp) (length(imp)>1) (length(imp)==0) any(imp<=0)]))
   error('comm:wgn:InvalidImp','The Impedance value must be a real scalar > 0.');
end;

% --- Seed
if(~isempty(seed))
   if(any([~isreal(seed) (length(seed)>1) (length(seed)==0) any((seed-floor(seed))~=0)]))
      error('comm:wgn:InvalidState','The State must be a real, integer scalar.');
   end;
end;

% --- All parameters are valid, so no extra checking is required
switch lower(pMode)
   case 'linear'
      noisePower = p;
   case 'dbw'
      noisePower = 10^(p/10);
   case 'dbm'
      noisePower = 10^((p-30)/10);
end;

% --- Generate the noise
if(~isempty(seed))
   randn('state',seed);
end;

if(strcmp(cplxMode,'complex'))
   z = randn(2*row,col);
   y = (sqrt(imp*noisePower/2))*(z(1:row,:)+j*z(row+1:end,:));
else
   y = (sqrt(imp*noisePower))*randn(row,col);
end;
