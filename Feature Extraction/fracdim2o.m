function [ H, alpha, P, f ] = fracdim2o(input_signal,varargin)
% @author Thomas JANVIER <thomas.janvier@univ-orleans.fr>
% @date 2014-02-03

%% DESCRIPTION
% FRACDIM2O Compute the fractal dimension of the 2D input signal along a
% specified dimension
%   ref : K. Harrar, L. Hamami, E. Lespessailles, and R. Jennane, "Piecewise Whittle estimator for trabecular bone radiograph characterization," Biomedical Signal Processing and Control, vol. 8, no. 6, pp. 657-666, Nov. 2013.
%
% INPUTS :
%
%   SIGNAL :
%       n-by-m numerical matrix
%       input signal
%
% OPTIONS :
%
%   DIRECTION :
%       a scalar [0,360[
%       the direction considered (the angle to the horizontal line)
%
%   METHOD :
%       {GSE, ILE, (MLE), 'WhE', MME, VAR}
%       specify the method to compute the fractal dimension
%
%           - GSE : based on the power spectral density
%                   compute the slope of log(PSD)-vs-log(f)
%                 ref : P. Flandrin, "Wavelet analysis and synthesis of fractional Brownian motion," Information Theory, IEEE Transactions on, vol. 38, no. 2, pp. 910-917, 1992.
%
%           - ILE : based on the generalization of the quadratic 
%                   variations of any gaussian process
%                   copy of the matlab implementation (cf wfbmesti.m)
%                 ref : J. Istas and G. Lang, "Quadratic variations and estimation of the local Hölder index of a Gaussian process," in Annales de l'Institut Henri Poincare (B) Probability and Statistics, 1997, vol. 33, pp. 407?436.
%
%           - MLE : OBSOLETE (high time and memory consumption)
%                   based on the statistical properties of the fBm
%                   compute the maximum likelihood estimation of the H 
%                   parameter in the time domain according to the
%                   statistical properties of the fBm
%                 ref : T. Lundahl, W. J. Ohley, S. M. Kay, and R. Siffert, "Fractional Brownian Motion: A Maximum Likelihood Estimator and Its Application to Image Texture," IEEE Transactions on Medical Imaging, vol. 5, no. 3, pp. 152-161, Sep. 1986.
%
%           - WhE : based on the statistical properties of the fBm
%                   compute the maximum likelihood estimation of the H 
%                   parameter in the frequency domain according to the
%                   statistical properties of the fBm
%                 ref : P. Whittle, "Estimation and information in stationary time series," 1952.
%
%           - MME : based on the mathematical morphology
%                   compute the slope of log(A)-vs-log(k)
%                 ref : P. Maragos and F.-K. Sun, "Measuring the Fractal Dimension of Signals: Morphological Covers and Iterative Optimization," IEEE Transactions on Signal Processing, vol. 41, no. 1, pp. 108-121, 1993.
%
%           - VAR : based on the quadratic variations of gaussian noise
%                 ref : the Scientific Committee of the GRIO (Groupe de Recherche et d?Information sur les Ostéoporoses), V. Bousson, C. Bergot, B. Sutter, P. Levitz, and B. Cortet, ?Trabecular bone score (TBS): available knowledge, clinical relevance, and future prospects,? Osteoporosis International, vol. 23, no. 5, pp. 1489?1501, May 2012.
%
% OUTPUTS :
%
%   H :
%       a scalar [0,1]
%       the signal Hurst Exponent

%% INPUT PARSING
p = inputParser;
addRequired(p,'input_signal',@(x) validateattributes(x,{'numeric'},{'2d','real'}));
addOptional(p,'method','WhE',@(x) any(validatestring(x,{'GSE','VAR','ILE','MLE','WhE','MME','ACF'})));
addOptional(p,'direction',0,@(x) validateattributes(x,{'numeric'},{'real','scalar','>=',0}));
parse(p, input_signal, varargin{:});
method = p.Results.method;

%% OUTPUT INICIALIZATION
P = [];
f = [];
verbose = 0;

%% Maximum Likelihood Estimation (time domain optimisation)
if strcmpi(method,'MLE')
    warning(['This method is obsolete, ' ...
    'applying Whittle maximum likehood estimation ...']);
    method = 'WhE';
end

%% Rotate the image

alpha = p.Results.direction;
signal = imrotation(input_signal,alpha,'nearest');

%% Gaussian Spectral Estimator (log(PSD) vs log(f) linear regression)
if strcmpi(method,'GSE')
    % compute the increments = fractionnal Gaussian noise
    fGn = diff(signal,1,2);
    [ny,nx] = size(fGn);
    % estimate the PSD of the fGn
    [P,f] = periodogram1(fGn(1,:));
    for y=2:ny
        P = P + periodogram1(fGn(y,:));
    end
    P = P./ny;
    % remove the 0 frequency (avoid computational errors)
    P = P(2:end);
    f = f(2:end);
    if(verbose)
        fig1 = figure;
        subplot(1,2,1),imshow(mat2gray(input_signal))
        subplot(1,2,2),loglog(f,P)
        close(fig1)
    end
    % compute the slope of PSD-vs-f
    poly = polyfit(log10(f),log10(P),1);
    % slope = 1-2H
    H = (1-poly(1))/2;
    % safeguard
    H = min(max(H,0),1);  
   
%% Maximum Likelihood Estimation (frequency domain optimisation)    
elseif strcmpi(method,'WhE')||strcmpi(method,'ACF')
    % compute the increments = fractionnal Gaussian noise
    fGn = diff(signal,1,2);
    [ny,nx] = size(fGn);
    % estimate the PSD of the fGn
    [P,f] = periodogram1(fGn(1,:));
    for y=2:ny
        P = P + periodogram1(fGn(y,:));
    end
    P = P./ny;
    % remove the 0 frequency (avoid computational errors)
    P = P(2:end);
    f = f(2:end);
    % define the PSD theoretical expression (using Beran,1994)
    N = 200;%length(f)+1;
    S = @(H) sum(abs(f*ones(1,2*N+1)+ones(size(f))*(2.*pi.*(-N:N))).^(-1-2*H),2);
    f1 = @(H) gamma(2*H+1)*sin(pi*H)*(1-cos(f)).*S(H)/pi;
    theta = @(H) exp(2*sum(log(f1(H)))/(2*N+1));
    T = @(H) f1(H)/theta(H);
    % define the normalisation constant
    c = @(H) mean(P)/mean(T(H));
    % rescale the theoretical psd
    cT = @(H) T(H).*c(H);
    % define the Whittle Likehod Function (wlf)
    wlf = @(H) -sum(-log(cT(H))-(P./cT(H)));
    % maximize the WLF (here we minimize -WLF)
    H = fminbnd(wlf,0,1);

%% Mathematical Morphology (blanket method)
elseif strcmpi(method,'MME')
    r = 1:length(signal)/2;
    se = strel('line',3,0);
    ub = signal;
    lb = signal;
    % for each scales
    A = zeros(size(r));
    for i=1:length(r)
       % dilate the signal
        ub = imdilate(ub,se);
        % erode the signal
        lb = imerode(lb,se);
        % compute the area between the erosion and the dilataion
        A(i) = mean(ub(:)-lb(:));
    end
    p = polyfit(log(r),log(A),1);
    H = p(1);
    % safeguard
    H = min(max(H,0),1);

%% Istas & Lang method (generalized quadratic variations)
elseif strcmpi(method,'ILE')
    V1 = mean(mean((2.*signal(:,2:end-1)-signal(:,1:end-2)-signal(:,3:end)).^2,2));
    V2 = mean(mean((2.*signal(:,3:end-2)-signal(:,1:end-4)-signal(:,5:end)).^2,2));
    H = 0.5*(log(V2)-log(V1));
    % safeguard
    H = min(max(H,0),1);
  
%% VAR (quadratic variations)
elseif strcmpi(method,'VAR')
    V1 = mean(mean((signal(:,1:end-1)-signal(:,2:end)).^2,2));
    V2 = mean(mean((signal(:,1:end-2)-signal(:,3:end)).^2,2));
    H = 0.5*(log2(V2)-log2(V1));
    % safeguard
    H = min(max(H,0),1);
end