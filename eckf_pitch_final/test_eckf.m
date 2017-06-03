%test eckf_pitch
close all; clearvars, clc;

%test with actual audio signal
parentpath = '/home/orchisama/Documents/Research/pitch_tracking';
% soundpath = strcat(parentpath,'/Cello.arco.ff.sulC.stereo/');
% filename = 'Cello.arco.ff.sulC.';
% %sound = {'A3.stereo.aif', 'C3.stereo.aif','D3.stereo.aif','G3.stereo.aif'};
% sound = {'A3.stereo.aif', 'Bb3.stereo.aif','E3.stereo.aif','G3.stereo.aif'};
% 
% snd = [];
% len = [];
% for n = 1:length(sound)
%     [x,fs] = audioread(strcat(soundpath, filename, sound{n}));
%     len(n) = length(x);
%     snd = [snd;x(:,1)];
% end

%test with guitar recordings
soundpath = strcat(parentpath, '/GuitarNotes/GuitarNotes/');
%test with cello recordings
%soundpath = strcat(parentpath, '/Chris_Cello/');
filename = 'Slides_2notes.wav';
[snd,fs] = audioread(strcat(soundpath,filename));

%convert from stereo to mono
if(size(snd,2) == 2)
    snd = snd(:,2);
elseif(size(snd,1) == 2)
    snd = snd(1,:);
end
t = (0:length(snd)-1)/fs;
%add noise to signal
snr = 5;
noise = (mean(abs(snd)))*(10^(-snr/20)) * 0.1*randn(1,length(t))';
snd = snd + noise;
%convert to a row vector
if(iscolumn(snd) == 1)
    snd = snd';
end

%ground truth frequency labels
%f = [220*ones(1,len(1)), 233.08 * ones(1,len(2)), 164.81 * ones(1,len(3)), 196 * ones(1,len(4))];
[f0_est,amp,phi1,x_est] = eckf_pitch(snd, fs, 8, 8);
time = (0:length(x_est)-1)/fs;

figure;
%plot(t, f, 'b');grid on; hold on;
subplot(211);plot(time, f0_est, 'r');grid on; hold off;
xlabel('Time');ylabel('Estimated f0 (Hz)');
subplot(212);plot(time, amp);grid on; 
xlabel('Time');ylabel('Estimated amplitude');

%legend('ground truth','eckf estimate');

figure;
subplot(211);
plot(t, snd); grid on; title('Original signal');
subplot(212);
plot(time,real(x_est));grid on; title('Reconstructed fundamental');


