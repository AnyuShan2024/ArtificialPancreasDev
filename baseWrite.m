function baseWrite(values, names)
% This is a helper function for batch writing parameters to workspace
    for i = 1:length(names)
        assignin('base', names{i}, values(i));
    end
end