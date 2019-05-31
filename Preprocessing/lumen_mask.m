function [lumen_mask, black_mask] = lumen_mask(img,s,lumen_size,se_dil)

% set random generator to default;
rng('default');

% set default parametres
if nargin < 3
    lumen_size = 20; % To remove lumen objects that are considered noise
    se_dil = 1;
end

% Apply K-means Clustering for lumen
[~, C] = kmeans(s(:), 3,'Distance','sqeuclidean', 'Replicates', 5);
[~, ind] = sort(sum(C,2));
C = C(ind,:); % Centroid coordinates by order
D = pdist2(s(:), C); 
[~, id] = min(D, [], 2); 
cluster = reshape(id,size(img,1),size(img,2)); 
lumen = cluster == 1; 

% Postprocessing 
lumen_img = double(lumen); 
lumen_img = bwareaopen(lumen_img,lumen_size);
se = strel('disk',se_dil);
lumen_mask = imdilate(lumen_img,se);

% Background
black_mask = lumen_mask;
[lumen_img, lumen_num] = bwlabel(black_mask);
for i = 1:lumen_num
    obj = lumen_img == i;
    unic = sum(unique(obj(1,:)) + unique(obj(:,1)) + ...
        unique(obj(end,:)) + unique(obj(:,end)));
    if unic>0
        black_mask(obj) = 0; % Lumen mask processed with the background black
    end
end