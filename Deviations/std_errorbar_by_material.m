%% Wave Overhang — Standard Deviation per Material with Min/Max Error Bars
% X-axis : materials (PLA, PLA-CF, PLA-GF, PETG, PETG-CF, ABS)
% Y-axis : standard deviation (mm)
% For each material:
%   - 6 unlabelled scatter points, one per sample (TS01–TS06), each showing
%     the standard deviation of that sample
%   - 1 mean point (mean of the 6 sample std values) with a single error bar
%     spanning from the lowest to the highest sample std
%
% Folder structure expected:
%   <script_dir>/<Material>/TS0X.csv

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;
dev_col  = 'Dev';

% ── Paper typography — identical to deviation_tables.m ────────────────────
fig_font    = 'Times New Roman';
font_sz_ax  = 9;
font_sz_ttl = 12;
fig_w_mm    = 186;
fig_h_mm    = 120;
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

% 2. Read CSVs — compute std deviation per material × sample
sample_std = nan(nM, nS);

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
            sample_std(m, s) = std(vals);
        catch
            warning('Could not read %s', fpath);
        end
    end
end

% 3. Per-material summary: mean of sample std values, min, max
mat_mean_std = nan(nM, 1);
mat_min_std  = nan(nM, 1);
mat_max_std  = nan(nM, 1);
for m = 1:nM
    row = sample_std(m, ~isnan(sample_std(m, :)));
    if isempty(row), continue; end
    mat_mean_std(m) = mean(row);
    mat_min_std(m)  = min(row);
    mat_max_std(m)  = max(row);
end

% 4. Build figure
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'Standard Deviation by Material', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [3 3 fig_w_cm fig_h_cm]);

ax = axes(fig);
hold(ax, 'on');

x_vals     = 1:nM;
dot_color  = [0.55 0.55 0.55];   % grey for the 6 unlabelled sample points
mean_color = [0.10 0.10 0.10];   % near-black for the mean point

% ── 4a. Scatter: 6 unlabelled sample std points per material ──────────────
jitter_w = 0.12;
rng(0);            % reproducible jitter
for m = 1:nM
    row = sample_std(m, :);
    valid_s = find(~isnan(row));
    n = numel(valid_s);
    if n == 0, continue; end
    jitter = (rand(1, n) - 0.5) * 2 * jitter_w;
    scatter(ax, x_vals(m) + jitter, row(valid_s), 18, ...
        'o', ...
        'MarkerFaceColor', dot_color, ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.55, ...
        'HandleVisibility', 'off');
end

% ── 4b. Mean-of-std point + single asymmetric error bar ───────────────────
valid_m = ~isnan(mat_mean_std);
lo_err  = mat_mean_std(valid_m) - mat_min_std(valid_m);
hi_err  = mat_max_std(valid_m)  - mat_mean_std(valid_m);

errorbar(ax, x_vals(valid_m), mat_mean_std(valid_m), lo_err, hi_err, ...
    'LineStyle',        'none', ...
    'LineWidth',        1.4, ...
    'Color',            mean_color, ...
    'Marker',           'o', ...
    'MarkerSize',       6, ...
    'MarkerFaceColor',  mean_color, ...
    'MarkerEdgeColor',  mean_color, ...
    'CapSize',          6, ...
    'HandleVisibility', 'off');

% 5. Axes formatting — mirrors deviation_tables.m
all_vals = [mat_min_std; mat_max_std];
y_max = max(all_vals(isfinite(all_vals))) * 1.18;
if isempty(y_max) || ~isfinite(y_max), y_max = 1; end

set(ax, ...
    'XTick',             x_vals, ...
    'XTickLabel',        materials, ...
    'TickLabelInterpreter', 'none', ...
    'XLim',              [0.5, nM + 0.5], ...
    'YLim',              [0, y_max], ...
    'Box',               'off', ...
    'TickDir',           'out', ...
    'Color',             'w', ...
    'XColor',            'k', ...
    'YColor',            'k', ...
    'GridColor',         [0.85 0.85 0.85], ...
    'GridAlpha',         1, ...
    'FontName',          fig_font, ...
    'FontSize',          font_sz_ax);
grid(ax, 'on');

ylabel(ax, 'Standard deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
xlabel(ax, 'Material', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax, 'Standard deviation per material  (mm)  —  error bars: min / max of sample \sigma', ...
    'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');

% 6. Export
out_path = fullfile(base_dir, 'std_errorbar_by_material.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);
