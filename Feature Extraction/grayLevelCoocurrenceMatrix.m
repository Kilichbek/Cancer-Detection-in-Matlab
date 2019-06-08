function [Homogeneity, Contrast, Energy, Mean, ...
    Desvest, Entropy, Correlation] = grayLevelCoocurrenceMatrix(image, offset)

GLCM = graycomatrix(image,'Offset',offset,'NumLevels',8,'GrayLimits',[]);

statsGLCM = graycoprops(GLCM,{'contrast','correlation','energy','homogeneity'});
Contrast = statsGLCM.Contrast;
Correlation = statsGLCM.Correlation;
Energy = statsGLCM.Energy;
Homogeneity = statsGLCM.Homogeneity;

glcmSymetric = GLCM+GLCM'; % Symmetric matrix when adding the transpose
glcmNorm = glcmSymetric/sum(glcmSymetric(:)); % Normalized matrix
Entropy = entropy(glcmNorm);
Mean = mean(glcmNorm);
Desvest = std(glcmNorm);