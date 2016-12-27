%matlab script to combine n audio files together

close all, clc;

parentpath = fileparts(pwd);
soundpath = strcat(parentpath,'/Cello.arco.ff.sulC.stereo/');

filename = 'Cello.arco.ff.sulC.';
sound = {'A3.stereo.aif', 'C3.stereo.aif','D3.stereo.aif','Gb2.stereo.aif'};

snd = [];
len = [];
for n = 1:length(sound)
    [x,fs] = audioread(strcat(soundpath, filename, sound{n}));
    len(n) = length(x);
    snd = [snd;x(:,1)];
end

f = [220*ones(1,len(1)), 130.81 * ones(1,len(2)), 146.83 * ones(1,len(3)), 92.5 * ones(1,len(4))];

%check which parts are silent
flength = round(0.025*fs);
nframes = ceil(length(snd)/flength);
snd = [snd; zeros(nframes*flength - length(snd), 1)];
f = [f, zeros(1,nframes*flength - length(f))];
f0 = zeros(nframes,flength);
snd_frames = zeros(nframes, flength);
start = 1;

for i = 1:nframes
    snd_frames(i,:) = snd(start:start + flength - 1);
    f0(i,:) = f(start) * ones(1,flength);
    start = start+flength;
end
f0 = silent_frame_classification(snd_frames,f0);
f0 = reshape(f0',1,nframes*flength);

     
%create ground truth labels
t = (0:length(snd)-1)/fs;
%add noise of a particular snr to signal
snr = 5;
noise = (mean(abs(snd)))*(10^(-snr/20)) * 0.1*randn(1,length(t))';
%snd = snd + noise;
%soundsc(snd, fs);


[time_yin, f0_est_yin] = yin_estimator(snd',fs, 'use_classification');
[time_ceps, f0_est_ceps] = cepstrum(snd',fs, 'use_classification');
[time_ml, f0_est_ml] = max_likelihood(snd',fs,'use_classification');

figure;
plot(time_yin, f0_est_yin);grid on;hold on;
plot(time_ceps, f0_est_ceps);grid on; hold on;
plot(time_ml, f0_est_ml);grid on;hold on;
plot((0:length(f0)-1)/fs, f0);grid on; hold off;
axis([0 length(snd)/fs 0 1000]);
xlabel('time in seconds');ylabel('Frequency in Hz');
legend('Estimated f0 - yin','Estimated f0 - cepstrum','Estimated f0 - max likelihood','Ground truth');
