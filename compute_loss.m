function loss = compute_loss(glucose_values)
    % Step 1: Remove invalid glucose values
    valid_glucose = glucose_values(~isnan(glucose_values) & glucose_values > 0);
    
    if isempty(valid_glucose)
        warning('All glucose values are invalid! Returning NaN loss.');
        loss = NaN;
        return;
    end

    % Step 2: Define penalty weights
    alpha = 1;  % Weight for mild hypoglycemia penalty
    beta = 5/6;   % Weight for mild hyperglycemia penalty

    % Step 3: Compute penalties for each valid glucose value
    hypo_penalty = alpha * (max(70 - valid_glucose, 0)).^2;
    hyper_penalty = beta * max(valid_glucose - 180, 0);

    % Step 4: Compute mean loss
    loss = mean(hypo_penalty + hyper_penalty);
end