function [Ypred, BestSigma1, BestLambda1, BestLambda2] = trainSKRRclasslinear(Xtrain,Ytrain,Xvalid,Yvalid,Xtest)

n = size(Xtrain,1);  % numero de muestras

Distancias = pdist([Xtrain;Xvalid]);
medianSigma = median(Distancias(:));
sigmaMin = log10(medianSigma*0.1);
sigmaMax = log10(medianSigma*5);
SIGMAS1 = logspace(sigmaMin,sigmaMax,10);
LAMBDAS1 = [0 logspace(-8,4,10)];
LAMBDAS2 = [0 logspace(-8,4,10)];

KtrainY = Ytrain*Ytrain';

[val Yval] = max(Yvalid');

i=0;
for sigma1 = SIGMAS1
    Ktrain   = kernelmatrix('rbf',Xtrain',Xtrain',sigma1);
    Kvalid   = kernelmatrix('rbf',Xvalid',Xtrain',sigma1);
    for lambda1 = LAMBDAS1
        for lambda2 = LAMBDAS2
            i=i+1;
            if lambda2==0
                gamma = (Ktrain + lambda1*eye(n))\Ytrain;
            else
                gamma = ((Ktrain + lambda1*eye(n)) \ KtrainY) * ((KtrainY+lambda2*eye(n))\Ytrain);
            end
            Yp = Kvalid*gamma;
            [val Ypred] = max(Yp');
            res = assessment(Yval,Ypred,'class');
            RESULTS(i,:) = [sigma1 lambda1 lambda2 res.Kappa];
            
        end
    end
end

% Best model:
[val idx]   = max(RESULTS(:,4));
BestSigma1  = RESULTS(idx,1);
BestLambda1 = RESULTS(idx,2);
BestLambda2 = RESULTS(idx,3);

XX = [Xtrain;Xvalid];
YY = [Ytrain;Yvalid];
[ntrain d] = size(XX);
K = kernelmatrix('rbf',XX',XX',BestSigma1);
Ky = YY*YY';

if BestLambda2==0
    alpha = (K + BestLambda1*eye(ntrain))\YY;
else
    alpha = ((K + BestLambda1*eye(ntrain))\Ky) * ((Ky + BestLambda2*eye(ntrain))\YY);
end

% Predict in batches for large test matrices
n = size(Xtest,1);   % samples and dimensions numbers
if n<1000
    folds=1;
else
    folds = round(n/1000); % number of approximate folds for testing (a fold will contain roughly 1000 samples)
end
indices = crossvalind('Kfold',1:n,folds); % generate random indices to sample folds

for f=1:folds
    test = find(indices==f);  % select samples belonging to fold "f"
    Xhat = Xtest(test,:);
    K = kernelmatrix('rbf',Xhat',XX',BestSigma1);
    Yp(test,:) = K*alpha;
end

[val Ypred] = max(Yp');


