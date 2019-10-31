function [flag_cur,f0_est,amp,phase] = harmonic_change_detector(xprev,xcur,fs,npeaks,show,nsemitones)
%on a frame by frame basis detects if there is a harmonic change,i.e,
%a note change

%these variables either need to be stored/ calculated just once
persistent  minf nfft fbins win nbins_below50 exp_win

if isempty(fbins)
    minf = length(xcur);
    nfft = 2^nextpow2(4*(minf+1));
    fbins = linspace(-fs/2,fs/2,nfft);
    win = blackman(minf);
    %considering minimum possible frequency to be 50Hz, we ignore all
    %bins that are below 50Hz. Number of bins below 50Hz = 50/(fs/2*nfft)
    nbins_below50 = round(50/(fs/2*nfft));
    fbins = fbins(nfft/2 + nbins_below50:end);
    exp_win = poisson_window(length(fbins), 5);
end

xcur = (xcur - mean(xcur)).* win;
X = fftshift(fft(xcur, nfft));
X = X(nfft/2 + nbins_below50:end); 
mag_cur = (abs(X)./mean(win)) .* exp_win;


%find npeaks largest peaks in current buffer FFT
[pval_cur, ppos_cur] = findpeaks(mag_cur);%,'NPeaks',10);
[pval_cur_sort, ind] = sort(pval_cur,'descend'); %sort by magnitude
ind = sort(ind(1:npeaks)); %sort by frequency - first 10 peaks
pval_cur_sort = pval_cur(ind); %first npeaks of sorted 10 peaks
ppos_cur_sort = ppos_cur(ind);
fpeaks_cur = fbins(ppos_cur_sort);

%find f0, amplitude and phase
phi = angle(X);
mpos = ppos_cur_sort(1);
[amp,pos] = parabolic_interpolation(mag_cur(mpos-1),mag_cur(mpos),mag_cur(mpos+1));
amp = amp/nfft;
% f0_est = fpeaks_cur(1);
f0_est = mode(round(diff(fpeaks_cur)));
% f0_est = fbins(mpos) + (pos * fs/nfft);
[phase,pos] = parabolic_interpolation(phi(mpos-1),phi(mpos),phi(mpos+1));

if ~isempty(xprev)
    xprev = (xprev-mean(xprev)).*win;
    X_prev = fftshift(fft(xprev, nfft));
    X_prev = X_prev(nfft/2 + nbins_below50:end); 
    mag_prev = (abs(X_prev)./mean(win)) .* exp_win;

    [pval_prev, ppos_prev] = findpeaks(mag_prev);%,'NPeaks',10);
    [pval_prev_sort, ind] = sort(pval_prev,'descend'); %sort by magnitude
    ind = sort(ind(1:npeaks)); %sort by frequency - first 10 peaks
    pval_prev_sort = pval_prev(ind); %first npeaks of sorted 10 peaks
    ppos_prev_sort = ppos_prev(ind);
    fpeaks_prev = fbins(ppos_prev_sort);

    %pitch deviation in cents
    [n,c] = hist(abs(diff(fpeaks_cur) - diff(fpeaks_prev)),100);
    [mx,ix]=max(n,[],'omitnan'); %find mode of histogram
    cent_dev = 1200*log2(f0_est/(f0_est+c(ix)));
%     f0_cur = mode(round(diff(fpeaks_cur)));
%     f0_prev = mode(round(diff(fpeaks_prev)));
%     cent_dev = 1200*log2(f0_cur/f0_prev);
%     cent_dev = 1200*log2(fpeaks_cur./fpeaks_prev);
%     cent_dev = sqrt(mean(cent_dev.^2));
    
    %pitch deviation greater than a semitone
    if(abs(cent_dev) >= nsemitones*100) 
        flag_cur = 1;
        if (show == 1)
        fig = figure('Units','inches', 'Position',[0 0 6.75 2.3],'PaperPositionMode','auto');
        set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
        subplot(1,2,1);
        plot(fbins,mag_cur);hold on;grid on;
        plot(fbins,mag_prev,'r--');hold on;
        plot(fpeaks_cur,pval_cur_sort,'bx');hold on;
        plot(fpeaks_prev,pval_prev_sort,'rx');hold off;
        xlim([0, max([fpeaks_cur,fpeaks_prev])+50]);
        xlabel('Frequency(Hz)');
        ylabel('Magnitude(dB)');
        set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
        subplot(1,2,2);
        hist(abs(diff(fpeaks_cur) - diff(fpeaks_prev)),50);
        xlabel('Frequency deviation in Hz');
        ylabel('Number of peaks'); 
        set(gca, 'FontUnits','points', 'FontWeight','normal', 'FontSize',8, 'FontName','Times');
        end
    else 
        flag_cur = 0;
    end
else
    flag_cur = 0;
end
end


function w = poisson_window (M, alpha)
    w = exp(-0.5*alpha*(0:M-1)./(M-1))';
end
