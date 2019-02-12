function [bias, slope, lapse] = fitErf_singleLapse(x,y)

% if there are NaNs, remove
nanIdx = isnan(x) | isnan(y);
x(nanIdx) = [];
y(nanIdx) = [];

% based on the range of X, decide starting point and range
% for slope and bias
% b = glmfit(x,y, 'binomial', 'link', 'probit');

% make gamma and lambda symmetrical
[pBest,~,exitflag,~] = fminsearchbnd(@(p) logistic_erf(p, ...
    x, y), [mean(x), 20, 0.05], [min(x) 10 0], [max(x) 100 0.4]);
try
    assert(exitflag == 1); % check that this worked
    bias        = pBest(1);
    slope       = pBest(2);
    lapse    = pBest(3);
catch
    bias = NaN;
    slope = NaN;
    lapse = NaN;
end

if nargout == 1,
    bias = pBest;
end

end

function err = logistic_erf(p, intensity, responses)
% see http://courses.washington.edu/matlab1/Lesson_5.html#1

% compute the vector of responses for each level of intensity
w   = erfFunc(p, intensity);

% negative loglikelihood, to be minimised
err = -sum(responses .*log(w) + (1-responses).*log(1-w));

% from https://github.com/cortex-lab/psychofit/blob/master/psychofit.py
err = -sum( (responses.*log10(w) + (1-responses).*log10(1-w)) );

end

function y = erfFunc(p, x)
% Parameters: p(1) bias
%             p(2) slope
%             p(3) lapse rate-low (guess rate)
%             p(4) lapse rate-high (lapse rate)
%             x   intensity values.

% include a lapse rate, see Wichmann and Hill parameterisation
% y = p(3) + (1 - p(3) - p(4)) * (1./(1+exp(- ( p(1) + p(2).*x ))));
%y = p(3) + (1 - p(3) - p(4)) * (erf( (x-p(1))/p(2) ) + 1 )/2;

% force one single lapse term
y = p(3) + (1 - p(3) - p(3)) * (erf( (x-p(1))/p(2) ) + 1 )/2;

end