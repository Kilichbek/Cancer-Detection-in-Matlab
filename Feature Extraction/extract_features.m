function [features,response,ids] = extract_features(input_dir)
rng('default');
addpath('Masks');

img_files = dir(fullfile(input_dir,'*.jpg*'));

lfeats = [];
lbpfeats = [];
nfeats = [];
gfeats = [];
hfeats = [];
features = [];
ids = [];

for i=1:length(img_files)
    
    filename = img_files(i).name;
    str = sprintf("%s",filename);
    ids = [ids,str];
    % label the image
    label = filename(1);
    switch label
        case 'b'
            response(i) = 0;
        case 'c'
            response(i) = 1;
        otherwise
            response(i) = -1;
    end
    
    img = imread([input_dir filename]);
    
    % get colors and masks
    [r,g,b,cyan,s,H,magenta,E] = colour_channels(img);
    [nucleous, nuclei] = nuclei_mask(img);
    [lumen, black_mask] = lumen_mask(img,s);

    % Obtain color Masks
    cyan_mask = imresize(cyan, 2);
    hemo_mask  = imresize(H, 2);
    eosin_mask  = imresize(E, 2);
    
    % Feature Extraction Stage
    
    lfeats(i,:) = lumen_features(black_mask);
    nfeats(i,:) = nuclei_features(nuclei);
    lbpfeats(i,:) = lbp_features(cyan_mask,hemo_mask,eosin_mask);
    gfeats(i,:) = glcm_features(cyan_mask,hemo_mask,eosin_mask);
    hfeats(i,:) = hurstexp_features(cyan_mask,hemo_mask,eosin_mask);
    disp(i);
end

features = cat(2,lfeats,nfeats,lbpfeats,gfeats,hfeats);