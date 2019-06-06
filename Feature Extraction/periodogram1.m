function [ PSD,FREQ ] = periodogram1( SIGNAL,varargin )
% @author Thomas JANVIER <thomas.janvier@univ-orleans.fr>
% @creation 2014-02-19
% @modified 2015-05-06

%% DESCRIPTION
% PERIDOGRAM1 compute the 1D periodogram of SIGNAL
%
% INPUTS :
%
%   SIGNAL :
%       n-by-1 or 1-by-n numerical vector
%       data as row or column vector
%
% OPTIONS :
%
%   TRIM :
%       bool (true) if trim 0 frequency
%
% OUTPUTS :
%
%   PSD :
%       floor(n/2)+1-by-1 numerical vector
%       the spectral density power
%
%   F :
%       floor(n/2)+1-by-1 numerical vector
%       the normalized frequencies


%% INPUT PARSING
p = inputParser;
addRequired(p,'SIGNAL',@(x) validateattributes(x,{'numeric'},{'vector'}));
addOptional(p,'trim',false,@(x) validateattributes(x,{'logical'},{'scalar'}));
parse(p, SIGNAL, varargin{:});

%% ALGORITHM

% determine the SIGNAL length
n = length(SIGNAL);
% compute the fft
dft = fft(SIGNAL(:));
% extract the power of the fft
power = dft.*conj(dft)./pi./n;
% compute the normalized frequencies
FREQ = linspace(0,pi,floor(n/2)+1)';
% normalize the power over the frequencies
PSD = power(1:floor(n/2)+1);

if p.Results.trim
    FREQ = FREQ(2:end);
    PSD = PSD(2:end);
end