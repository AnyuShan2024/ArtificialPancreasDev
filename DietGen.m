function [time_vector, CHO_vector] = DietGen(start_time, end_time)
% The distribution of diet is adapted from Garry et. al (2006)

% Initialize output vectors
relative_times = [];
meal_amounts = [];

% Loop through each day in the range
current_date = dateshift(start_time, 'start', 'day'); % Get thwee first day's start
while current_date <= end_time
    % Generate meal pattern for the current day (example function call)
    [meal_times, meal_amounts_day] = generate_meal_pattern();
    
    % Adjust meal times relative to the overall start_time
    time_offset = minutes(current_date - start_time); % Offset in minutes from start_time
    relative_meal_times = meal_times + time_offset;
    
    % Append results to the output vectors
    relative_times = [relative_times; relative_meal_times];
    meal_amounts = [meal_amounts; meal_amounts_day];
    
    % Move to the next day
    current_date = current_date + days(1);
end

% round the meal times and exclude entries smaller than relative time 1
relative_times = round(relative_times);

valid_indices = (relative_times >= 1) & (relative_times < minutes(end_time - start_time));
time_vector = relative_times(valid_indices);
CHO_vector = meal_amounts(valid_indices);
end

function [meal_times, meal_amounts] = generate_meal_pattern()
    % Generate random meal times
    meal_times = [8; 13; 18; 22]*60; % Times in minutes from midnight (8 AM, 1 PM, 6 PM, 10PM)
    meal_times = meal_times + randn(length(meal_times), 1)*10; % Add variability to meal time

    % Generate randome meal amounts
    meal_amounts = [
        87.9 + 11.5*randn; 
        69.0 + 8.8*randn; 
        45.3 + 7.7*randn;
        55.1 + 8.4*randn
    ];   % Corresponding meal amounts (grams of carbs, etc.)
end


% Reference:
% Garry M. Steil, Kerstin Rebrin, Christine Darwin, Farzam Hariri, 
% Mohammed F. Saad; Feasibility of Automating Insulin Delivery for the 
% Treatment of Type 1 Diabetes. Diabetes 1 December 2006; 55 (12): 3344–3350. 
% https://doi.org/10.2337/db06-0419