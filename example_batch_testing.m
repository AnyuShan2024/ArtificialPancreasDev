clear;
clc;

%% ===== Simulator Setup =====

model_name = 'SimBG'; % Replace with your actual Simulink model name

load_system(model_name);
set_param(model_name, 'FastRestart', 'on');

control_flag = false;

% Constants for patient simulation is loaded here
W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 120;             % Initial condition for blood glucose level (mg/dL)


%% ===== Loop Setup =====

uncertainty_list = 2:2:40;
loss_list = zeros(length(uncertainty_list), 16);

%% ===== Evaluator Settings =====

Hypo_Threshold = 70;
Hyper_Threshold = 180;

Hypo_Hyst_L = (Hypo_Threshold-10)/18;
Hypo_Hyst_H = (Hypo_Threshold+10)/18;

Hyper_Hyst_L = (Hyper_Threshold - 10)/18;
Hyper_Hyst_H = (Hyper_Threshold + 10)/18;

%% ===== Simulation Setup =====

% Definition of session time

start_time = datetime(2025, 1, 21, 0, 30, 0); % Format: year, month, day, hour, minute, second
end_time = datetime(2025, 1, 26, 0, 30, 0);  % Example: Same day, different time

% Calculate the duration between the times
t_sim = minutes(end_time - start_time);

%% ===== Sensor & Actuator Definition =====

T_CGM = 5;              % Sampling period of CGM sensor (min)
sig_n = 10;             % Noise in CGM measurement, assuming Gaussian (mg/dL)

%% ===== Safety Parameters =====

TDD_limit = 0.6*W*1000; % total daily dosage limit, in mU of insulin

%% ===== Generate CHO Profile =====

% Randomize and construct meal disturbances
[CHO_time, CHO_amount] = DietGen(start_time, end_time);
CHO_data = CHO2PWL(CHO_time, CHO_amount, 4.5);

%% ===== Loop Time =====

for i = 1:length(uncertainty_list)    
    fprintf('=== Investigating uncertainty list index %d ===\n', i);
    % Loop patient-wise
    for j = 1:16
        fprintf('     -> Investigating patient index %d \n', j);
        loss = 0;
        iter_avg = 2;
        for k = 1:iter_avg
            fprintf('         -> Trial %d ...      ', k)
            %% ===== Randomize Announcement =====
            
            % control_flag turns on / off the random meal inputs 
            % prandial flag is related to the bolus data which is disconnected 
            announcement_ratio = 1.0;
            announcement_std = uncertainty_list(i)/100;
            
            % Corrupt CHO amount with announcement error and possibility of
            % unannouced meal.
            Announcement_data = max(0, CHO_amount.*(1+announcement_std*randn(size(CHO_amount))));
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
            
            Announcements = [Announcements; 5 * 1440, 0];
            
            bolus_data = [0, 0; 1e6, 0];
            glucagon_data = [0, 0; 1e6, 0];

            %% ===== Patient Parameters =====
            % Read from virtual patient presets and load
            dirVP = 'presets\virtual_patients.mat';
            LoadVP(dirVP, j);
            
            % The blood-to-interstitial transfer coeffecient is overidden here
            k_bi = rand*0.05+0.075;
            
            % Solve for basal insulin required to maintain steady-state blood glucose
            G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
            f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
            U_b0 = fzero(f, 10);
            
            basal_data = [0, U_b0; 1440*5, U_b0];
            
            %Goal Blood glucose value 
            BG_setpoint = 100; %mg/dL         
            
            %% ===== Controller Parameters =====
            
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
            % Run simulation
            simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
        
            % Extract glucose data (assuming glucose is logged as 'glucose_signal')
            glucose_values = simOut.get('real_bg').Data;
            loss_temp = compute_loss(glucose_values);
            loss = loss + loss_temp;
            fprintf('loss = %.4f \n', loss_temp)
        end
        loss = loss/iter_avg;
        loss_list(i,j) = loss;
        fprintf('     -> Patient %d evaluated: loss = %.4f\n', j, loss);
    end
end

%% ===== Save Results =====
save('loss_list_ng.mat', 'loss_list');
fprintf('loss list saved to loss_list_ng.mat\n');

%% ===== Simulator Wrap-up =====
set_param(model_name, 'FastRestart', 'off');
close_system(model_name, 0);
disp(loss_list);

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
