function [cyto_mask,stroma_mask,overlay] = cytoplasm_stroma_mask(img, black_mask,nuclei_mask,cyan,se_open,se_dil)

% set random generator to default;
rng('default');

% set default parametres
if nargin < 5
    se_open = 20;
    se_dil = 1;
end

% Preprocessing 
c = cyan;
c(nuclei_mask == 1) = 0;

% Apply K-means clustering to obtain stroma mask
[~, C] = kmeans(c(:), 3,'Distance','sqeuclidean', 'Replicates', 5);
[~, ind] = sort(sum(C,2));
C = C(ind,:); % Centroid coordinates by order
D = pdist2(c(:), C); 
[~, id] = min(D, [], 2); 
cluster = reshape(id,size(img,1),size(img,2));

% Stroma postprocessing 
stroma_mask = cluster == 2;
black_mask = imfill(black_mask,'holes');
strom = stroma_mask-black_mask;
strom = strom == 1;
st = bwareaopen(strom,10);
st = imopen(st,strel('disk',se_dil));
stroma_mask = logical(st);

% Cytoplasm postprocessing
cytoplasm_mask = cluster == 3;
cytoplasm_mask = imdilate(cytoplasm_mask, strel('disk',se_dil));
cytoplasm_mask = cytoplasm_mask - black_mask;
cyto = cytoplasm_mask == 1;
cyto = cyto-nuclei_mask;
cyto = cyto-stroma_mask;
cyto = cyto == 1;
cyto = bwareaopen(cyto, se_open);
cyto_mask = logical(cyto);

% Overlay
over = imoverlay(img, cytoplasm_mask, 'green');
overlay = imoverlay(over, nuclei_mask, 'black');