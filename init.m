% clear;
% clc;
test = 10;

%% ===== Simulation Setup =====

% Definition of session time

start_time = datetime(2025, 1, 21, 0, 30, 0); % Format: year, month, day, hour, minute, second
end_time = datetime(2025, 1, 22, 0, 30, 0);  % Example: Same day, different time

% Calculate the duration between the times
t_sim = minutes(end_time - start_time);

%% ===== Sensor & Actuator Definition =====

T_CGM = 5;              % Sampling period of CGM sensor (min)
sig_n = 10;             % Noise in CGM measurement, assuming Gaussian (mg/dL)

%% ===== Patient Parameters =====

% Constants for patient simulation is loaded here
W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 120;             % Initial condition for blood glucose level (mg/dL)
K_clear = 0.0143;       % Insulin clearance coefficient  

% Read from virtual patient presets and load
dirVP = 'presets\virtual_patients.mat';
LoadVP(dirVP);

% The blood-to-interstitial transfer coeffecient is overidden here
k_bi = rand*0.05+0.075;

% Solve for basal insulin required to maintain steady-state blood glucose
G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
U_b0 = fzero(f, 10);

basal_data = [0, U_b0; 1440*5, U_b0];

%Goal Blood glucose value 
BG_setpoint = 100; %mg/dL 

%% ===== Safety Parameters =====

TDD_limit = 0.6*W*1000; % total daily dosage limit, in mU of insulin


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

m_prep = 20;



%% ===== Input Definition =====

% control_flag turns on / off the random meal inputs 
% prandial flag is related to the bolus data which is disconnected 
control_flag = false;
announcement_ratio = 0.8;
control_flag = false;
announcement_ratio = 0.5;
announcement_std = 3;
meal_prep_flag = true;

%========== Pharmokinetics test run: =============================
test_flag = false;

meal_prep = [0, 0; 1e6, 0];

if test_flag == true
    
    set_param('SimBG/Controller/Constant1', 'Value', '1' )
    t_sim = 1800; 
    ins_injection_time = 400; 
    glu_injection_time = 700; 
    
    bolus_data = ConvertZOH([ins_injection_time], [10/ICR*1e3], 1); 
    glucagon_data = ConvertZOH([glu_injection_time], [5e7], 1); 
    CHO_data = [0,0]; 
    Announcements = zeros(2); 

      % patients
    data = load(dirVP); 
    patient_data = data.param_matrix; 
    num_var = size(patient_data); 
    columns = num_var(2); 

    avg_patient = zeros(1,columns); 

    for i = 1:columns
        avg_patient(i) = mean(patient_data(:,i)); %take the mean values from all 16 patients 
    end 

baseWrite(avg_patient, data.param_names)          %assign this data to variables in workspace

% Solve for basal insulin required to maintain steady-state blood glucose
G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);
f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
U_b0 = fzero(f, 10);

basal_data = [0, U_b0; 1440*5, U_b0];
%=================================================================

elseif control_flag == true
    t_sim = 1800;

    % insulin dosage are all given in mU
    % 
    bolus_data = ConvertZOH([120], [80/ICR*1e3], T_CTRL);
    
    % glucagon dosage are all given in pg
    glucagon_data = ConvertZOH([480], [5e7],T_CTRL);
    
    % CHO intake are defined in grams of glucose intake
    CHO_data = CHO2PWL([120], [80], 4.5);

    Announcements = [0, 0; 1e6, 0];
else
    % Randomize and construct meal disturbances
    [CHO_time, CHO_amount] = DietGen(start_time, end_time);
    CHO_data = CHO2PWL(CHO_time, CHO_amount, 4.5);

    % Corrupt CHO amount with announcement error and possibility of
    % unannouced meal.
    %Announcement_data = max(0, CHO_amount+announcement_std*randn(size(CHO_amount)));
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

    Announcements = [Announcements; 5 * 1440, 0];

    if meal_prep_flag
        meal_prep = [0, 0];

        meal_prep_time = Announcement_time - 5*randi(6, length(Announcement_time), 1);
        for meal_idx = 1:length(meal_prep_time)
            meal_prep = [meal_prep; [
                meal_prep_time(meal_idx)-1, 0;
                meal_prep_time(meal_idx), 1;
                meal_prep_time(meal_idx)+4, 1;
                meal_prep_time(meal_idx)+5, 0;
            ]];
        end

        meal_prep = [meal_prep; 5 * 1440, 0];
    end

    bolus_data = [0, 0; 1e6, 0];
    glucagon_data = [0, 0; 1e6, 0];
end

%% ===== Evaluator Settings =====

Hypo_Threshold = 70;
Hyper_Threshold = 180;

Hypo_Hyst_L = (Hypo_Threshold-10)/18;
Hypo_Hyst_H = (Hypo_Threshold+10)/18;

Hyper_Hyst_L = (Hyper_Threshold - 10)/18;
Hyper_Hyst_H = (Hyper_Threshold + 10)/18;

%% ===== Auxilary Functions =====

function LoadVP(dir)
% This function reads Virtual Patient Parameters from cohort and load

    data = load(dir);
    param_matrix = data.param_matrix;

    baseWrite(param_matrix(randi(size(param_matrix, 1)),:), data.param_names);
end
