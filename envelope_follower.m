function [silent_indices] = envelope_follower(x)
%amplitude envelope tracker for data x

%Envelope Detection based on Hilbert Transform 
analy=hilbert(x);
env=abs(analy);
%applying moving average filter to further smooth envelope
M = 10;
b = 1/M * ones(1,M);
a = 1;
env = filter(b,a,env);
%find signal indices with very low value of amplitude envelope
n = find(abs(env) < 0.1*max(abs(env)));
silent_indices = [];
if(~isempty(n))
    %there needs to be a consecutive array of silent indices. We will ignore single values that 
    %dip in amplitude, because they are most likely caused by computational errors. Consecutively 10
    %or more values need to be below the threshold for region to be silent.

    %the following lines find the longest sequence of consecutive numbers
    %in array n - genius solution I found on stack overflow
    temp = [0 cumsum(diff(n)~=1)];
    elems = n(temp==mode(temp));

    %silent regions can only be at the beginning or end of frame, not in the
    %middle. The number of indices belonging to silent frames has to be
    %greater than 10
    if(numel(elems) >= 10)
        N = length(x);
        if(max(elems) < N/2)
            silent_indices = 1:max(elems);
        else
            silent_indices = min(elems):N;
        end
    end

%     figure;
%     plot(x,'b');hold on;
%     plot(env,'r');hold on;
%     plot(silent_indices,env(silent_indices),'k*');hold off;
%     grid on;
end

end

