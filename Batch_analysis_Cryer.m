clear; 
clc; 

BG_traces = load('Test_data.mat'); 
BG_values = BG_traces.BG_data; 
[test_no,~] = size(BG_values); 

Eval_data = zeros(test_no, 4); 

for i = 1:test_no
    for j = 1:4
    Eval_data(i,j) = evalGlucose(BG_values(i,:), j); 
    end 
end 
disp(Eval_data)

mean_TIR = mean(Eval_data(:,4)); 
disp(mean_TIR)