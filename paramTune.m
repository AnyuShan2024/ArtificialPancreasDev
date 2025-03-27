function best_params = paramTune(model_name, param_names, param_bounds)
    % Optimize multiple Simulink parameters using Genetic Algorithm (GA) with Fast Restart
    %
    % Inputs:
    %   model_name  - Simulink model name (string)
    %   param_names - Cell array of parameter names (strings)
    %   param_bounds - Matrix [lower_bounds; upper_bounds] (size: 2 x num_params)
    %
    % Output:
    %   best_params - Optimized parameter values

    % Load Simulink model and enable Fast Restart
    load_system(model_name);
    set_param(model_name, 'FastRestart', 'on');

    % Define cost function
    cost_function = @(params) loss_evaluate(model_name, param_names, params);

    % Set optimization options
    options = optimoptions('ga', 'Display', 'iter', 'PopulationSize', 20);

    % Run Genetic Algorithm optimizer
    num_params = length(param_names);
    best_params = ga(cost_function, num_params, [], [], [], [], ...
                     param_bounds(1, :), param_bounds(2, :), [], options);

    % Disable Fast Restart and close model
    set_param(model_name, 'FastRestart', 'off');
    close_system(model_name, 0);

    fprintf('Optimal parameters: %s = %s\n', strjoin(param_names, ', '), mat2str(best_params));
end


function loss = loss_evaluate(model_name, param_names, param_values)
    % Runs Simulink with multiple parameters and computes LBGI + HBGI loss
    %
    % Inputs:
    %   model_name  - Simulink model name
    %   param_names - Cell array of parameter names in Simulink
    %   param_values - Vector of parameter values
    %
    % Output:
    %   loss - LBGI + HBGI loss value

    % Set each parameter in Simulink
    baseWrite(param_values, param_names)

    % Run simulation
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');

    % Extract glucose data (assuming glucose is logged as 'glucose_signal')
    glucose_values = simOut.get('real_bg').Data;

    % Compute LBGI + HBGI loss
    loss = compute_loss(glucose_values);
end

function loss = compute_loss(glucose_values)
    % Step 1: Remove invalid glucose values
    valid_glucose = glucose_values(~isnan(glucose_values) & glucose_values > 0);
    
    if isempty(valid_glucose)
        warning('All glucose values are invalid! Returning NaN loss.');
        loss = NaN;
        return;
    end

    % Step 2: Define penalty weights
    alpha = 1;  % Weight for mild hypoglycemia penalty
    beta = 5/6;   % Weight for mild hyperglycemia penalty

    % Step 3: Compute penalties for each valid glucose value
    hypo_penalty = alpha * (max(70 - valid_glucose, 0)).^2;
    hyper_penalty = beta * max(valid_glucose - 180, 0);

    % Step 4: Compute mean loss
    loss = mean(hypo_penalty + hyper_penalty);
end