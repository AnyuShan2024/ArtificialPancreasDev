function best_params = paramTune(model_name, param_names, param_bounds)
    % Optimize multiple Simulink parameters using Bayesian Optimization (noise-robust)
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

    % Create optimizable variables
    num_params = length(param_names);
    opt_vars = optimizableVariable.empty;
    max_evals = 500;

    for i = 1:num_params
        opt_vars(i) = optimizableVariable(param_names{i}, ...
            [param_bounds(1, i), param_bounds(2, i)]);
    end

    % Define the Bayesian optimization objective
    objective = @(x) wrapper_loss(model_name, param_names, x);

    % Run Bayesian optimization
    results = bayesopt(objective, opt_vars, ...
        'IsObjectiveDeterministic', false, ...
        'MaxObjectiveEvaluations', 50, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'Verbose', 1, ...
        'MaxObjectiveEvaluations', max_evals, ...
        'PlotFcn', {@plotObjectiveModel});

    % Extract the best parameters
    bestTable = results.XAtMinObjective;
    best_params = zeros(1, num_params);
    for i = 1:num_params
        best_params(i) = bestTable.(param_names{i});
    end

    % Disable Fast Restart and close model
    set_param(model_name, 'FastRestart', 'off');
    close_system(model_name, 0);

    fprintf('Optimal parameters: %s = %s\n', strjoin(param_names, ', '), mat2str(best_params));
end

function loss = wrapper_loss(model_name, param_names, param_table)
    % Convert param_table to vector
    num_params = length(param_names);
    param_values = zeros(1, num_params);
    for i = 1:num_params
        param_values(i) = param_table.(param_names{i});
    end

    % Evaluate the loss
    loss = loss_evaluate(model_name, param_names, param_values);
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

    loss = 0;

    for i = 1:1
        % Set each parameter in Simulink
        evalin('base', 'init')
        baseWrite(param_values, param_names)
    
        % Run simulation
        simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
    
        % Extract glucose data (assuming glucose is logged as 'glucose_signal')
        glucose_values = simOut.get('real_bg').Data;
    
        % Compute LBGI + HBGI loss
        loss = loss + compute_loss(glucose_values);
    end
end