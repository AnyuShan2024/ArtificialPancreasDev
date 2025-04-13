%% Loading the tested data
L1 = load('loss_list.mat').loss_list;
L2 = load('loss_list_ng.mat').loss_list;

uncertainty_list = 2:2:40;

%% Plotting the patient characteristics

line_width = 2;  % Handle to configure line width

% 16 Harmonized color sets (marker, line)
color_sets = load("presets\color_sets_16.mat").color_sets_16;

figure
for patient_number = 1:16
    subplot(4, 4, patient_number)
    hold on

    c1 = color_sets{patient_number, 1};  % marker
    c2 = color_sets{patient_number, 2};  % line

    % Plot L1 with filled circle markers
    plot(uncertainty_list, L1(:, patient_number), 'o', ...
         'Color', c1, 'MarkerFaceColor', c1)

    grid on

    title(sprintf('Patient %d', patient_number))
    hold off
end

%% Plotting the population graph

% Compute percentiles for L1
L1_p25 = prctile(L1, 25, 2);
L1_p75 = prctile(L1, 75, 2);
L1_med = prctile(L1, 50, 2);

% Compute percentiles for L2
L2_p25 = prctile(L2, 25, 2);
L2_p75 = prctile(L2, 75, 2);
L2_med = prctile(L2, 50, 2);

% Color scheme (muted tones)
L1_fill = [192 128 128]/255;   % Soft red
L1_line = [120 60 60]/255;     % Dull maroon

L2_fill = [128 160 200]/255;   % Steel blue
L2_line = [70 100 130]/255;    % Cool navy-gray

figure
hold on

% Fill shaded area for L1 (25th to 75th percentile)
fill([uncertainty_list, fliplr(uncertainty_list)], ...
     [L1_p25', fliplr(L1_p75')], ...
     L1_fill, ...
     'FaceAlpha', 0.2, ...
     'EdgeColor', 'none');

% Fill shaded area for L2
fill([uncertainty_list, fliplr(uncertainty_list)], ...
     [L2_p25', fliplr(L2_p75')], ...
     L2_fill, ...
     'FaceAlpha', 0.2, ...
     'EdgeColor', 'none');

% Plot median lines
plot(uncertainty_list, L1_med, '-', 'Color', L1_line, 'LineWidth', 2)
plot(uncertainty_list, L2_med, '-', 'Color', L2_line, 'LineWidth', 2)

grid on
xlabel('Uncertainty')
ylabel('Loss')
legend('Dual-Hormone System', 'Single-Hormone System')

hold off
