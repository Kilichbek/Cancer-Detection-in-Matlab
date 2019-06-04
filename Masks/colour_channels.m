function [r,g,b,cyan,s,H,magenta,E] = colour_channels(img)

% RGB colour space 
r = double(img(:,:,1)); 
g = double(img(:,:,2)); 
b = double(img(:,:,3));

% Normalization
r = r./max(unique(r));
g = g./max(unique(g));
b = b./max(unique(b));

% Cyan, Magenta, Yellow and Key colour space
cmyk = makecform('srgb2cmyk');
a = applycform(img,cmyk);

% cyan
cyan = double(a(:,:,1));
cyan = cyan./max(unique(cyan));

% magenta
magenta = double(a(:,:,2));
magenta = magenta./max(unique(magenta));

% Hue, Saturation and Value colour space
hsv = rgb2hsv(img);
s = hsv(:,:,2);

% Colour Deconvolution for Hematoxylin and Eosin stain
HEtype = 'H&E';
[H,E,~] = colour_deconvolution(uint8(img), HEtype);