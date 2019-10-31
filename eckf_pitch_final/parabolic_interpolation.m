function[peak,pos] = parabolic_interpolation(a,b,c)
    %given 3 points, it returns the result of their parabolic interpolation
    pos = 0.5 * ((a-c)/(a - 2*b + c));
    peak = b - 0.25*(a-c)*pos;
end