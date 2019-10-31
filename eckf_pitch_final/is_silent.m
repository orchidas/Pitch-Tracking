function [silent, spectral_flatness] = is_silent(x)
%silent frame classification in music 

%method for clean signal - calculate signal energy and see if it is below
%a certain threshold

%method for noisy signals - find PSD of signal, and its spectral flatness
%the assumption is that silent frames have noise only and therefore a flat
%power spectrum

[psdw, w] = pwelch(x); 
%this method works in case the signal isn't noisy.
energy = 20*log10(sum(x.^2));
%the spectral flatness method works only if signal is noisy
spectral_flatness = geomean(psdw)/mean(psdw);

threshold = 0.45;
silent = spectral_flatness >= threshold | energy < -50;
end

