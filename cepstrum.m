function [ time, f0 ] = cepstrum(x,fs,varargin)
%use cepstrum method for pitch detection
%based on paper Cepstrum pitch detection
%by A. Michael Noll

%convert column vector to row vector
if(size(x,1) > 2)
    x = x';
    x = x(:,1);
end

%compute blockwise spectrum
win = round(0.04 * fs);
hop = round(0.01 * fs);
N = length(x);
nframes = ceil(N/hop);
%zero pad to make signal have enough samples
x = [x, zeros(1,hop*nframes - N + (win-hop))];
%number of fft bins
nfft = max(1024, 2^nextpow2(win));
ceps = zeros(nframes,nfft);
mat_ceps = zeros(nframes, nfft);
w = hamming(win);
start = 1;
X_log = zeros(1,nfft);

quefreq = (0:nfft-1)/fs;
%by taking quefrequency values between 1-20 ms
%we assume f0 lies in range 50-1000Hz
range = find( quefreq <= 0.02 & quefreq >= 0.001);
q_min = range(1);
q_max = range(end);
ceps_scaled = zeros(nframes, q_max-q_min+1);
%also truncate quefrequency values
quefreq = quefreq(q_min:q_max);

time = zeros(nframes,win);
f0 = zeros(nframes,win);
%this is for silent frame classification
xframes = zeros(nframes, win);

for i = 1:nframes
    x_win = x(start:start+win-1).*w';
    xframes(i,:) = x_win;
    X_psd = abs(fft(x_win,nfft)).^2;
    
    %make sure we don't get a log (0) error
    %get non-zero valued indices
    ind = find(X_psd);
    X_log(ind) = log(X_psd(ind));
    %get zero valued indices
    zero_ind = setdiff(1:nfft,ind);
    if(~isempty(zero_ind))
        X_log(zero_ind) = log(eps);
    end
   
    ceps(i,:) = ifft(X_log, nfft);
    %restrict peak limits to 1-20ms
    ceps_scaled(i,:) = ceps(i,q_min:q_max);
   
    %plot cepstrum
%     if(i == 1)
%     figure(1);
%     mat_ceps(i,:) = cceps(x_win,nfft);
%     plot((0:nfft-1)/fs, ceps(i,:)); grid on;hold on;
%     plot((0:nfft-1)/fs, mat_ceps(i,:), 'r');hold off;
%     xlabel('Quefrequency in seconds');
%     ylabel('Cepstrum');
%     end
    
    f = find_pitch_from_cepstrum(ceps_scaled(i,:), quefreq, 4, fs);
    f0(i,:) = f*ones(1,win);
    time(i,:) = (start-1:start+win-2)/fs;
    %time(i) = (start - 1)/fs;
    start = start + hop;
end

%for silent frames estimated frequency should be 0Hz
if ~isempty(varargin)
    f0 = silent_frame_classification(xframes, f0);
end

f0 = reshape(f0',1,nframes*win);
time = reshape(time',1,nframes*win);
    
end

