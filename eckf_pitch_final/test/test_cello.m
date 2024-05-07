%test eckf_pitch
close all; clear all; clc;

%test with actual audio signal
parentpath = '/Users/orchisamadas/Documents/Research/pitch_tracking';

%test with concatenated cell notes
soundpath = strcat(parentpath,'/Cello.arco.ff.sulC.stereo/');
filename = 'Cello.arco.ff.sulC.';
%sound = {'A3.stereo.aif', 'C3.stereo.aif','D3.stereo.aif','G3.stereo.aif'};
sound = {'A3.stereo.aif', 'Bb3.stereo.aif','E3.stereo.aif','G3.stereo.aif'};

snd = [];
len = [];
for n = 1:length(sound)
    [x,fs] = audioread(strcat(soundpath, filename, sound{n}));
    len(n) = length(x);
    snd = [snd;x(:,1)];
end

%add noise to signal
snr = 5;
noise = (mean(abs(snd)))*(10^(-snr/20)) * 0.1*randn(1,length(t))';
snd = snd + noise;
%convert to a row vector
if(iscolumn(snd) == 1)
    snd = snd';
end
snd = snd-mean(snd);

%ground truth frequency labels
f = [220*ones(1,len(1)), 233.08 * ones(1,len(2)), 164.81 * ones(1,len(3)), 196 * ones(1,len(4))];

%kalman pitch estimator
[f0_est,amp,phi,x_est] = eckf_pitch(snd, fs, 2048, 8, 2); 

%yin estimator output
[time_yin, f0_est_yin] = yin_estimator(snd',fs);

figure;
plot((0:length(f0)-1)/fs,f0,'b');grid on;hold on;
plot(time,f0_est_com,'r');grid on;hold on;
plot(time_yin, f0_est_yin,'m');grid on; hold off;
%plot(time, f0_est_med,'m');grid on;hold on;
%plot(time, f0_est_bt);grid on;hold on;
xlabel('time in seconds');
ylabel('Estimated frequency in Hz');
axis([0 20 0 500]);
legend('ground truth','ekf estimate', 'yin estimate');
%legend('ground truth','ekf estimate w/o med filt','ekf estimate with med filt',...
%    'ekf estimate with backtracking');
