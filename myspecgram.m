function myspecgram (x, fs, frameSize, hopSize, fftSize)

% function myspecgram (x, fs, frameSize, hopSize, fftSize)
% A function to plot the spectrogram of an input signal x
% using the Hann window
% x: input signal (row or column vector) - assume real
% fs: sampling rate of x
% frameSize: frame size (in samples) = window length (make it odd)
% hopSize: time between start-times of successive windows (in samples)
% fftSize: sets the zero-padding factor - defaults to length(x)
% Orchisama Das

N = length(x);
if(frameSize > N)
    error('Frame size has to be lesser than signal length');
end
if(hopSize > frameSize)
    error('Hop size cannot be greater than frame size');
end

%make sure window size is odd
if(mod(frameSize,2) == 0)
    frameSize = frameSize+1;
end
    
%convert fftSize to power of 2 
fftSize = 2^nextpow2(fftSize);

%find number of frames
nframes = ceil(N/hopSize);


%zero pad input signal so that it has nframes exactly
x = [x zeros(1,nframes*hopSize - N + (frameSize - hopSize))]; 

x_frames = zeros(nframes, frameSize);
X = zeros(nframes, fftSize);
start = 1;
win = hann(frameSize);

for frame = 1:nframes
    x_frames(frame, :) = x(start:start+frameSize - 1) .* win';
    start = start + hopSize;
    X(frame, :) = abs(fftshift(fft(x_frames(frame,:), fftSize)));
end

%normalise 
X = X/max(max(X));
%convert to dB
X = 20*log10(X);
%clip to -60 dB
X(find(X<-60)) = -60;
%truncate X to keep posiive frequencies only
X = X(:,fftSize/2+1:end);

%label time and frequency axes
t = [0 N/fs];
f = [0 fs/2];

%plot spectrogram
%figure();
%we can ignore the last frame because it only contains zeros because of our
%earlier zero padding
imagesc(t,f,X(1:end-1,:)');
set(gca,'YDir','normal');
xlabel('Time in seconds');
ylabel('Frequency in Hz');
colormap default;


%print parameters
sprintf('Printing Parameters \nFrame Size :%d \nHop Size:%d \nFFT Size:%d', frameSize, hopSize, fftSize)
end

