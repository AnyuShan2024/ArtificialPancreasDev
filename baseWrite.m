function baseWrite(values, names)
    for i = 1:length(names)
        assignin('base', names{i}, values(i));
    end
end