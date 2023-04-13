%test eckf_pitch
close all; clear all; clc;

%test with actual audio signal
parentpath = '/Users/orchisamadas/Documents/Research/pitch_tracking';

% %test with guitar recordings from Mark
soundpath = strcat(parentpath, '/GuitarNotes/');
filename = 'Trill_high_1note_2.wav';

% %test with double-bass recordings from Chris
% soundpath = strcat(parentpath, '/DoubleBass/more_bass/');
% filename = 'descend_fast_1.wav';
% filename = 'D2Eb_trill.wav';

[snd,fs] = audioread(strcat(soundpath,filename));
%convert from stereo to mono
if(size(snd,2) == 2)
    snd = snd(:,2);
elseif(size(snd,1) == 2)
    snd = snd(1,:);
end

t = (0:length(snd)-1)/fs;
%only required for spectrogram plotting
% extra_t = round((3.68-t(end))*fs);
% snd = [snd;zeros(extra_t,1)];
% t = (0:length(snd)-1)/fs;


%add noise to signal
snr = 5;
noise = (mean(abs(snd)))*(10^(-snr/20)) * 0.1*randn(1,length(t))';
snd = snd + noise;
%convert to a row vector
if(iscolumn(snd) == 1)
    snd = snd';
end
snd = snd-mean(snd);

%kalman pitch tracker - double bass
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 11, 1, 6); %-descend
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 11, 2, 6); %-descend_fast
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 1024, 11, 3, 5); %-descend_faster
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 11, 2, 5); %-celleto


%double bass - ornaments
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 10, 2, 6); %-portamento
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 10, 3, 6); %-vibrato
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 9, 1, 6); %-vibrato trill
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 9, 2, 5);%-trill

%guitar - ornaments
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 1024, 9, 2, 3); %-hammer
[f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 9, 2, 2, 0.25); %-trill
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 8, 2, 2); %-vibrato
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 9, 2, 3); %-slide

time = (0:length(x_est)-1)/fs;


%yin tracker
[time_yin, f0_yin] = yin_estimator(snd,fs);


%crepe tracker
crepe_filename = strcat(filename(1:end-3), 'f0.csv');
crepe = readtable(strcat(soundpath,crepe_filename));
time_crepe = crepe.time;
f0_crepe = crepe.frequency;


%% plot
yL = 450;
fig = figure('Units','inches', 'Position',[0 0 3.25 2.1],'PaperPositionMode','auto');
set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
plot(time_yin, f0_yin,'--','Linewidth',0.8);grid on;hold on;
plot(time_crepe, f0_crepe,'.','Markersize',5);grid on;
plot(time, f0_est,'k','Linewidth',0.6);grid on; hold on;
% for i = 1:length(onset_pos)
%     line([onset_pos(i) onset_pos(i)]/fs,[0,yL],'Color','k','LineStyle','--');
% end

hold off;
xlabel('Time');ylabel('Estimated f0 (Hz)');
ylim([300,yL]);
xlim([0,time(end)+0.2]);
legend('yin','crepe','ekf');
set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
print(strcat('../figures/',filename(1:end-4),'_crepe.eps'), '-depsc');

% figure;
% subplot(121);plot(time, amp);grid on; 
% xlabel('Time');ylabel('Estimated amplitude');
% subplot(122);plot(time,(phi));grid on;
% xlabel('Time');ylabel('Estimated phase in radians (unwrapped)');

% figure;
% subplot(211);
% plot(t, snd); grid on; title('Original signal');
% subplot(212);
% plot(time,real(x_est));grid on; title('Reconstructed fundamental');

% myspecgram(snd,fs,8096,2048,2^15);hold on;
% xL = 3.68;
% fig = figure('Units','inches', 'Position',[0 0 3.25 2.1],'PaperPositionMode','auto');
% set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
% myspecgram(snd,fs,2^13,2^10,2^15);hold on;
% plot(time,f0_est,'k','LineWidth',1.2);hold off;
% ylim([0,yL]);
% xlim([0,xL]);
% set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
% print(strcat('../figures/',filename(1:end-4),'_spectrogram.eps'), '-depsc');


