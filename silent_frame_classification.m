function [ f0 ] = silent_frame_classification(xframes, f0)

%silent frame classification in music based on signal energy/spectral flatness
%xframes - signal divided into buffers/frames
%f0 - frequencies (one for each frame)

%this method works great for non-noisy signals but fails otherwise
nframes = size(xframes,1);
N = size(xframes,2);

%this method works for noisy signals - find PSD of signal, and its spectral flatness
%the assumption is that silent frames have only noise and therefore a flat
%power spectrum

spectral_flatness = zeros(1,nframes);
energy = zeros(1,nframes);

for i = 1:nframes
    [psdw, w] = pwelch(xframes(i,:)); 
    %this method works in case the signal isn't noisy.
    energy(i) = 20*log10(sum(xframes(i,:).^2));
    %the spectral flatness method works only if signal is noisy
    spectral_flatness(i) = geomean(psdw)/mean(psdw);
end

norm_spec_flatness = spectral_flatness./max(spectral_flatness);
threshold = 0.9;
silent = norm_spec_flatness >= threshold | energy < -50;

s = find(silent == 1);
for i = 1:length(s)
    f0(s(i),:) = zeros(1,N);
end

figure;
set(gca, 'fontsize', 14);
hold on
plot(spectral_flatness);grid on;
xlabel('Frame number');
ylabel('Spectral flatness');
%print('/home/orchisama/Documents/MATLAB/pitch_tracking/DAFx 2017/dafx17/my_paper/spf','-deps');

%make sure that partially silent frames are taken into account

for i = 2:nframes-1
    %voiced frame preceded or followed by silent frame
    if(silent(i) == 0 && silent(i-1) == 1) 
        %returns signal indices with very low amplitude
        ind = envelope_follower(xframes(i,:),1);
        f0(i,ind) = zeros(1,length(ind));
    elseif(silent(i) == 0 && silent(i+1) == 1)
        ind = envelope_follower(xframes(i,:),0);
        f0(i,ind) = zeros(1,length(ind)); 
    end
end
    
end


