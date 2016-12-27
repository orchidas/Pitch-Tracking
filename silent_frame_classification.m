function [ f0 ] = silent_frame_classification(xframes, f0)
%silent frame classification in music based on signal energy
%this works quite well for non-noisy signal, cross-checked with
%visual inspection in audacity

%this method works great for non-noisy signals but fails otherwise
nframes = size(xframes,1);
N = size(xframes,2);

%method for noisy signals - find PSD of signal, and its spectral flatness
%the assumption is that silent frames have noise only and therefore a flat
%power spectrum
spectral_flatness = zeros(1,nframes);
energy = zeros(1,nframes);
for i = 1:nframes
    psd = fftshift(abs(fft(xframes(i,:))).^2);
    psd = psd(round(length(psd)/2):end);
    %using parseval's theorem to get signal energy from PSD
    %this method works in case the signal isn't noisy.
    energy(i) = 20*log10(sum(psd)/length(psd));
    %the spectral flatness method works only if signal is noisy
    spectral_flatness(i) = geomean(psd)/mean(psd);
end
norm_spec_flatness = spectral_flatness./max(spectral_flatness);
threshold = 0.7;
silent = norm_spec_flatness >= threshold | energy < -60;
s = find(silent == 1);
for i = 1:length(s)
    f0(s(i),:) = zeros(1,N);
end

%make sure that partially silent frames are taken into account
for i = 2:nframes-1
    %voiced frame preceded or followed by silent frame
    if(silent(i) == 0 && silent(i-1) == 1 || silent(i) == 0 && silent(i+1) == 1)
        %returns signal indices with very low amplitude
        ind = envelope_follower(xframes(i,:));
        f0(i,ind) = zeros(1,length(ind));
    end
end
    
end


