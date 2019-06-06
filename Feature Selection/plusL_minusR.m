
function features = plusL_minusR(features,y)

% Split the data into  calibration and validation sets
[m,n] = size(features);
P = 0.70;
idx = randperm(m);
left = idx(1:round(P * m));
right = idx(round(P * m)+1:end);

x_acc = zeros(1,n);

% Compute 𝐽(𝑥) for each feature 𝑥 ∈ X
for i=1:n
    model = fitcsvm(features(left,i),y(left));
    predicted = predict(model,features(right,i));
    x_acc(i) = get_accuracy(predicted,y(right));
end

% Sort the feature set 𝑋 in descending order of the classification accuracy
[~,sort_idx] = sort(x_acc,'descend');
acc = zeros(1,n);

for i=1:n
    model = fitcsvm(features(left,sort_idx(1:i)),y(left));
    predicted = predict(model,features(right,sort_idx(1:i)));
    acc(i) = get_accuracy(predicted,y(right));
end

[argvalue, argmax] = max(acc);
Y = sort_idx(1:argmax);
X = sort_idx(argmax+1:n);

for i=1:3
    for j=1:3
        
        % Select the best feature 𝑥𝑏𝑒𝑠𝑡 from 𝑋 that maximizes 𝐽{𝑌 ∪ 𝑥𝑏𝑒𝑠𝑡}
        for m=1:size(X)
            model = fitcsvm(features(left,[Y,X(m)]),y(left));
            predicted = predict(model,features(right,[Y,X(m)]));
            new_accuracy = get_accuracy(predicted,y(right));
            
            % Update 𝑌 = 𝑌 ∪ 𝑥𝑏𝑒𝑠𝑡
            if new_accuracy > argvalue
                Y = [Y,X(m)];
                argvalue = new_accuracy;
            end
        end
    end
    for j=1:2
        
        % Select the best feature 𝑦𝑏𝑒𝑠𝑡 from 𝑌 that maximizes 𝐽{𝑌 \ 𝑦𝑏𝑒𝑠𝑡}
        for m=1:size(Y)
            model = fitcsvm(features(left,setdiff(Y,Y(m))),y(left));
            predicted = predict(model,features(right,setdiff(Y,Y(m))));
            new_accuracy = get_accuracy(predicted,y(right));
            
            % Update 𝑌 = 𝑌 \ 𝑦𝑏𝑒𝑠𝑡
            if new_accuracy > argvalue
                Y(X(m)) = [];
                argvalue = new_accuracy;
            end
        end
    end
end

features = Y;

end           

