% Parameters
num_samples = 16;
param_matrix = []; % Initialize matrix to store valid parameter sets
output_folder = 'presets'; % Output folder for saving .mat file

% Ensure the output folder exists
if ~isfolder(output_folder)
    mkdir(output_folder);
end

progress = 1;

% Sampling loop
while progress <= num_samples
    % Step 1: Sample from the distribution
    
    while true
        [params, ~] = randomizeVP();
        G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
    
        % Solving basal insulin to maintain BG initial condition (mU min^{-1})
        f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
        U_b0 = fzero(f, 10);            

        if G_GG0>6 && 1.5<G_GG0+G_GNG-F_01 && G_GG0+G_GNG-F_01<3.5 && U_b0 > 5 && U_b0 < 20
            break
        end
    end

    basal_data = [0, U_b0; 1440*5, U_b0];

    % Step 2: Display parameters for manual inspection
    user_input = input('Accept this parameter set? (y/n): ', 's');
    
    % Step 3: Log parameter set if accepted
    if strcmpi(user_input, 'y')
        param_matrix = [param_matrix; params];
        disp('Parameter set accepted.');
        progress = progress + 1;
    else
        disp('Parameter set rejected.');
    end
end

% Step 4: Save the matrix as a .mat file
output_file = fullfile(output_folder, 'virtual_patients.mat');
save(output_file, 'param_matrix');

disp(['Parameter matrix saved to ', output_file]);
