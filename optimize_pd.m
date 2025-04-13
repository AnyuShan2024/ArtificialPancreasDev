% Define Simulink model name
model_name = 'SimBG'; % Replace with your actual Simulink model name

% Define the parameters to optimize
param_names = {'K_d_glu', 'K_p_glu'}; % Two parameters for tuning

% Define the lower and upper bounds for each parameter
param_bounds = [0, 0;  % Lower bounds (gd, gp)
                10,  10];   % Upper bounds (gd, gp)

% Run the Genetic Algorithm optimizer
optimal_params = paramTune(model_name, param_names, param_bounds);

% Display the results
fprintf('Optimal gd: %.4f\n', optimal_params(1));
fprintf('Optimal gp: %.4f\n', optimal_params(2));
