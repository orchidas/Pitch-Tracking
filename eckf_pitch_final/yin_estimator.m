function [time, f0] = yin_estimator(x, fs, varargin)

%function that implements YIN algorithm for
%fundamental pitch tracking
%x - input audio signal
%fs - sampling rate
%time,f0 - time vector and associated fundamental frequencies estimated

%window size -  we assume the minimum f0 to be 1/0.025 = 40Hz
win = round(0.025*fs);
N = length(x);
nframes = ceil(N/win);
%zero pad signal to have enough frames
x = [x, zeros(1,win*nframes - N)];
x_frame = zeros(nframes, win);
start = 1;
%break into windows
for i = 1:nframes
    x_frame(i,:) = x(start:start + win - 1);
    start = start + win;
end

%step 1 - calculate difference function 
d = zeros(nframes,win);
x_temp = [x_frame, zeros(nframes,win)];
for tau = 0:win-1
    for j = 1:win  
         d(:,tau+1) = d(:,tau+1) + (x_temp(:,j) - x_temp(:,j+tau)).^2;         
    end
end


%step 2 - cumulative mean normalised difference function
d_norm = zeros(nframes,win);
d_norm(:,1) = 1;

for i = 1:nframes
    for tau = 1:win-1
        d_norm(i,tau+1) = d(i,tau+1)/((1/tau) * sum(d(i,1:tau+1)));
    end
end

% figure(1);
% subplot(211);
% plot(0:length(x)-1, reshape(d',1,length(x)));grid on;
% xlabel('Lags');
% ylabel('Difference function');
% subplot(212);
% plot(0:length(x)-1, reshape(d_norm',1,length(x)));grid on;
% xlabel('Lags');
% ylabel('Cumulative mean difference function');

%step 3 - absolute thresholding
lag = zeros(1,nframes);
th = 0.1;
for i = 1:nframes
    l = find(d_norm(i,:) < th,1);
    if(isempty(l) == 1)
        [v,l] = min(d_norm(i,:));
    end
    lag(i) = l;
    
end

%step 4 - parabolic interpolation
period = zeros(1,nframes);
time = zeros(nframes,win);
f0 = zeros(nframes,win);
start = 1;

for i = 1:nframes
    if(lag(i) > 1 && lag(i) < win)
        alpha = d_norm(i,lag(i)-1);
        beta = d_norm(i,lag(i));
        gamma = d_norm(i,lag(i)+1);
        peak = 0.5*(alpha - gamma)/(alpha - 2*beta + gamma);
        %ordinate needs to be calculated from d and not d_norm - see paper
        %ordinate = d(i,lag(i)) - 0.25*(d(i,lag(i)-1) - d(i,lag(i)+1))*peak;
    else
        peak = 0;
    end
    %1 needs to be subtracted from 1 due to matlab's indexing nature
    period(i) = (lag(i)-1) + peak;
    f0(i,:) = fs/period(i)*ones(1,win);
    time(i,:) = ((i-1)*win:i*win-1)/fs;
    
end

%for silent frames estimated frequency should be 0Hz
if ~isempty(varargin)
    [f0] = silent_frame_classification(x_frame, f0);
end

f0 = reshape(f0',1,nframes*win);
time = reshape(time',1,nframes*win);

end







