function [zohData] = ConvertZOH(t, x, T)
% This function parses a list of time-value pairs (t, x) into a ZOH-like format
% aligned with a given sampling period T. Missing intervals are explicitly set to 0,
% and an extra row with time incremented by T and value 0 is appended at the end.

% Validate inputs
if length(t) ~= length(x)
    error('Inputs t and x must have the same length.');
end
if T <= 0
    error('Sampling period T must be positive.');
end

% Sort inputs by time
[t_sorted, sort_indices] = sort(t);
x_sorted = x(sort_indices);
t_sorted = round(t_sorted./T)*T;

% Determine the range of time
t_start = 0; % ZOH starts counting from 0
t_end = max(t_sorted);

zohData = [0,0];

for data_idx = 1:length(t_sorted)
    zohData = [zohData; [
        t_sorted(data_idx)-1,0;
        t_sorted(data_idx), x_sorted(data_idx)/T;
        t_sorted(data_idx)+T-1, x_sorted(data_idx)/T;
        t_sorted(data_idx)+T, 0
    ]];
end

zohData = [zohData; 5*1440,0];

end
