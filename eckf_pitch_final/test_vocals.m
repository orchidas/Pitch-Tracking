%% read audio file

parentpath = '/Users/orchisamadas/Documents/Research/pitch_tracking';
soundpath = strcat(parentpath, '/VocalSet/FULL/female2/excerpts/vibrato/');
filename = 'f2_row_vibrato.wav';

[snd,fs] = audioread(strcat(soundpath,filename));
%convert from stereo to mono
if(size(snd,2) == 2)
    snd = snd(:,2);
elseif(size(snd,1) == 2)
    snd = snd(1,:);
elseif(size(snd,2) == 1)
    snd = snd';
end

%% eckf pitch tracker
% [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(snd, fs, 2048, 7, 2, 3, 2);
[f0_est,amp,phi,x_est] = eckf_pitch(snd,fs,7,2);
time = (0:length(x_est)-1)/fs;

%% yin tracker
[time_yin, f0_yin] = yin_estimator(snd,fs);

%% crepe tracker
crepe_filename = strcat(filename(1:end-3), 'f0.csv');
crepe = readtable(strcat(soundpath,crepe_filename));
time_crepe = crepe.time;
f0_crepe = crepe.frequency;

%% plot

yL = 800;
fig = figure('Units','inches', 'Position',[0 0 6.5 2.3],'PaperPositionMode','auto');
set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
plot(time_yin, f0_yin,'s','Markersize',1);grid on;hold on;
plot(time_crepe, f0_crepe,'d','Markersize',1);grid on;
plot(time, f0_est,'k.','Markersize',0.1);grid on; hold on;
% for i = 1:length(onset_pos)
%     line([onset_pos(i) onset_pos(i)]/fs,[0,yL],'Color','k','LineStyle','--');
% end

hold off;
xlabel('Time');ylabel('Estimated f0 (Hz)');
ylim([0,yL]);
xlim([0,time(end)+0.2]);
% legend('yin','crepe','ekf');
set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
% print(strcat('../figures/',filename(1:end-4),'_crepe.eps'), '-depsc');


