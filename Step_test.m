test_flag = true;

if test_flag == true
   
    BG_0 = 120; 
    BG_1 = 140; 
    meal_prep = [0, 0; 1e6, 0];
    set_param('SimBG/Controller/Constant1', 'Value', '2' )
    t_sim = 1800; 
    ins_injection_time = t_sim - 1; 
    glu_injection_time = t_sim - 1; 
    step_time = 200; 
    
    bolus_data = ConvertZOH([ins_injection_time], [0.0001/ICR*1e3], 1); 
    glucagon_data = ConvertZOH([glu_injection_time], [0.0001], 1); 
    CHO_data = [0,0]; 
    Announcements = zeros(2); 
    
    reference_time = [0;step_time-1;step_time;t_sim]; 
    reference_sig = [BG_0;BG_0;BG_1;BG_1]; 
    reference_tseries = [reference_time, reference_sig]; 

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
K_d = 379.0122/ICR -5.8677;

end 