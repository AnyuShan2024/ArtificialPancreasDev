function [fPWL] = ConvertPWL(t, x)
% This function converts a pair of time and value vectors into piece-wise
% linear definition utilized in Simulink

terminate = 1e6;

% Check if they have the same size
if length(t) ~= length(x)
    error('Inputs t and x must have the same length.');
end

% Check if there's any unallowable time point
if sum(t<1)
    error('All time points must be no smaller than 1.');
end

[t_sorted, sort_indices] = sort(t);
x_sorted = x(sort_indices);

xPWL = [];
tPWL = [];

% Log all the data points into PWL vectors
for i = 1:length(t)
    tPWL = [tPWL; [t_sorted(i)-1; t_sorted(i); t_sorted(i)+1]];
    xPWL = [xPWL; [0; x_sorted(i); 0]];
end

% Patch the start and end of the curve
if tPWL(1) ~= 0
    tPWL = [0; tPWL];
    xPWL = [0; xPWL];
end

tPWL = [tPWL; terminate];
xPWL = [xPWL; 0];

fPWL = [tPWL, xPWL];

end

