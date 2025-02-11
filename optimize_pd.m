% Define Simulink model name
model_name = 'SimBG'; % Replace with your actual Simulink model name

% Define the parameters to optimize
param_names = {'K_d', 'K_p'}; % Two parameters for tuning

% Define the lower and upper bounds for each parameter
param_bounds = [0, 0;  % Lower bounds (gd, gp)
                20,  1];   % Upper bounds (gd, gp)

% Run the Genetic Algorithm optimizer
optimal_params = paramTune(model_name, param_names, param_bounds);

% Display the results
fprintf('Optimal gd: %.4f\n', optimal_params(1));
fprintf('Optimal gp: %.4f\n', optimal_params(2));
