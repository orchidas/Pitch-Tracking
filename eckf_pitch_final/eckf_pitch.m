function [f0,amp,phi1,x_est] = eckf_pitch(y,fs,c, numBufToWait)

%pitch detector based on the extended complex kalman filter
%y - incoming noisy signal (row vector) 
%fs - sampling rate
%f0 - estimated pitch
%c - parameter for determining process noise
%numBufToWait - number of buffers to wait after note onset - this will vary
%from instrument to instrument, depending on how strong its attack is
%amp - estimated amplitude of fundamental
%phi - estimated phase of fundamental
%x_est - estimated fundamental component of signal

%steps
%1. break signal into frames of 25 ms
%2. detect if frame is silent
%3. if frame is not silent :
%4. if previous frame was silent, reset covariance
%   matrix and calculate initial estimates
%5. calculate frequency, amplitude and phase estimates for non-silent frame using ECKF

flength = round(0.025*fs);
nframes = ceil(length(y)/flength);
y = [y, zeros(1,nframes*flength - length(y))];

Ts = 1/fs;
H =[0,0.5,-0.5];

%Kalman filter variables
K = zeros(3,1);
flag = -1;
Kthres = 0.01;
x_est = zeros(1,length(y));
amp = zeros(1,length(y));
phase = zeros(1,length(y));
Q = zeros(1,length(y));
f0 = zeros(1,length(y));
start = 1;
n = 1;
%state of current frame - initially silent
cur_frame = 1;

while(start + flength - 1 < length(y))
    y_frame = y(start:start+flength-1);
    prev_frame = cur_frame;
    cur_frame = is_silent(y_frame);
    silent_inds = 1;
    
    %if current frame is silent, then continue
    if(cur_frame == 1)
        flag = 0;
        start = start + flength;
        n = start;
        continue;
        
    %transition from non-silent to silent frame
    elseif(prev_frame == 1 && cur_frame == 0)
        %start counting buffers
        count = 0;
        %wait for a few frames before doing analysis to ignore 'attack'
        %of an instrument where frequencies go haywire
        while(count < numBufToWait)
            count = count+1;
            start = start + flength;
        end
        if(start + flength - 1 < length(y))
            y_frame = y(start:start+flength-1);
            flag = 1;
            n = start;
        else
            break;
        end
    end
        
         
    %reset covariance matrix and calculate initial states
    if(flag == 1)
        silent_inds = amp_follower(y_frame, 1);
        %if there are very few samples remaining in the rest of the frame,
        %then we should mark the frame as silent and proceed to the next frame
        if(flength - silent_inds(end) < (fs/100))
            start = start + flength;
            n = start;
            flag = 0;
            cur_frame = 1;
            continue;
        end 
	
        %calculate initial state by taking an FFT and detecting the first peak
        n = n + silent_inds(end) + 1;
        ybuf = y_frame(silent_inds(end):end);
        minf = length(ybuf);
        nfft = 2^nextpow2(4*minf);
        fbins = linspace(-fs/2,fs/2,nfft+1);
        win = blackman(minf);
        ybuf = (ybuf - mean(ybuf)).* win';
        Y = fftshift(fft(ybuf, nfft));
        %considering minimum possible frequency to be 50Hz, we ignore all
        %bins that are below 50Hz. Number of bins below 50Hz = 50/(fs/2*nfft)
        nbins_below50 = round(50/(fs/2*nfft));
        Y = Y(nfft/2 + nbins_below50:end); 
        fbins = fbins(nfft/2 + 1 + nbins_below50:end);
        mag = abs(Y)./mean(win);
        phase = angle(Y);
        %take the least frequency peak to be fundamental, ignore harmonics
        [m, mpos] = findpeaks(mag);
        [val, ind] = sort(m, 'descend');
        %we assume that fundamental is the minimum of largest peaks' frequency
        mpos = min(mpos(ind(val > 0.5*max(val))));  
        [a1,ppos] = parabolic_interpolation(mag(mpos-1),mag(mpos),mag(mpos+1));
        a1 = a1/nfft;
        f1 = fbins(mpos) + (ppos * fs/nfft);
        [phi1,pos] = parabolic_interpolation(phase(mpos-1),phase(mpos),phase(mpos+1));
        x0 = [exp(1i*2*pi*f1*Ts);a1*exp(1i*2*pi*f1*n*Ts + 1i*phi1);...
            a1*exp(-1i*2*pi*f1*n*Ts - 1i*phi1)];
        P0 = 0;
        %P0 = abs(y_frame(silent_inds(end)+1) - H*x0);
        
        %uncomment to plot estimated states
        figure;
        set(gca, 'fontsize', 14);
        hold on
        subplot(211);plot(fbins, mag);grid on;hold on;
        plot(f1,a1*nfft,'k*');hold off;
        ylabel('Magnitude spectrum');xlabel('Frequency in Hz');
        subplot(212);plot(fbins,unwrap(phase));grid on;   
        ylabel('Phase spectrum');xlabel('Frequency in Hz');

        %reset covariance matrix
        if(abs(min(K)) < Kthres)
            sprintf('Covariance matrix reset at time %d seconds', (n-1)/fs)
            P_last = P0;
            x_last = x0;
            flag = 0;
        end
    end
    
    for k = silent_inds(end)+1:flength
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
        phase(n) = -1i * (log(x(2)/amp(n))-(2*pi*(1i)*f0(n)*Ts*n));
        x_est(n) = H*x;

        P_last = P_next;
        x_last = x_next;
        n = n + 1;
    end
    start = start + flength;
end

end

