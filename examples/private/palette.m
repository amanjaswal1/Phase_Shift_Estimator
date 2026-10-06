function c = palette(name)
%PALETTE  Consistent colours for all figures in this repo.
    switch lower(name)
        case 'blue',   c = [0.000 0.447 0.741];
        case 'orange', c = [0.850 0.325 0.098];
        case 'green',  c = [0.466 0.674 0.188];
        case 'purple', c = [0.494 0.184 0.556];
        case 'red',    c = [0.800 0.100 0.150];
        case 'grey',   c = [0.450 0.450 0.450];
        case 'black',  c = [0.000 0.000 0.000];
        otherwise,     error('palette:name', 'Unknown colour "%s".', name);
    end
end
