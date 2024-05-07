function [f0,amp,phase,x_est,onset_pos] = eckf_pitch_modified(y, fs, blockSize, c, numBufToWait, npeaks, nsemitones, plot_flag)

%Pitch tracker based on the extended complex kalman filter
%INPUTS:
%y - incoming noisy signal (row vector) 
%fs - sampling rate
%f0 - estimated pitch
%c - parameter for determining process noise
%numBufToWait - number of buffers to wait after note onset - this will vary
%from instrument to instrument, depending on how strong its attack is
%nsemitones - number of semitones of pitch change to occur for a new note
%to be detected
%plot_flag - boolean to determine if results are to be plotted
%OUTPUTS:
%amp - estimated amplitude of fundamental
%phi - estimated phase of fundamental
%x_est - estimated fundamental component of signal
%onset_pos - position of note onsets (in seconds)

%steps
%1. break signal into frames of 25 ms
%2. detect if frame is silent
%3. if frame is not silent :
%4. if previous frame was silent, reset covariance
%   matrix and calculate initial estimates
%5. calculate frequency, amplitude and phase estimates for non-silent frame using ECKF

if nargin < 7
    nsemitones = 2;
    plot_flag = 0;
elseif nargin < 8
    plot_flag = 0;
end

nframes = ceil(length(y)/blockSize);
y = [y, zeros(1,nframes*blockSize - length(y))];
blocks = 1;
onset_pos = [];

Ts = 1/fs;
H =[0,0.5,0.5];

%Kalman filter variables
K = zeros(3,1);
flag = -1;
Kthres = 0.01;
x_est = zeros(1,length(y));
amp = zeros(1,length(y));
phase = zeros(1,length(y));
Q = zeros(1,length(y));
f0 = zeros(1,length(y));
P_track = zeros(1, length(y));
K_track = zeros(1, length(y));
n = 1;
start_pos = 1;
%state of current frame - initially silent
silent_cur = 1;
harm_prev = 0;
spf = [];

while blocks <= nframes

    end_pos = start_pos + blockSize - 1;
    if(end_pos >= length(y))
        break;
    end
    y_frame = y(start_pos:start_pos + blockSize - 1);
    
    %detect if current frame is silent
    silent_prev = silent_cur;
    [silent_cur, cur_spf] = is_silent(y_frame);
    spf = [spf;cur_spf];
    %if current frame is silent, then continue
    if(silent_cur == 1)
        flag = 0;
        start_pos = start_pos+blockSize;
        n = start_pos;
        continue;
    else
    
        %detect harmonic change (note change)
        if (start_pos > blockSize)
            y_prev = y(start_pos-blockSize:start_pos-1);
        else
            y_prev = [];
        end
        harm_cur = harmonic_change_detector(y_prev.',y_frame.',fs,npeaks,0,nsemitones);
        
        %transition from non-silent to silent frame or note change
        if ((silent_prev == 1 && silent_cur == 0) || (harm_prev == 0 && harm_cur == 1))
            onset_pos = [onset_pos, start_pos];
            %start counting buffers
            count = 0;
            %wait for a few frames before doing analysis to ignore 'attack'
            %of an instrument where frequencies go haywire
            while(count < numBufToWait)
                count = count+1;
                start_pos = start_pos+blockSize;
            end
            
            if(start_pos + blockSize  < length(y))
                y_frame = y(start_pos:start_pos+blockSize-1);
                if(n>1)
                    f0(n:start_pos) = f0(n-1);
                    amp(n:start_pos) = amp(n-1);
                    phase(n:start_pos) = phase(n-1);
                end
                flag = 1;
                n = start_pos;
            else
                break;
            end
        end
    end
                
    %reset covariance matrix and calculate initial states
    if(flag == 1)
        if (start_pos > blockSize)
            y_prev = y(start_pos-blockSize:start_pos-1);
        else
            y_prev = [];
        end
        %iniitial estimates
        [harm_cur, f1, a1, phi1] = harmonic_change_detector(y_prev.',y_frame.',fs,npeaks,0,nsemitones);      
        x0 = [exp(1i*2*pi*f1*Ts);a1*exp(1i*2*pi*f1*n*Ts + 1i*phi1);...
            a1*exp(-1i*2*pi*f1*n*Ts - 1i*phi1)];
        P0 = 0;
                      
        % plot estimated states
        if plot_flag
            figure;
            set(gca, 'fontsize', 14);
            hold on
            subplot(211);plot(fbins, mag);grid on;hold on;
            plot(f1,a1*nfft,'k*');hold off;
            ylabel('Magnitude spectrum');xlabel('Frequency in Hz');
            subplot(212);plot(fbins,unwrap(phi));grid on;   
            ylabel('Phase spectrum');xlabel('Frequency in Hz');
        end

        %reset covariance matrix
        if(abs(min(K)) < Kthres)
            sprintf('Covariance matrix reset at time %d seconds', (n-1)/fs)
            P_last = P0;
            x_last = x0;
            flag = 0;
            %backwards filtering - this demands a look-ahead of
            %numBuffersToWait
            start_pos = start_pos - count*blockSize;
            n = start_pos;
        end
    end
    
    for k = 1:blockSize
        %ekf equations
        K = (P_last*H')/(H*P_last*H' + 1);
        P = P_last - K*H*P_last;
        x = x_last + K*(y_frame(k) - H*x_last);
        x_next = [x(1);x(1)*x(2);x(3)/x(1)];
        F = [1,0,0;x(2),x(1),0;-x(3)/(x(1)^2),0,1/x(1)];
        %adaptive process noise based on error 
        Q(n) = 10^-(c-(abs(y_frame(k) - H*x)));
        P_next = F*P*F' + Q(n)*eye(3);
        f0(n) = abs(log(x(1))/(1j*Ts*2*pi));
        amp(n) = abs(x(2));
        phase(n) = abs(-1i * (log(x(2)/amp(n))-(2*pi*f0(n)*Ts*n)));
        x_est(n) = H*x;

        P_last = P_next;
        x_last = x_next;
        P_track(n) = norm(P);
        K_track(n) = norm(K);
        n = n + 1;
    end
    start_pos = start_pos + blockSize;
    harm_prev = harm_cur;
end

%% for plotting

if plot_flag
    figure;
    time = 0:1/fs:(length(y)-1)/fs;
    yL = max(abs(y));
    subplot(311);
    plot(time, y);hold on;
    for i = 1:length(onset_pos)
        line([onset_pos(i) onset_pos(i)]/fs,[-yL,yL],'Color','k','LineStyle','--');
    end
    title('Original signal');
    subplot(312);
    plot(time, P_track(1:length(y)));
    title('Error covariance matrix');
    subplot(313);
    plot(time, K_track(1:length(y)));
    title('Kalman gain');

    fig = figure('Units','inches', 'Position',[0 0 3.25 2.1],'PaperPositionMode','auto');
    set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
    plot(1:length(spf), spf);grid on;
    xlim([1,length(spf)]);
    ylabel('Spectral flatness');
    xlabel('Frame number');
    set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
end

end

