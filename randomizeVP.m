function [values, names] = randomizeVP()
    [values_glucagon, names_glucagon] = glucagonEstim(false);
    [values_insulin, names_insulin] = insulinEstim();
    % 
    baseWrite(values_glucagon, names_glucagon)
    baseWrite(values_insulin, names_insulin)

    values = [values_glucagon, values_insulin];
    names = [names_glucagon, names_insulin];
end

function [values, names] = glucagonEstim(dispFlag)
    % Estimated model parameter by Wendt et al
    % The parameters in columns are:
    %   C_b (pg/ml)
    %   k_1 (1/min)
    %   k_2 (1/min)
    %   Cl_FC (ml/kg/min)
    %   t_max (min)
    %   C_E50 (pg/ml)
    %   E_max (umol/kg/min)
    
    % Parameter names
    params = {'C_b', 'k_1', 'k_2', 'CL_FC', 't_max', 'C_E50', 'E_max', 'S_E', 'k_a3'};
    
    % Parameter data
    data = [
        10.7, 0.042, 0.14, 94, 12.2, 436, 56.4, 155e-4, 215e-4;
        7.6, 0.056, 0.26, 106, 7.5, 405, 67.4, 334e-4, 231e-4;
        7.6, 0.022, 0.10, 114, 19.1, 401, 57.4, 237e-4, 327e-4;
        10.9, 0.058, 0.058, 159, 17.3, 285, 84.4, 415e-4, 68e-4;
        8.7, 0.038, 0.19, 200, 10.7, 339, 65.4, 229e-4, 235e-4;
        8.9, 0.035, 0.28, 125, 8.6, 424, 60.1, 404e-4, 74e-4;
        11.6, 0.035, 0.25, 136, 9.2, 141, 78, 140e-4, 178e-4;
        19.0, 0.052, 0.090, 91, 14.5, 307, 75.3, 463e-4, 154e-4
    ];

    if dispFlag
        % Number of variables
        numVars = size(data, 2);
        
        % Plot histograms and perform normality tests
        for i = 1:numVars
            subplot(3, 3, i); % Adjust layout for 7 variables
            histogram(data(:, i), 'Normalization', 'pdf', 'NumBins', 10); % Plot histogram with probability density
            hold on;
            % Fit a log-normal distribution
            logData = log(data(:, i)); % Log-transform the data
            pd = fitdist(logData, 'Normal'); % Fit a normal distribution to the log-transformed data
            x = linspace(min(data(:, i)), max(data(:, i)), 100);
            y = pdf(pd, log(x)) ./ x; % Adjust PDF to original scale
            plot(x, y, 'r', 'LineWidth', 2); % Overlay log-normal distribution
            title(['Variable ' num2str(i)]);
            xlabel('Value');
            ylabel('Density');
            hold off;
            
            % Kolmogorov-Smirnov Test
            [h_kstest, p_kstest] = kstest((log(data(:, i)) - mean(log(data(:, i)))) / std(log(data(:, i)))); % Test log-normality
            if h_kstest == 0
                disp(['Variable ', num2str(i), ': KS Test p-value = ', num2str(p_kstest), ' (Log-normality not rejected).']);
            else
                disp(['Variable ', num2str(i), ': KS Test p-value = ', num2str(p_kstest), ' (Log-normality rejected).']);
            end
        end
    end

    % Compute mean and covariance in log-space
    logData = log(data);         % Transform data to log scale
    logMeanVector = mean(logData); % Mean in log-space
    logCovMatrix = cov(logData);  % Covariance matrix in log-space

    logSample = mvnrnd(logMeanVector, logCovMatrix); % Sample in log-space
    values = exp(logSample); % Transform back to original scale
    names = params;
end

function [values, names] = insulinEstim()
    % Sampling parameters from clinical data (reported in 2002 Hovorka. et al)
    % Column headers for reference
    params_clinic = {'k_12', 'k_a1', 'k_a2', 'S_T', 'S_D', 'F_01'};

    % Transcription of the data table
    data_clinic = [
        0.0343, 0.0031, 0.0752, 29.4e-4, 0.9e-4, 12.1;
        0.0871, 0.0157, 0.0231, 18.7e-4, 6.1e-4, 7.5;
        0.0863, 0.0029, 0.0495, 81.2e-4, 20.1e-4, 10.3;
        0.0968, 0.0088, 0.0302, 86.1e-4, 4.7e-4, 11.9;
        0.0390, 0.0007, 0.1631, 72.4e-4, 15.3e-4, 7.1;
        0.0458, 0.0017, 0.0689, 19.1e-4, 2.2e-4, 9.2
    ];


    % Log-transform the data
    logDataClinic = log(data_clinic);

    % Compute mean and covariance in log-space
    logMeanVectorClinic = mean(logDataClinic);
    logCovMatrixClinic = cov(logDataClinic);

    logSampleClinic = mvnrnd(logMeanVectorClinic, logCovMatrixClinic); % Sample in log-space
    sample_clinic = exp(logSampleClinic); % Transform back to original scale

    % Sampling parameters from prior informnation
    params_informed = {'V_G', 'V_I', 't_max_I', 'k_e', 'A_G', 't_max_G', 'k_bi'};
    distributions_informed = {
        @(n) exp(normrnd(log(0.15), 0.23, [n, 1])) * 1000, ...  % V_G: exp(N(ln(0.15), 0.23^2))
        @(n) normrnd(0.12, 0.012, [n, 1]), ...                  % V_I: N(0.12, 0.012^2)
        @(n) 1 ./ normrnd(0.018, 0.0045, [n, 1]), ...           % t_max_I: 1/N(0.018, 0.0045^2)
        @(n) normrnd(0.14, 0.035, [n, 1]), ...                  % ke: N(0.14, 0.035^2)
        @(n) unifrnd(70, 120, [n, 1]) ./ 100, ...               % A_G: U(70, 120)/100
        @(n) 1 ./ exp(normrnd(-3.689, 0.25, [n, 1])), ...       % t_max_G: 1/exp(N(-3.689, 0.25^2))
        @(n) exp(normrnd(-2.372, 1.092, [n, 1]))                % k_bi: exp(N(-2.372, 1.092^2))
    };

    % Sample each parameter
    sample_informed = zeros(1, length(params_informed));
    for i = 1:length(params_informed)
        valid = false;
        while ~valid
            sample = distributions_informed{i}(1);
            valid = sample > 0;
        end

        sample_informed(i) = distributions_informed{i}(1); % Use the corresponding distribution
    end

    names = [params_clinic, params_informed];
    values = [sample_clinic, sample_informed];
end
