%% ==== Load the data as structures ====
BG = load('BG_array.mat'); 
BG_array = BG.blood_glucose; 

BI = load('BI_array.mat'); 
BI_array = BI.blood_insulin; 

%% ==== Initialise parameters ====
ttp = 70; %time to peak after insulin does of average patient

% Extract into individual runs 
control = BG_array(1,:); 

%% ==== Loop for all tests ====

delta_bg = zeros(length(time_delay),1); %store the difference between control and glucagon test
delta_ins = delta_bg;                   %store the blood insulin at the same time (not the difference) 

for i = 1:length(time_delay)

    bg_values = BG_array(i+1,:); 
    bi_values = BI_array(i+1,:);
    current_delay = time_delay(i); 

    peak_time = ins_injection_time + current_delay + ttp; 
    peak_bg = bg_values(1 + (peak_time/T_CGM)); 
    control_bg = control(1 + (peak_time/T_CGM));

    peak_ins = bi_values(1 + peak_time/T_CGM); 
    ins_at_injection = bi_values(1 + (peak_time-ttp)/5); 

    delta_bg(i) = peak_bg - control_bg; 
    delta_ins(i) = ins_at_injection; 

end 

%% ==== Plot the data ====

tiledlayout(2,1)
nexttile
plot(time_delay, delta_bg, '+')
xlabel('time delay (mins)')
ylabel('Blood glucose (mg/dL)')
title('Time offset of injections vs effctiveness')

nexttile
plot(delta_ins, delta_bg, '+')
xlabel('estimated blood insulin (units?)')
ylabel('Blood glucose (mg/dL)')
title('Insulin level in blood vs effectiveness')
hold off 

%% ==== Validation Tests ====
figure 
time = 0:5:1440; 
plot(time, BG_array(1,:))
hold on 
plot(time, BG_array(end,:))
hold off 
%% ==== Trend fitting ====

% remove data point corresponding to glucagon 'beating' insulin to peak
% translate the data to allow for more accurate curve fitting 
delta_bg_clean = delta_bg(2:end) - 72;      % from observing the data 
delta_ins_clean = delta_ins(2:end) - 600;   % from observing the data 

%fit exponential decay 
f = fit(delta_ins_clean, delta_bg_clean, 'exp1'); 
a = f.a; b = f.b;
y = a.*(exp(b.*(delta_ins_clean)));  
plot(delta_ins_clean, delta_bg_clean, '+')
hold on 
plot(delta_ins_clean, y)