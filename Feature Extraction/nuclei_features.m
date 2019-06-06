function features = nuclei_features(nuclei_mask)

[nuclei_img,nuclei_num] = bwlabel(nuclei_mask,8);
nuclei_img = imfill(nuclei_img,'holes');
nuclei_img = imopen(nuclei_img,strel('disk',2));
nuclei_img = bwareaopen(nuclei_img,20);
[nuclei_img,nuclei_num] = bwlabel(nuclei_img,8);

propNuclei = regionprops(nuclei_img, 'Area');
[m,n] = size(nuclei_mask);
numNucAreaprop = nuclei_num/(m*n);

sum = 0;
for i=1:nuclei_num
    sum = sum+propNuclei(i).Area;
end
features = [sum ,nuclei_num];