%test pitch tracker on triangle wave with vibrato
fs = 44100;
t = 0:1/fs:2-1/fs;
f0 = 440;
fm = 5;
am = 5;

x = sawtooth(2*pi*f0*t+(am*sin(2*pi*fm*t)));
f0_corr = f0 + am*fm*cos(2*pi*fm*t);

snr = [5,10,15,20,25];
% snr = [5];
mse = zeros(length(snr),1);
var = zeros(length(snr),1);

for i = 1:length(snr)
    xn = awgn(x, snr(i),'measured');
    [time_yin, f0_yin] = yin_estimator(xn,fs);
    [f0_est,amp,phi,x_est,onset_pos] = eckf_pitch_modified(xn, fs, 1024, 10, 3, 5);
    time_eckf = (0:length(x_est)-1)/fs;
    
    fig = figure('Units','inches', 'Position',[0 0 3.25 2.1],'PaperPositionMode','auto');
    set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
    plot(t,f0_corr,'r--','Linewidth',1.3);hold on; grid on;
    plot(t, f0_est(1:length(t)),'k'); hold off;
    ylim([400,490]);
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
    print('../figures/saw_wave.eps', '-depsc');
    
    err = f0_est(1:length(t)) - f0_corr;
    mse(i) = mean(abs(err));
    var(i) = std(err);
    
end

figure;
plot(snr,mse);

