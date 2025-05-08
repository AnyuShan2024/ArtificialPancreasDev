clear; 
clc; 

BG_traces = load('Test_data.mat'); 
BG_values = BG_traces.BG_data; 
[test_no,~] = size(BG_values); 

TIR = zeros(test_no,1); 

for i = 1:test_no
    TIR(i) = evalGlucose(BG_values(i,:), 4); %4 selects TIR evaluation
end 
disp(TIR)