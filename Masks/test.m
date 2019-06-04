I = imread(['images/' 'c85.jpg']);
img = I;
[r,g,b,cyan,s,H,magenta] = colour_channels(img);
[nucleous, nuclei_post] = nuclei_mask(img);
[lumen, black_mask] = lumen_mask(img,s);
[cyto_mask,stroma_mask,overlay] = cytoplasm_stroma_mask(img, black_mask,nuclei_post,cyan);
%img_seg = Segmentation(nuclei_post,lumen,black_mask,stroma_mask);
