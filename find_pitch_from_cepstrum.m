function[f0] = find_pitch_from_cepstrum(ceps,quefreq,npeaks,fs)
%this function will find npeaks peaks and their position
%in the ceps array

    %peaks are those values that are greater than their next and
    %previous neighbours
    allPeaks = [];
    indPos = [];
    k = 1;
    for i=2:length(ceps)-1
        if(ceps(i) >= ceps(i-1) && ceps(i) >= ceps(i+1))
            allPeaks(k) = ceps(i);
            indPos(k) = i;
            k = k+1;
        end
    end
    
    [ceps_sorted, qi] = sort(allPeaks,'descend');
    qi = indPos(qi);
    npeaks = min(npeaks, length(qi));
    qi = sort(qi(1:npeaks));
    peakpos = 1./quefreq(qi);
    peaks = ceps(qi);
    
    %quadratic interpolation
    for i = 2:npeaks-1
        a = ceps(qi(i)-1);
        b = ceps(qi(i));
        c = ceps(qi(i)+1);
        p = 0.5*((a-c)/(a+c-2*b));
        peaks(i) = b - (0.25*(a-c)*p);
        peakpos(i) = 1/(quefreq(qi(i)) + p/fs);
    end
    
    [m,i] = max(peaks);
    f0 = peakpos(i);
    
%     figure(2);
%     stem(peakpos, peaks);grid on;
%     xlabel('Frequency in Hz');
%     ylabel('Peak amplitude');
    
end