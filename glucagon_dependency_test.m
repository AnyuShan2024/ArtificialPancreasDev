%% ===== Simulator Initialisation =====

model_name = 'SimBG'; 

load_system(model_name);
set_param(model_name, 'FastRestart', 'on');
set_param('SimBG/Controller/Constant1', 'Value', '1' )

% Constants for patient simulation loaded here
W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 120;             % Initial condition for blood glucose level (mg/dL)

%% == Set Test Procedure (to edit) ====

% choose which test to run
test_flag = true;               % no carb input + impulse of insulin and glucagon
control_flag = false;           % input bolus and glucagon data manually
mean_flag = true;               % use mean of all 16 patients for parameters 

time_delay = 30:30:800;         % if test_flag = true, set range of glucagon injection delay times

%% ===== Evaluator, start time, CGM and Safety values =====

% Evaluator settings 
Hypo_Threshold = 70;
Hyper_Threshold = 180;

Hypo_Hyst_L = (Hypo_Threshold-10)/18;
Hypo_Hyst_H = (Hypo_Threshold+10)/18;

Hyper_Hyst_L = (Hyper_Threshold - 10)/18;
Hyper_Hyst_H = (Hyper_Threshold + 10)/18;


% Definition of session time
start_time = datetime(2025, 1, 21, 0, 0, 0); % Format: year, month, day, hour, minute, second
end_time = datetime(2025, 1, 21, 24, 0, 0);  % Example: Same day, different time

% Calculate the duration between the times
t_sim = minutes(end_time - start_time);

T_CGM = 5;              % Sampling period of CGM sensor (min)
sig_n = 10;             % Noise in CGM measurement, assuming Gaussian (mg/dL)

TDD_limit = 0.6*W*1000; % total daily dosage limit, in mU of insulin

%% ===== Generate CHO and patient profile =====

CHO_data = [0,0]; 
dirVP = 'presets\virtual_patients.mat';

if mean_flag == true

    % average patient test
    data = load(dirVP); 
    patient_data = data.param_matrix; 
    num_var = size(patient_data); 
    columns = num_var(2); 

    avg_patient = zeros(1,columns); 

    for i = 1:columns
        avg_patient(i) = mean(patient_data(:,i)); %take the mean values from all 16 patients 
    end 

    baseWrite(avg_patient, data.param_names)      %assign this data to variables in workspace

else 
    % random patient test 
    LoadVP(dirVP)
    k_bi = rand*0.05+0.075;
end 

% Solve for basal insulin required to maintain steady-state blood glucose
G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
U_b0 = fzero(f, 10);

basal_data = [0, U_b0; 1440*5, U_b0];

%% ==== Set controller parameters ====

 T_CTRL = 5;             % Update period of AP controller (min)
            
load("presets\nn_reconstructor.mat");

K_d_ins = 379.0122/ICR -5.8677;
K_p_ins = 0.1;
K_i_ins = 0; 

glucagon_dose = 1e7; 

K_d_glu = 2.484; 
K_p_glu = 0.10976; 
K_i_glu = 0; 



%% ===== Run Control Test =====

% Initialsie arrays to store the test results 
Announcements = zeros(2);
blood_glucose = zeros(length(time_delay)+1, 1+(t_sim/T_CGM)); % extra column to include t=0, extra row for control
blood_insulin = blood_glucose; 

% Set injection times and dosages for control 
ins_injection_time = 400; 
bolus_data = ConvertZOH([ins_injection_time], [10/ICR*1e3], 1); 
glucagon_data = ConvertZOH([1], [0], [1]); 

% Save the data into the array 
simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on'); 
blood_glucose(1,:) = transpose(simOut.get('BG_data'));
blood_insulin(1,:) = transpose(simOut.get('total_insulin')); 

%% ===== Loop for all further tests  =====

for i = 1:length(time_delay)    
    fprintf('=== Running test no. %d ===\n', i);
    
    % Set injections
    ins_injection_time = 400; 
    glu_injection_time = ins_injection_time + time_delay(i); 

    bolus_data = ConvertZOH([ins_injection_time], [10/ICR*1e3], 1); 
    glucagon_data = ConvertZOH([glu_injection_time], [5e7], 1);

    % Run simulation
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');

    % Extract glucose data
    blood_glucose(i+1,:) = transpose(simOut.get('BG_data')); 
    blood_insulin(i+1,:) = transpose(simOut.get('total_insulin')); 

end 

save('BG_array.mat', 'blood_glucose')
save('BI_array.mat', 'blood_insulin')


%% ===== Simulator Wrap-up =====
set_param(model_name, 'FastRestart', 'off');
close_system(model_name, 0);


 %% ===== Auxilary Functions =====

function LoadVP(dir)
% This function reads Virtual Patient Parameters from cohort and load

    data = load(dir);
    param_matrix = data.param_matrix;

    baseWrite(param_matrix(randi(size(param_matrix, 1)),:), data.param_names);
end    