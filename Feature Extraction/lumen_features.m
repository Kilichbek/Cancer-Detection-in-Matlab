function features = lumen_features(mask_black)

[lumen_img,lumen_num] = bwlabel(mask_black);
lumen_img = imfill(lumen_img,'holes');

areaLumen = 0;
convexAreaLumen =  0;
solidityLumen =  0;
eccentLumen =  0;
equivDiamLumen =  0;
extentLumen =  0;
perimeterLumen = 0;
rG = 0;
roundnessLumen = 0;
meanDistLumen = 0;
varDistLumen = 0;
numberOfLumens = 0;
compactnessLumen = 0;
circularityLumen = 0;
minMaxRatio = 0;
j = 0;

for i = 1:lumen_num
    if lumen_num == 0
        continue; % If there are not any lumen... next!
    end
    bw = lumen_img == i;
    fg = logical(bw);  % Mask of each individual candidate                               

    prop = regionprops(fg,'Centroid', 'Orientation','Area');
    c = cat(1,prop.Centroid);
    
    if prop.Area > 850 && ~isempty(c)
        
        j = j + 1;
        propLumen = regionprops(fg, 'Area', 'BoundingBox', 'Centroid', 'ConvexArea',...
        'Eccentricity', 'EquivDiameter', 'Extent', 'Orientation', 'Perimeter', 'Solidity',...
        'MinorAxisLength','MajorAxisLength','Circularity');

        areaLumen(j) = cat(1,propLumen.Area); 
        convexAreaLumen(j) = cat(1,propLumen.ConvexArea);
        solidityLumen(j) = convexAreaLumen/areaLumen;
        eccentLumen(j) = cat(1,propLumen.Eccentricity);
        equivDiamLumen(j) = cat(1,propLumen.EquivDiameter);
        extentLumen(j) = cat(1,propLumen.Extent);
        perimeterLumen(j) = cat(1, propLumen.Perimeter);
        circularityLumen(j) = propLumen.Circularity;
        rG(j) = sqrt(areaLumen(j)/pi);
        if ~isempty(propLumen.MinorAxisLength)
            minMaxRatio(j) = propLumen.MajorAxisLength/propLumen.MinorAxisLength;
        end
        if ~isempty(areaLumen(j))
            compactnessLumen(j) = perimeterLumen(j)/sqrt(areaLumen(j));
            roundnessLumen(j) = rG(j)*perimeterLumen(j)/areaLumen(j);
        else
            roundnessLumen(j) = 0;
        end
        frontiersLumen = bwboundaries(fg);
        if isempty(frontiersLumen)
            disp('emtpy front');
            continue;
        end
        fLumen = frontiersLumen{1};
        x = fLumen(:,1);
        y = fLumen(:,2);
        centLumen = cat(1,propLumen.Centroid);
        for z = 1:length(x)
            dist(z)=sqrt((centLumen(2)-x(z))^2+(centLumen(1)-y(z))^2);
        end
        meanDistLumen(j) = mean(dist);
        varDistLumen(j) = var(dist);
    end    
     
end

area = mean(areaLumen);
convexArea = mean(convexAreaLumen);
solidity =  mean(solidityLumen);
eccent = mean(eccentLumen);
equivDiam =  mean(equivDiamLumen);
extent =  mean(extentLumen );
perimeter =  mean(perimeterLumen);
rG = mean(rG);
roundness = mean(roundnessLumen);
meanDist= mean(meanDistLumen);
varDist = mean(varDistLumen);
numberOfLumens = j;
minMaxAxisRation = mean(minMaxRatio);
circularity = mean(circularityLumen);
features = [area,convexArea,solidity,eccent,equivDiam,extent,perimeter,rG,roundness,...
    meanDist,varDist,minMaxAxisRation numberOfLumens,circularity];