function [nucleous, nuclei_post] = nuclei_mask(img,se_open,se_dil)

% set random generator to default;
rng('default');

% set default parametres
if nargin < 3
    se_open = 20;
    se_dil = 1;
end

% Remove noise and sharpen the image
gauss_filter = fspecial('gaussian',200);
img = imfilter(img,gauss_filter,'replicate'); 
img = imsharpen(img);

% Define the parametres
img = double(img);
[s1,s2,s3] = size(img);

% Obtention data
pixels = reshape(img(:),s1 * s2, s3);
pixels_ind = randi(length(pixels), round(length(pixels)*0.05), 1)';
data = pixels(pixels_ind, :);

% Apply K-means Clustering
[~, C] = kmeans(data, 4,'Distance','sqeuclidean', 'Replicates', 5);
[~, ind] = sort(sum(C,2));
C = C(ind,:); % Centroid coordinates by order
D = pdist2(pixels, C); 
[~, id] = min(D, [], 2); 
cluster_img = reshape(id,s1,s2);

% Postprocessing 
nucleous = cluster_img == 1;
nuclei_mask = imdilate(nucleous, strel('disk',se_dil));
nuclei_mask = bwareaopen(nuclei_mask,se_open);
nuclei_post = logical(nuclei_mask);