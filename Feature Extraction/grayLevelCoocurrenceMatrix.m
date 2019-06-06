function [Homogeneity, Contrast, Energy, Mean, ...
    Desvest, Entropy, Correlation] = grayLevelCoocurrenceMatrix(image, offset)

GLCM = graycomatrix(image,'Offset',offset,'NumLevels',8,'GrayLimits',[]);

statsGLCM = graycoprops(GLCM,{'contrast','correlation','energy','homogeneity'});
Contrast = statsGLCM.Contrast;
Correlation = statsGLCM.Correlation;
Energy = statsGLCM.Energy;
Homogeneity = statsGLCM.Homogeneity;

glcmSymetric = GLCM+GLCM'; % Matriz simétrica al sumar la traspuesta
glcmNorm = glcmSymetric/sum(glcmSymetric(:)); % Matriz normalizada
Entropy = entropy(glcmNorm);
Mean = mean(glcmNorm);
Desvest = std(glcmNorm);