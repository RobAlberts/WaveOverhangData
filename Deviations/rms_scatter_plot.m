%% Wave Overhang — RMS Deviation Scatter Plot
% Plots RMS deviation per material as a horizontal scatter/line chart:
%   Y-axis — test samples (TS01–TS06) with thumbnails to the left
%   X-axis — RMS deviation (mm)
%
% Folder structure expected:
%   <script_dir>/Deviations/<Material>/TS0X.csv
%   <script_dir>/Deviations/Images/TS0X.png  (optional thumbnails)

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;
dev_col  = 'Dev';
img_dir  = fullfile(base_dir, 'Images');
thumb_w  = 0.07;   % thumbnail width in normalised figure units (tune if needed)

% ── Paper typography — matches deviation_tables.m ─────────────────────────
fig_font    = 'Times New Roman';
font_sz_ax  = 9;
font_sz_lbl = 9;
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

% 2. Read CSVs and compute RMS
rms_mat = nan(nM, nS);
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
        catch
            warning('Could not read %s', fpath);
        end
    end
end

% 3. Colors and markers — one per material (same order as heatmap)
colors = [
    0.22, 0.53, 0.25;   % PLA      — green
    0.12, 0.47, 0.71;   % PLA-CF   — blue
    0.58, 0.20, 0.58;   % PLA-GF   — purple
    0.85, 0.33, 0.10;   % PETG     — orange
    0.80, 0.07, 0.07;   % PETG-CF  — red
    0.35, 0.35, 0.35;   % ABS      — grey
];
marker_styles = {'o', 's', '^', 'd', 'v', 'p'};

% 4. Build figure
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'RMS Deviation Scatter', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [3 3 fig_w_cm fig_h_cm]);

ax = axes(fig);
hold(ax, 'on');

y_vals = 1:nS;   % sample positions on y-axis

for m = 1:nM
    x = rms_mat(m, :);   % RMS values on x-axis
    valid = ~isnan(x);

    % Connecting line (faint)
    plot(ax, x(valid), y_vals(valid), '-', ...
        'Color', [colors(m,:), 0.40], ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off');

    % Markers
    scatter(ax, x(valid), y_vals(valid), 48, ...
        colors(m,:), marker_styles{m}, ...
        'filled', ...
        'LineWidth', 1.0, ...
        'MarkerEdgeColor', colors(m,:) * 0.65, ...
        'DisplayName', materials{m});
end

% Axes formatting — mirrors deviation_tables.m style
x_max = max(rms_mat(:), [], 'omitnan') * 1.12;
set(ax, ...
    'YTick',          y_vals, ...
    'YTickLabel',     {}, ...          % labels replaced by thumbnails
    'YLim',           [0.5, nS + 0.5], ...
    'YDir',           'reverse', ...   % TS01 at top, TS06 at bottom
    'XLim',           [0, x_max], ...
    'Box',            'off', ...
    'TickDir',        'out', ...
    'XColor',         'k', ...
    'YColor',         'k', ...
    'Color',          'w', ...         % white axes background
    'GridColor',      [0.85 0.85 0.85], ...
    'GridAlpha',      1, ...
    'FontName',       fig_font, ...
    'FontSize',       font_sz_ax);
grid(ax, 'on');

xlabel(ax, 'RMS Deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax, 'RMS deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');

% Legend — upper right, matching heatmap colorbar label style
leg = legend(ax, 'Location', 'southeast', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, ...
    'EdgeColor', [0.75 0.75 0.75], 'Box', 'on');

% 5. Add thumbnails to the left of the y-axis
add_image_labels_left(fig, ax, samples, img_dir, thumb_w, font_sz_thn, fig_font);

% 6. Export
out_path = fullfile(base_dir, 'rms_scatter.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);


%% ── Helper functions ──────────────────────────────────────────────────────

function add_image_labels_left(fig, ax, samples, img_dir, thumb_w, fsize, fname)
% Place thumbnails + sample name labels to the LEFT of the y-axis.
% Mirrors the logic of add_image_labels in deviation_tables.m.
    nS      = numel(samples);
    gap     = 0.012;   % gap between y-axis and thumbnails
    label_w = 0.040;   % width reserved for the text label left of each thumbnail
    total   = thumb_w + gap + label_w + 0.005;

    % Shrink axes from the left to free space
    p = ax.Position;
    ax.Position = [p(1) + total, p(2), p(3) - total, p(4)];

    % Reference from the (now shifted) axes
    pos   = ax.Position;
    row_h = pos(4) / nS;

    for s = 1:nS
        % Y centre for this sample (top-to-bottom: s=1 is top)
        y_c   = pos(2) + pos(4) - (s - 0.5) * row_h;
        h     = row_h * 0.82;
        x_img = pos(1) - gap - thumb_w;
        x_lbl = x_img - label_w + 0.004;

        % --- thumbnail axes ---
        th = axes(fig, ...
            'Position',  [x_img, y_c - h/2, thumb_w, h], ...
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

        % --- text label to the left of thumbnail ---
        annotation(fig, 'textbox', ...
            [x_lbl, y_c - h/2, label_w, h], ...
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
