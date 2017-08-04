function [time, f0] = max_likelihood(x,fs, varargin)

%maximum likelihood pitch estimator based on the paper by
%James D Wise published in 1976

%they chose K0 = 384 because They assume minimum fundamental
%frequency to be 8450/384 = 22Hz. Their sampling frequency was 8450

K0 = round(fs/50);
hop = round(K0/4);
n = length(x);
nframes = ceil(n/hop);
x = [x, zeros(1,nframes*K0 - n + K0-hop)];
xframes = zeros(nframes, K0);
%this is the function we need to maximise
g = zeros(1,2*K0);
start = 1;
f0 = zeros(nframes,K0);
time = zeros(nframes,K0);
p = 0:0.5:K0-0.5;

for i = 1:nframes
    xframes(i,:) = x(start:start+K0-1);
    %to test fractional values of P, we use zero-order
    %hold on the function phi(lP), i.e, phi(lp) = phi(floor(lP))
    [rcorr, lags]  = xcorr(xframes(i,:));
    rcorr = [rcorr(max(lags)+2 : end), 0];
    for j = 3:2*K0
        N = floor(K0/p(j));
        g(j) = 2*p(j)/K0 * sum_autocorr(rcorr,N+1,p(j));       
    end

    %find P which maximises g(p)
    [val,ind] = max(g);
    P = p(ind);
    f0(i,:) = fs/P * ones(1,K0);
    time(i,:) = (start-1:start+K0-2)/fs;
    start = start + hop;
    
end
    
%check if frames are silent
if ~isempty(varargin)
    f0 = silent_frame_classification(xframes,f0);
end

f0 = reshape(f0',1,nframes*K0);
time = reshape(time',1,nframes*K0);
end


