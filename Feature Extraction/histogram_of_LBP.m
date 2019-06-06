function histogram = histogram_of_LBP(img, mapping,n,r)
    
img_lbp = lbp(img,r,n,mapping,'i');
img_hist= hist(img_lbp(:), 0:(mapping.num-1));
histogram  = img_hist./sum(img_hist);

end