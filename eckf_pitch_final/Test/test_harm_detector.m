clear all, 
close all;
[x,fs] = audioread('../../Chris_Cello/more_cello/descend_faster_1.wav');

sig = x(:,2);
time = 0:1/fs:(length(x)-1)/fs;
%add noise to signal
snr = 5;
noise = (mean(abs(sig)))*(10^(-snr/20)) * 0.1*randn(1,length(time))';
sig = sig + noise;
yL =[-max(abs(sig)), max(abs(sig))];

blockSize = 1024;
blocks = 1;
numOfBlocks = ceil(length(sig)/blockSize);
flag_prev = 0;
note_change_pos = [];
figure(2);
xlim([0, max(time)]);
plot(time,sig);grid on;
ylim(yL);hold on;
signal_prev= [];
f0 = [];

while blocks <= numOfBlocks

    start_pos = (blocks-1)*blockSize+1;
    end_pos = start_pos + blockSize - 1;
    if(end_pos >= length(sig))
        break;
    end
    signal = sig(start_pos : end_pos);
    silent = is_silent(signal);
    if ~silent
        [flag_cur f0_est] = harmonic_change_detector(signal_prev,signal,fs,3,1); %- descend_fast
        %[flag_cur f0_est] = harmonic_change_detector(signal_prev,signal,fs,6);% - descend
        
        %if there is a note change
        if(flag_prev == 0 && flag_cur == 1)
            f0 = [f0, f0_est];
            note_change_pos = [note_change_pos, start_pos/fs];
            figure(2);
            line([start_pos start_pos]/fs,yL,'Color','k','LineStyle','--');
            hold on;
        end
        signal_prev = signal;
        flag_prev = flag_cur;
    end
  
    blocks = blocks + 1;
end

figure(2);hold off;
