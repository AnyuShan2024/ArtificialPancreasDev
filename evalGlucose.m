function result = evalGlucose(glucoseTrace, protocol)
% EVALGLUCOSE Evaluate blood glucose trace, stripping trailing zero padding.
%
%   result = EVALGLUCOSE(glucoseTrace, protocol) returns one of:
%     1 – Maximum glucose
%     2 – Minimum glucose
%     3 – Mean glucose
%     4 – Time-in-range (TIR, % in 70–180 mg/dL)
%     5 – Loss Function 
%
%   Any trailing zeros in glucoseTrace are treated as padding and removed.
%
%   Example:
%     G = [85, 95, 120, 200, 150, 0, 0, 0];
%     maxG = evalGlucose(G,1);   % 200
%     tir  = evalGlucose(G,4);   % 60 (%)

    % --- strip trailing zeros (padding) ---
    lastValid = find(glucoseTrace~=0, 1, 'last');
    if isempty(lastValid)
        error('No nonzero glucose readings found.');
    end
    glucoseTrace = glucoseTrace(1:lastValid);

    % --- select evaluation protocol ---
    switch protocol
        case 1  % Highest glucose
            result = max(glucoseTrace);
        case 2  % Lowest glucose
            result = min(glucoseTrace);
        case 3  % Average glucose
            result = mean(glucoseTrace);
        case 4  % Time-in-range (% in 70–180 mg/dL)
            % Define targets (mg/dL):
            lowerBound = 70;
            upperBound = 180;
            inRange = glucoseTrace >= lowerBound & glucoseTrace <= upperBound;
            result = sum(inRange) / numel(glucoseTrace) * 100;
        case 5
            result = compute_loss(glucoseTrace);
        otherwise
            error('Protocol must be an integer 1–4.');
    end
end
