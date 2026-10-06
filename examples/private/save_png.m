function save_png(fig, file, width_px, height_px)
%SAVE_PNG  Save a figure as a PNG at a fixed pixel size (MATLAB and Octave).
%   Forces the light theme first: MATLAB R2025a+ follows the desktop theme,
%   which would otherwise export dark figures with grey text.
    if isprop(fig, 'Theme')
        set(fig, 'Theme', 'light');
    end
    dpi = 150;
    set(fig, 'Units', 'pixels', 'Position', [50 50 width_px height_px]);
    set(fig, 'PaperUnits', 'inches', ...
             'PaperPosition', [0 0 width_px/dpi height_px/dpi], ...
             'PaperSize', [width_px/dpi height_px/dpi]);
    print(fig, file, '-dpng', sprintf('-r%d', dpi));
    fprintf('  saved %s\n', file);
end
