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

% Determine the range of time
t_start = 0; % ZOH starts counting from 0
t_end = max(t_sorted);

% Generate ZOH-aligned time points
zohTimes = t_start:T:t_end; % ZOH time points
zohValues = zeros(size(zohTimes)); % Initialize ZOH values to 0

% Process each T-interval
for i = 1:length(zohTimes)
    % Define the current T-interval
    t_start_interval = zohTimes(i);
    t_end_interval = t_start_interval + T;
    
    % Find indices of t_sorted within this interval
    indices = find(t_sorted >= t_start_interval & t_sorted < t_end_interval);
    
    % Sum the corresponding x values for this interval
    if ~isempty(indices)
        zohValues(i) = sum(x_sorted(indices));
    else
        zohValues(i) = 0; % Explicitly set to 0 if no values exist
    end
end

% Append an extra row with time incremented by T and value 0
zohTimes = [zohTimes, zohTimes(end) + T, zohTimes(end) + 2*T];
zohValues = [zohValues, 0, 0];

% Combine ZOH times and values into output matrix
zohData = [zohTimes', zohValues'/T];

end
