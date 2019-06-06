function features = hurstexp_features(cyan_mask,hemato_mask,eosin_mask)

 % Hurst (15)
        directions = [0,30,45,60,90];
        for jj = 1:5
            hurst_cyan(jj) = fracdim2o(cyan_mask,'GSE', directions(jj));
        end
        for jj = 1:5
            hurst_hemato(jj) = fracdim2o(hemato_mask,'GSE', directions(jj));
        end
        for jj = 1:5
            hurst_eosin(jj) = fracdim2o(eosin_mask,'GSE', directions(jj));
        end
features = [hurst_cyan, hurst_hemato, hurst_eosin];