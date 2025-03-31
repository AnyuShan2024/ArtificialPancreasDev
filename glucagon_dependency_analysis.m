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
delta_ins = delta_bg;                 %store the blood insulin at the same time (not the difference) 

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

tiledlayout(2,1)
nexttile
plot(time_delay, delta_bg)
xlabel('time delay (mins)')
ylabel('Blood glucose (mg/dL)')
title('Time offset of injections vs effctiveness')

nexttile
plot(delta_ins, delta_bg)
xlabel('estimated blood insulin (?)')
ylabel('Blood glucose (mg/dL)')
title('Insulin level in blood vs effectiveness')

