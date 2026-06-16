%% Wave Overhang — RMS Deviation with ±σ Error Bars
% Scatter/line plot: test samples on x-axis, RMS deviation on y-axis,
% one series per material, error bars show ±1 standard deviation.
%
% Folder structure expected:
%   <script_dir>/<Material>/TS0X.csv
%   <script_dir>/Images/TS0X.png  (optional thumbnails)

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;
dev_col  = 'Dev';
img_dir  = fullfile(base_dir, 'Images');
thumb_h  = 0.08;   % thumbnail height in normalised figure units

% ── Paper typography — identical to deviation_tables.m ────────────────────
fig_font    = 'Times New Roman';
font_sz_ax  = 9;
font_sz_ttl = 12;
font_sz_thn = 10;
fig_w_mm    = 186;
fig_h_mm    = 110;
dpi         = 300;

set(0, 'defaultAxesFontName',  fig_font);
set(0, 'defaultTextFontName',  fig_font);
set(0, 'defaultAxesFontSize',  font_sz_ax);
set(0, 'defaultTextFontSize',  font_sz_ax);
% ──────────────────────────────────────────────────────────────────────────

% 1. Discover materials and samples
mat_entries    = dir(dev_dir);
mat_entries    = mat_entries([mat_entries.isdir] & ~startsWith({mat_entries.name}, '.'));
material_order = {'PLA', 'PLA-CF', 'PLA-GF', 'PETG', 'PETG-CF', 'ABS'};
found          = {mat_entries.name};
materials      = material_order(ismember(material_order, found));

all_samples = {};
for m = 1:numel(materials)
    csv_files = dir(fullfile(dev_dir, materials{m}, 'TS*.csv'));
    for f = 1:numel(csv_files)
        [~, name, ~] = fileparts(csv_files(f).name);
        all_samples{end+1} = name; %#ok<AGROW>
    end
end
samples = unique(all_samples);
samples = samples(~strcmp(samples, 'TS00'));   % exclude calibration sample

nM = numel(materials);
nS = numel(samples);

% 2. Read CSVs — compute RMS and std dev
rms_mat = nan(nM, nS);
std_mat = nan(nM, nS);

for m = 1:nM
    for s = 1:nS
        fpath = fullfile(dev_dir, materials{m}, [samples{s} '.csv']);
        if ~isfile(fpath), continue; end
        try
            T   = readtable(fpath, 'VariableNamingRule', 'preserve');
            raw = T.(dev_col);
            if isnumeric(raw)
                vals = raw;
            elseif iscell(raw)
                vals = cellfun(@str2double, strtrim(raw));
            else
                vals = str2double(strtrim(string(raw)));
            end
            vals = vals(isfinite(vals));
            if numel(vals) < 2, continue; end
            rms_mat(m, s) = sqrt(mean(vals.^2));
            std_mat(m, s) = std(vals);
        catch
            warning('Could not read %s', fpath);
        end
    end
end

% 3. Colors and markers — one per material
mat_colors = [
    0.18, 0.55, 0.25;   % PLA      — green
    0.12, 0.47, 0.71;   % PLA-CF   — blue
    0.58, 0.20, 0.58;   % PLA-GF   — purple
    0.88, 0.43, 0.06;   % PETG     — orange
    0.79, 0.17, 0.17;   % PETG-CF  — red
    0.40, 0.40, 0.40;   % ABS      — grey
];
marker_styles = {'o', 's', '^', 'd', 'v', 'p'};

% 4. Build figure
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'RMS Deviation ± σ', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [3 3 fig_w_cm fig_h_cm]);

ax = axes(fig);
hold(ax, 'on');

x_vals = 1:nS;
h_series = gobjects(nM, 1);   % handles for legend

for m = 1:nM
    rms_row = rms_mat(m, :);
    std_row = std_mat(m, :);
    valid   = ~isnan(rms_row);
    col     = mat_colors(m, :);

    % Error bar series (draws line + markers + bars in one call)
    h = errorbar(ax, x_vals(valid), rms_row(valid), std_row(valid), ...
        'LineStyle',        '-', ...
        'LineWidth',        1.2, ...
        'Color',            col, ...
        'Marker',           marker_styles{m}, ...
        'MarkerSize',       5, ...
        'MarkerFaceColor',  col, ...
        'MarkerEdgeColor',  col * 0.65, ...
        'CapSize',          5, ...
        'DisplayName',      materials{m});

    h_series(m) = h;
end

% 5. Axes formatting — mirrors deviation_tables.m
y_max = max(rms_mat(:) + std_mat(:), [], 'omitnan') * 1.12;
set(ax, ...
    'XTick',        x_vals, ...
    'XTickLabel',   {}, ...          % replaced by thumbnails below
    'XLim',         [0.5, nS + 0.5], ...
    'YLim',         [0, y_max], ...
    'Box',          'off', ...
    'TickDir',      'out', ...
    'Color',        'w', ...
    'XColor',       'k', ...
    'YColor',       'k', ...
    'GridColor',    [0.85 0.85 0.85], ...
    'GridAlpha',    1, ...
    'FontName',     fig_font, ...
    'FontSize',     font_sz_ax);
grid(ax, 'on');

ylabel(ax, 'RMS deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax, 'RMS deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');

% 6. Legend
legend(ax, h_series, materials, ...
    'Location',  'northeast', ...
    'FontName',  fig_font, ...
    'FontSize',  font_sz_ax, ...
    'EdgeColor', [0.75 0.75 0.75], ...
    'Color',     'w', ...
    'TextColor', 'k', ...
    'Box',       'on');

% 7. Thumbnails below x-axis — identical helper to deviation_tables.m
add_image_labels(fig, ax, samples, img_dir, thumb_h, font_sz_thn, fig_font);

% 8. Export
out_path = fullfile(base_dir, 'rms_errorbar.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);


%% ── Helper functions (copied verbatim from deviation_tables.m) ────────────

function add_image_labels(fig, ax, samples, img_dir, thumb_h, fsize, fname)
    nS      = numel(samples);
    gap     = 0.012;
    label_h = 0.030;
    total   = thumb_h + gap + label_h + 0.01;

    p = ax.Position;
    ax.Position = [p(1), p(2) + total, p(3), p(4) - total];

    pos   = ax.Position;
    col_w = pos(3) / nS;

    for s = 1:nS
        x_c   = pos(1) + (s - 0.5) * col_w;
        w     = col_w * 0.82;
        y_img = pos(2) - gap - thumb_h;
        y_lbl = y_img - label_h + 0.004;

        th = axes(fig, ...
            'Position',  [x_c - w/2, y_img, w, thumb_h], ...
            'XTick', [], 'YTick', [], ...
            'Box', 'on', 'LineWidth', 0.5, ...
            'XColor', [0.7 0.7 0.7], 'YColor', [0.7 0.7 0.7]);

        img_path = find_sample_image(img_dir, samples{s});
        if ~isempty(img_path)
            imshow(imread(img_path), 'Parent', th);
        else
            fill(th, [0 1 1 0], [0 0 1 1], [0.93 0.93 0.93], 'EdgeColor', 'none');
            text(th, 0.5, 0.5, samples{s}, ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'FontName', fname, 'FontSize', fsize, 'Color', [0.55 0.55 0.55]);
            xlim(th, [0 1]); ylim(th, [0 1]);
        end

        annotation(fig, 'textbox', ...
            [x_c - w/2, y_lbl, w, label_h], ...
            'String',              samples{s}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment',   'middle', ...
            'EdgeColor',           'none', ...
            'Color',               'k', ...
            'FontName',            fname, ...
            'FontSize',            fsize, ...
            'FontWeight',          'bold', ...
            'Interpreter',         'none');
    end
end

function p = find_sample_image(img_dir, sample_name)
    p = '';
    if ~isfolder(img_dir), return; end
    for ext = {'.png', '.jpg', '.jpeg', '.PNG', '.JPG', '.tif', '.tiff'}
        c = fullfile(img_dir, [sample_name ext{1}]);
        if isfile(c), p = c; return; end
    end
end
