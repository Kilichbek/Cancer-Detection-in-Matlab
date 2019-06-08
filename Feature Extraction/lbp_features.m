function [lbp_hist_cyan, lbp_hist_hemo, lbp_hist_eosin] = lbp_features(cyan_mask,hemo_mask,eosin_mask)

neigh = 8;
radius = 1; 
mapping = getmapping(neigh,'riu2');

% Cyan (10)
lbp_hist_cyan = histogram_of_LBP(cyan_mask,mapping,neigh,radius);

% Hematoxylin (10)
lbp_hist_hemo = histogram_of_LBP(hemo_mask,mapping,neigh,radius);

% Eosin (10)
lbp_hist_eosin = histogram_of_LBP(eosin_mask,mapping,neigh,radius);