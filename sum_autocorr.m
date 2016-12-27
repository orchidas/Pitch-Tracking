function [val] = sum_autocorr(rcorr, N, P)
%calculates a part of the cost function in maximum
%likelihood estimator
if(N < 2 || isnan(N) || isinf(N))
    val = 0;
else
    %the following loops were taking forever to execute
%     phi = zeros(1,N-1);
%     for l = 1:N-1
%         for j = 0 : K0-1-l*P
%             phi(l) = phi(l) + r(j+1)*r(j+1+floor(l*P));
%         end
%     end
%     val = sum(phi);

    l = 1:N-1;
    phi = rcorr(floor(l.*P));
    val = sum(phi);
end

end

