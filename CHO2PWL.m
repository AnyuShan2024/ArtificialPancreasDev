function CHO_data = CHO2PWL(CHO_time, CHO_amount, intake_rate)
    % CHOtoPWL: Converts CHO intake impulses into a rectangular wave
    %           and generates a piecewise linear vector for Simulink.
    %
    % INPUTS:
    %   CHO_time   - vector of meal start times
    %   CHO_amount - vector of carbohydrate intake amounts (grams)
    %   intake_rate - intake rate (grams/min)
    %
    % OUTPUT:
    %   CHO_data - piecewise linear (PWL) formatted data for Simulink

    if length(CHO_time) ~= length(CHO_amount)
        error('CHO_time and CHO_amount must have the same length.');
    end
    
    meal_durations = CHO_amount ./ intake_rate; % Compute meal duration (minutes)

    % Generate time and intake level vectors for rectangular wave
    t_expanded = [];
    x_expanded = [];

    for i = 1:length(CHO_time)
        t_start = CHO_time(i);
        t_end = t_start + meal_durations(i);

        % Append time points for step-wise meal representation
        t_expanded = [t_expanded; t_start-1; t_start; t_end; t_end+1]; % Meal starts and ends
        x_expanded = [x_expanded; 0; intake_rate; intake_rate; 0]; % Intake rate, then drop to zero
    end

    % Ensure 0 intake before the first meal and after the last meal
    if ~isempty(t_expanded)
        t_expanded = [0; t_expanded; t_expanded(end) + 1e6]; % Large end time
        x_expanded = [0; x_expanded; 0]; % Ensure zero before and after intake
    end

    % Convert to PWL format
    CHO_data = [t_expanded, x_expanded];
end
