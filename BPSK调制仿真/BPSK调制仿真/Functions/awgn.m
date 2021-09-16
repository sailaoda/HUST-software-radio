function y=awgn(varargin)
%AWGN Add white Gaussian noise to a signal.
% Y = AWGN(X,SNR) adds white Gaussian noise to X. The SNR is in dB.
% The power of X is assumed to be 0 dBW. If X is complex, then
% AWGN adds complex noise.
%
% Y = AWGN(X,SNR,SIGPOWER) when SIGPOWER is numeric, it represents
% the signal power in dBW. When SIGPOWER is 'measured', AWGN measures
% the signal power before adding noise.
%
% Y = AWGN(X,SNR,SIGPOWER,S) uses S, which is a random stream handle, to
% generate random noise samples with RANDN. If S is an integer, then
% resets the state of RANDN to S. The latter usage is obsoleted and may
% be removed in a future release. If you want to generate repeatable
% noise samples, then provide the handle of a random stream or use reset
% method on the default random stream. Type 'help RandStream' for more
% information.
%
% Y = AWGN(X,SNR,SIGPOWER,STATE) resets the state of RANDN to STATE.
% This usage is deprecated and may be removed in a future release.
%
% Y = AWGN(..., POWERTYPE) specifies the units of SNR and SIGPOWER.
% POWERTYPE can be 'db' or 'linear'. If POWERTYPE is 'db', then SNR
% is measured in dB and SIGPOWER is measured in dBW. If POWERTYPE is
% 'linear', then SNR is measured as a ratio and SIGPOWER is measured
% in Watts.
%
% Example 1:
% % To specify the power of X to be 0 dBW and add noise to produce
% % an SNR of 10dB, use:
% X = sqrt(2)*sin(0:pi/8:6*pi);
% Y = awgn(X,10,0);
%
% Example 2:
% % To specify the power of X to be 3 Watts and add noise to
% % produce a linear SNR of 4, use:
% X = sqrt(2)*sin(0:pi/8:6*pi);
% Y = awgn(X,4,3,'linear');
%
% Example 3:
% % To cause AWGN to measure the power of X and add noise to
% % produce a linear SNR of 4, use:
% X = sqrt(2)*sin(0:pi/8:6*pi);
% Y = awgn(X,4,'measured','linear');
%
% Example 4:
% % To specify the power of X to be 0 dBW, add noise to produce
% % an SNR of 10dB, and utilize a local random stream, use:
% S = RandStream('mt19937ar','seed',5489);
% X = sqrt(2)*sin(0:pi/8:6*pi);
% Y = awgn(X,10,0,S);
%
% Example 5:
% % To specify the power of X to be 0 dBW, add noise to produce
% % an SNR of 10dB, and produce reproducible results, use:
% reset(RandStream.getGlobalStream)
% X = sqrt(2)*sin(0:pi/8:6*pi);
% Y = awgn(X,10,0,S);
%
%
% See also WGN, RANDN, RandStream/RANDN, and BSC.
% Copyright 1996-2011 The MathWorks, Inc.
% --- Initial checks
error(nargchk(2,5,nargin,'struct'));
% --- Value set indicators (used for the string flags)
pModeSet = 0;
measModeSet = 0;
% --- Set default values
sigPower = 0;
pMode = 'db';
measMode = 'specify';
state = [];
% --- Placeholder for the signature string
sigStr = '';
% --- Identify string and numeric arguments
isStream = false;
for n=1:nargin
if(n>1)
sigStr(size(sigStr,2)+1) = '/';
end
% --- Assign the string and numeric flags
if(ischar(varargin{n}))
sigStr(size(sigStr,2)+1) = 's';
elseif(isnumeric(varargin{n}))
sigStr(size(sigStr,2)+1) = 'n';
elseif(isa(varargin{n},'RandStream'))
sigStr(size(sigStr,2)+1) = 'h';
isStream = true;
else
error(message('comm:awgn:InvalidArg'));
end
end
% --- Identify parameter signatures and assign values to variables
switch sigStr
% --- awgn(x, snr)
case 'n/n'
sig = varargin{1};
reqSNR = varargin{2};
% --- awgn(x, snr, sigPower)
case 'n/n/n'
sig = varargin{1};
reqSNR = varargin{2};
sigPower = varargin{3};
% --- awgn(x, snr, 'measured')
case 'n/n/s'
sig = varargin{1};
reqSNR = varargin{2};
measMode = lower(varargin{3});
measModeSet = 1;
% --- awgn(x, snr, sigPower, state)
case {'n/n/n/n', 'n/n/n/h'}
sig = varargin{1};
reqSNR = varargin{2};
sigPower = varargin{3};
state = varargin{4};
% --- awgn(x, snr, 'measured', state)
case {'n/n/s/n', 'n/n/s/h'}
sig = varargin{1};
reqSNR = varargin{2};
measMode = lower(varargin{3});
state = varargin{4};
measModeSet = 1;
% --- awgn(x, snr, sigPower, 'db|linear')
case 'n/n/n/s'
sig = varargin{1};
reqSNR = varargin{2};
sigPower = varargin{3};
pMode = lower(varargin{4});
pModeSet = 1;
% --- awgn(x, snr, 'measured', 'db|linear')
case 'n/n/s/s'
sig = varargin{1};
reqSNR = varargin{2};
measMode = lower(varargin{3});
pMode = lower(varargin{4});
measModeSet = 1;
pModeSet = 1;
% --- awgn(x, snr, sigPower, state, 'db|linear')
case {'n/n/n/n/s', 'n/n/n/h/s'}
sig = varargin{1};
reqSNR = varargin{2};
sigPower = varargin{3};
state = varargin{4};
pMode = lower(varargin{5});
pModeSet = 1;
% --- awgn(x, snr, 'measured', state, 'db|linear')
case {'n/n/s/n/s', 'n/n/s/h/s'}
sig = varargin{1};
reqSNR = varargin{2};
measMode = lower(varargin{3});
state = varargin{4};
pMode = lower(varargin{5});
measModeSet = 1;
pModeSet = 1;
otherwise
error(message('comm:awgn:InvalidSyntax'));
end
% --- Parameters have all been set, either to their defaults or by the values passed in,
% so perform range and type checks
% --- sig
if(isempty(sig))
error(message('comm:awgn:NoInput'));
end
if(ndims(sig)>2)
error(message('comm:awgn:InvalidSignalDims'));
end
% --- measMode
if(measModeSet)
if(~strcmp(measMode,'measured'))
error(message('comm:awgn:InvalidSigPower1'));
end
end
% --- pMode
if(pModeSet)
switch pMode
case {'db' 'linear'}
otherwise
error(message('comm:awgn:InvalidPowerType'));
end
end
% -- reqSNR
if(any([~isreal(reqSNR) (length(reqSNR)>1) (isempty(reqSNR))]))
error(message('comm:awgn:InvalidSNR'));
end
if(strcmp(pMode,'linear'))
if(reqSNR<=0)
error(message('comm:awgn:InvalidSNRForLinearMode'));
end
end
% --- sigPower
if(~strcmp(measMode,'measured'))
% --- If measMode is not 'measured', then the signal power must be specified
if(any([~isreal(sigPower) (length(sigPower)>1) (isempty(sigPower))]))
error(message('comm:awgn:InvalidSigPower2'));
end
if(strcmp(pMode,'linear'))
if(sigPower<0)
error(message('comm:awgn:InvalidSigPowerForLinearMode'));
end
end
end
% --- state
if(~isempty(state))
if ~isStream
validateattributes(state, {'double', 'RandStream'}, ...
{'real', 'scalar', 'integer'}, 'awgn', 'S');
end
end
% --- All parameters are valid, so no extra checking is required
% --- Check the signal power. This needs to consider power measurements on matrices
if(strcmp(measMode,'measured'))
sigPower = sum(abs(sig(:)).^2)/length(sig(:));
if(strcmp(pMode,'db'))
sigPower = 10*log10(sigPower);
end
end
% --- Compute the required noise power
switch lower(pMode)
case 'linear'
noisePower = sigPower/reqSNR;
case 'db'
noisePower = sigPower-reqSNR;
pMode = 'dbw';
end
% --- Add the noise
if(isreal(sig))
opType = 'real';
else
opType = 'complex';
end
y = sig+wgn(size(sig,1), size(sig,2), noisePower, 1, state, pMode, opType);