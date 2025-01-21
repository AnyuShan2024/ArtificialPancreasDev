%% ===== Patient Parameters =====

% Constants for patient simulation is loaded here
W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 100;             % Initial condition for blood glucose level (mg/dL)
sig_n = 10;             % Noise in CGM measurement, assuming Gaussian (mg/dL)

% Read from virtual patient presets and load
dirVP = 'presets\virtual_patients.mat';
LoadVP(dirVP);

% Solve for basal insulin required to maintain steady-state blood glucose
G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
U_b0 = fzero(f, 10);

basal_data = [0, U_b0; 1440*5, U_b0];

% ===== Input Definition =====

% insulin dosage are all given in mU
bolus_data = [0, 0; 119, 0; 120, 2e3; 121, 0; 1440*5, 0];

% glucagon dosage are all given in pg
glucagon_data = [0, 0; 359, 0; 360, 1e8; 361, 0; 1440*5, 0];

% CHO intake are defined in grams of glucose intake
CHO_data = [0, 0; 119, 0; 120, 40; 121, 0; 1440*5, 0];

function LoadVP(dir)
% This function reads Virtual Patient Parameters from cohort and load

    data = load(dir);
    param_matrix = data.param_matrix;

    baseWrite(param_matrix(randi(size(param_matrix, 1)),:), data.param_names);
end
