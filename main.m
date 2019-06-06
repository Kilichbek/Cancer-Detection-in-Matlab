
clc; clear all; close all; % Tidy up

%% Feature Extraction Stage
train_dir = './images/train/';
valid_dir = './images/validation/';
test_dir = './images/test/';

[trainX, trainY] = extract_features(train_dir);
[validX, validY] = extract_features(valid_dir); 
[testX, testY] = extract_features(valid_dir); 

train_matrix = [trainX, trainY'];
valid_matrix = [validX, validY'];
test_matrix = [testX, testY'];

save train_features.mat train_matrix;
save valid_features.mat valid_matrix;
save test_features.mat test_matrix;


%% Normalization
load train_features.mat;
load valid_features.mat;
load test_features.mat;

% columns to be normalized
cols = [1,2,5,7,8,10,11,15];

colmin = min(train_matrix(:,cols));
colmax = max(train_matrix(:,cols));
train_matrix(:,cols) = rescale(train_matrix(:,cols),'InputMin',colmin,'InputMax',colmax);

colmin = min(valid_matrix(:,cols));
colmax = max(valid_matrix(:,cols));
valid_matrix(:,cols) = rescale(valid_matrix(:,cols),'InputMin',colmin,'InputMax',colmax);

colmin = min(test_matrix(:,cols));
colmax = max(test_matrix(:,cols));
test_matrix(:,cols) = rescale(test_matrix(:,cols),'InputMin',colmin,'InputMax',colmax);

%% Principal Component Analysis (PCA)

X = train_matrix(:,1:end-1);
y = train_matrix(:,end);

[m,n] = size(X);
mu = mean(X);
Z = X - repmat(mu,m,1);
coeff = pca(X);
Xd = coeff(:,1:floor(n/2))' * Z';

features = Xd';

% Train a Model
model = fitcsvm(features,y);
score_model = fitPosterior(model,features,y);

% Crossvalidate 
CVSVMModel = crossval(model,'Holdout',0.15);
classLoss = kfoldLoss(CVSVMModel)

% Test the Model
X_test = valid_matrix(:,1:end-1);
y_test = valid_matrix(:,end);

[m,n] = size(X_test);
mu = mean(X_test);
Z = X_test - repmat(mu,m,1);
Xd = coeff(:,1:floor(n/2))' * Z';
features = Xd';


[labels,post_probs] = predict(score_model,features);

acc = get_accuracy(labels,y_test)

table(y_test,labels,post_probs(:,1),post_probs(:,2),'VariableNames',...
    {'TrueLabels','PredictedLabels','NegClassPosterior','PosClassPosterior'})


%% Answer for Final Test

X_test = test_matrix(:,1:end-1);
y_test = test_matrix(:,end);

[m,n] = size(X_test);
mu = mean(X_test);
Z = X_test - repmat(mu,m,1);
Xd = coeff(:,1:floor(n/2))' * Z';
features = Xd';

[labels,post_probs] = predict(score_model,features);

ids = [];
for i=1:m
    str = sprintf("ts%d",i);
    ids = [ids,str];
end

T = table(ids',labels,post_probs(:,1),post_probs(:,2),'VariableNames',...
    {'ID','Predictions','B','C'})

fname='PR_result_16012676.csv';
writetable(T,fname,'Delimiter',',');