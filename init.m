% ===== Patient Parameters =====

W = 70;                 % Body weigh of patient (kg)
M_g = 180.16;           % Molecular weight of glucose (g mol^{-1})
G_GNG = 6;              % Glucose production due to gluconeogenesis (umol/kg/min)
BG_0 = 100;             % Initial condition for blood glucose level (mg/dL)
sig_n = 10;             % Noise in CGM measurement, assuming Gaussian (mg/dL)

% ===== Random Patient Generation =====

% Use rejection sampling to make sure the difference of EGP (basal) and
% F_01 is within biologically plausible range

while true
    randomizeVP()
    G_GG0 = C_b/(C_b+C_E50)*(E_max-G_GNG);

    % Solving basal insulin to maintain BG initial condition (mU min^{-1})
    f = @(x) -F_01 - x/(k_e*V_I*W)*S_T*(1-k_12/(k_12+x/(k_e*V_I*W)*S_D))*(BG_0*V_G/18)+G_GG0+G_GNG;
    U_b0 = fzero(f, 10);            

    if G_GG0>6 && 1.5<G_GG0+G_GNG-F_01 && G_GG0+G_GNG-F_01<3.5 && U_b0 > 5 && U_b0 < 20
        break
    end
end

% ===== Input Definition =====

% insulin dosage are all given in mU
basal_data = [0, U_b0; 1440*5, U_b0];
bolus_data = [0, 0; 119, 0; 120, 2e3; 121, 0; 1440*5, 0];

% glucagon dosage are all given in pg
glucagon_data = [0, 0; 359, 0; 360, 1e8; 361, 0; 1440*5, 0];

% CHO intake are defined in grams of glucose intake
CHO_data = [0, 0; 119, 0; 120, 40; 121, 0; 1440*5, 0];
