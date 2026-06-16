%% Wave Overhang — RMS Deviation Small Multiples (±σ error bars)
% One subplot per material, samples on x-axis, RMS ± std on y-axis.
% All panels share the same y-axis scale for direct comparison.
% Thumbnails appear below the bottom row of subplots.
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
thumb_h  = 0.07;   % thumbnail height in normalised figure units

% ── Paper typography — identical to deviation_tables.m ────────────────────
fig_font    = 'Times New Roman';
font_sz_ax  = 8;
font_sz_ttl = 9;
font_sz_thn = 8;
fig_w_mm    = 186;
fig_h_mm    = 150;
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
samples = samples(~strcmp(samples, 'TS00'));

nM = numel(materials);
nS = numel(samples);

% 2. Read CSVs
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

% Per-panel y-axis limits: each material scales to its own data.
% Lower bound uses rms-std so bottom error bar caps are never clipped.
y_max_per = max(rms_mat + std_mat, [], 2, 'omitnan') * 1.15;  % nM × 1
y_min_per = min(rms_mat - std_mat, [], 2, 'omitnan') - 0.02;  % nM × 1, small pad below lowest cap

% 3. Colors — one per material
mat_colors = [
    0.00, 0.69, 0.31;   % PLA      — vivid green
    0.00, 0.45, 0.70;   % PLA-CF   — strong blue
    0.58, 0.10, 0.70;   % PLA-GF   — vivid purple
    0.93, 0.49, 0.00;   % PETG     — vivid orange
    0.84, 0.07, 0.07;   % PETG-CF  — vivid red
    0.30, 0.30, 0.30;   % ABS      — dark grey
];

% 4. Grid layout (2 rows × 3 columns)
n_cols = 3;
n_rows = 2;

left_m   = 0.10;   % space for y-axis labels on left
right_m  = 0.03;
top_m    = 0.06;
col_gap  = 0.025;
row_gap  = 0.09;

% Bottom margin: room for thumbnails + sample labels below bottom row
gap      = 0.012;
label_h  = 0.030;
bottom_m = thumb_h + gap + label_h + 0.025;

plot_w = (1 - left_m - right_m - (n_cols-1)*col_gap) / n_cols;
plot_h = (1 - top_m  - bottom_m - (n_rows-1)*row_gap) / n_rows;

% 5. Build figure
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'RMS Deviation Small Multiples', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [2 2 fig_w_cm fig_h_cm]);

ax_arr = gobjects(nM, 1);
x_vals = 1:nS;

for m = 1:nM
    row = ceil(m / n_cols);
    col = mod(m - 1, n_cols) + 1;

    x_pos = left_m + (col - 1) * (plot_w + col_gap);
    y_pos = 1 - top_m - row * plot_h - (row - 1) * row_gap;

    ax = axes(fig, 'Position', [x_pos, y_pos, plot_w, plot_h]); %#ok<LAXES>
    ax_arr(m) = ax;
    hold(ax, 'on');

    rms_row = rms_mat(m, :);
    std_row = std_mat(m, :);
    valid   = ~isnan(rms_row);
    col_rgb = mat_colors(m, :);

    errorbar(ax, x_vals(valid), rms_row(valid), std_row(valid), ...
        'LineStyle',       '-', ...
        'LineWidth',       1.2, ...
        'Color',           col_rgb, ...
        'Marker',          'o', ...
        'MarkerSize',      4, ...
        'MarkerFaceColor', col_rgb, ...
        'MarkerEdgeColor', col_rgb * 0.65, ...
        'CapSize',         4);

    % Title = material name
    title(ax, materials{m}, ...
        'FontName',   fig_font, ...
        'FontSize',   font_sz_ttl, ...
        'FontWeight', 'bold', ...
        'Color',      'k');

    % Axis limits and formatting
    set(ax, ...
        'XLim',      [0.5, nS + 0.5], ...
        'YLim',      [y_min_per(m), y_max_per(m)], ...
        'XTick',     x_vals, ...
        'XTickLabel', {}, ...          % thumbnails/labels added below
        'Box',       'off', ...
        'TickDir',   'out', ...
        'Color',     'w', ...
        'XColor',    'k', ...
        'YColor',    'k', ...
        'GridColor', [0.82 0.82 0.82], ...
        'GridAlpha', 1, ...
        'FontName',  fig_font, ...
        'FontSize',  font_sz_ax);
    grid(ax, 'on');

    % Y-tick labels only on left column
    if col ~= 1
        set(ax, 'YTickLabel', {});
    end
end

% 6. Shared y-axis label (centred on the left edge)
mid_y = 1 - top_m - n_rows * plot_h / 2 - (n_rows - 1) * row_gap / 2 - plot_h / 2;
annotation(fig, 'textbox', [0, mid_y - 0.15, left_m - 0.01, 0.30], ...
    'String',              'RMS deviation  (mm)', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment',   'middle', ...
    'Rotation',            90, ...
    'EdgeColor',           'none', ...
    'Color',               'k', ...
    'FontName',            fig_font, ...
    'FontSize',            font_sz_ax, ...
    'Interpreter',         'none');

% 7. Thumbnails below the bottom row only (cols 4, 5, 6 → m = 4, 5, 6)
for m = (n_cols + 1):(n_cols * n_rows)
    add_image_labels(fig, ax_arr(m), samples, img_dir, ...
                     thumb_h, font_sz_thn, fig_font, gap, label_h);
end

% 8. Export
out_path = fullfile(base_dir, 'rms_small_multiples.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);


%% ── Helper functions ──────────────────────────────────────────────────────

function add_image_labels(fig, ax, samples, img_dir, thumb_h, fsize, fname, gap, label_h)
    nS    = numel(samples);
    total = thumb_h + gap + label_h + 0.01;

    % Shrink this axes up to make room below
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
            'XColor', [0.7 0.7 0.7], 'YColor', [0.7 0.7 0.7]); %#ok<LAXES>

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
