clear; 
%% ===== Simulator Setup =====

model_name = 'SimBG'; % Replace with your actual Simulink model name

load_system(model_name);
set_param(model_name, 'FastRestart', 'on');

% Constants for patient simulation is loaded here
W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 120;             % Initial condition for blood glucose level (mg/dL)

m_prep = 20;
meal_prep = [0, 0; 1e6, 0];
K_clear = 0.0143;       % Insulin clearance coefficient  

%% ===== Simulation Setup =====

% Definition of session time

start_time = datetime(2025, 1, 21, 0, 30, 0); % Format: year, month, day, hour, minute, second
end_time = datetime(2025, 1, 28, 0, 30, 0);  % Example: Same day, different time

% Calculate the duration between the times
t_sim = minutes(end_time - start_time);
T_CGM = 5;                                  %sampling period    
sig_n = 10;                                 %variance in CGM noise

control_flag = false; 
meal_prep_flag = true;

%% ===== Loop Setup ====== 
n_patients = 16; 
BG_data = zeros(n_patients, t_sim./T_CGM + 1); 
%BG_data will store each BG trace together. The time will increase along
%the columns, and the patient will be indexed by the row number - the test
%can by multiple days long rather than repeating the 1 day test. 
%% ===== Evaluator Settings =====

Hypo_Threshold = 70;
Hyper_Threshold = 180;

Hypo_Hyst_L = (Hypo_Threshold-10)/18;
Hypo_Hyst_H = (Hypo_Threshold+10)/18;

Hyper_Hyst_L = (Hyper_Threshold - 10)/18;
Hyper_Hyst_H = (Hyper_Threshold + 10)/18;

%% ===== Safety Parameters =====

TDD_limit = 0.6*W*1000; % total daily dosage limit, in mU of insulin

%% ===== Loop over each patient, and run with both controllers =====

[CHO_time, CHO_amount] = DietGen(start_time, end_time);
CHO_data = CHO2PWL(CHO_time, CHO_amount, 4.5);
%produce corresponding announcements for carb input (with variance)
announcement_ratio = 0.8;
announcement_std = 3;
Announcement_data = max(0, CHO_amount.*(1+0.26*randn(size(CHO_amount))));

Announcement_mask = rand(size(Announcement_data))<announcement_ratio;
Announcement_data = Announcement_data(Announcement_mask);

Announcement_time = round(CHO_time ./ 5) .* 5;
Announcement_time = Announcement_time(Announcement_mask);
Announcements = [0, 0];

for meal_idx = 1:length(Announcement_time)
    Announcements = [Announcements; [
        Announcement_time(meal_idx)-1, 0;
        Announcement_time(meal_idx), Announcement_data(meal_idx);
        Announcement_time(meal_idx)+4, Announcement_data(meal_idx);
        Announcement_time(meal_idx)+5, 0;
    ]];
end

Announcements = [Announcements; 10 * 1440, 0];
bolus_data = [0, 0; 1e6, 0];
glucagon_data = [0, 0; 1e6, 0];

for i = 1:n_patients
    fprintf('     -> Investigating patient index %d \n', i);
     % Read from virtual patient presets and load
        dirVP = 'presets\virtual_patients.mat';
        LoadVP(dirVP, i);   %i is the patient index
        
        % The blood-to-interstitial transfer coeffecient is overidden here
        k_bi = rand*0.05+0.075;
        
        % Solve for basal insulin required to maintain steady-state blood glucose
        G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
        f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
        U_b0 = fzero(f, 10);
        
        basal_data = [0, U_b0; 1440*5, U_b0];
        BG_setpoint = 120; %mg/dL

%% ===== Configure the controller parameters based on patient ===== %% 
        
        set_param('SimBG/Controller/Constant1', 'Value', '3')
        T_CTRL = 5;             % Update period of AP controller (min)
            
        load("presets\nn_reconstructor.mat");
        
        K_d_ins = 379.0122/ICR -5.8677;
        K_p_ins = 0.1;
        K_i_ins = 0; 
        
        glucagon_dose = 1e7; 
        
        K_d_glu = 2.484; 
        K_p_glu = 0.10976; 
        K_i_glu = 0;
    
%% ===== Run Simulation =====
        
        simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on'); 
        glucose_values = simOut.get('real_bg').Data; 
        BG_data(i,:) = glucose_values; 
end 

%% ===== Save Results ===== 
save('Test_data.mat', 'BG_data') 
disp('test data saved to Test_data')

%% ===== Close Simulator ===== 
set_param(model_name, 'FastRestart', 'off');
close_system(model_name, 0);
disp(BG_data); 

%% ===== Auxilary Functions =====

function LoadVP(dir, patient_idx)
% This function reads Virtual Patient Parameters from cohort and load

    data = load(dir);
    param_matrix = data.param_matrix;

    if patient_idx == 0
        patient_idx = randi(size(param_matrix, 1));
    end

    baseWrite(param_matrix(patient_idx,:), data.param_names);
end

