function [ OUT ] = imrotation( IN,ALPHA, varargin )
% @author Thomas JANVIER <thomas.janvier@univ-orleans.fr>
% @date 2014-04-15

%% DESCRIPTION
% IMROTATION Rotate the image and crop the valid part (for any angle)
%
% INPUTS :
%
%   IN :
%       m-by-n matrix
%       input image
%
%   ALPHA : 
%       a scalar [0,360[
%       the angle
%
% OPTIONS :
%
%   METHOD :
%       {'nearest', linear, spline, cubic}
%       specify the method to interpolate the datas (see interp2)
%
% OUTPUTS :
%
%   OUT :
%       a matrix
%       the rotated/croped image

%% INPUT PARSING
p = inputParser;
addRequired(p,'IN',@(x) validateattributes(x,{'numeric'},{'2d','real'}));
addRequired(p,'ALPHA',@(x) validateattributes(x,{'numeric'},{'real','scalar','>=',0}));
addOptional(p,'method','nearest',@(x) any(validatestring(x,{'nearest','linear','spline','cubic'})));
parse(p, IN, ALPHA, varargin{:});

method = p.Results.method;
alpha = -ALPHA*pi/180;

[ny,nx] = size(IN);
[y,x] = ndgrid(1:ny,1:nx);

center = [ny+1,nx+1]./2;
side = min(ny,nx)/2;

newside = floor(sqrt(2)/2*side)-1;

tmpy = linspace(-1,1,2*newside);
tmpx = linspace(-1,1,2*newside);
[tmpy,tmpx] = ndgrid(tmpy,tmpx);
newy = newside*(tmpx.*sin(alpha)+tmpy.*cos(alpha))+center(1);
newx = newside*(tmpx.*cos(alpha)-tmpy.*sin(alpha))+center(2);

OUT = interp2(x,y,double(IN),newx,newy,method);
end