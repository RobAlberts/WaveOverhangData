%% Wave Overhang — RMS Deviation per Material with Min/Max Error Bars
% X-axis : materials (PLA, PLA-CF, PLA-GF, PETG, PETG-CF, ABS)
% Y-axis : RMS deviation (mm)
% For each material:
%   - 6 unlabelled scatter points, one per sample (TS01–TS06), each showing
%     the RMS deviation of that sample
%   - 1 mean point (mean of the 6 sample RMS values) with a single error bar
%     spanning from the lowest to the highest sample RMS
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

% 2. Read CSVs — compute RMS deviation per material × sample
sample_rms = nan(nM, nS);

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
            sample_rms(m, s) = sqrt(mean(vals.^2));
        catch
            warning('Could not read %s', fpath);
        end
    end
end

% 3. Per-material summary: mean of sample RMS values, min, max + which sample
mat_mean_rms = nan(nM, 1);
mat_min_rms  = nan(nM, 1);
mat_max_rms  = nan(nM, 1);
mat_min_lbl  = repmat({''}, nM, 1);   % sample name at min
mat_max_lbl  = repmat({''}, nM, 1);   % sample name at max
for m = 1:nM
    valid_idx = find(~isnan(sample_rms(m, :)));
    if isempty(valid_idx), continue; end
    row = sample_rms(m, valid_idx);
    mat_mean_rms(m) = mean(row);
    [mat_min_rms(m), i_min] = min(row);
    [mat_max_rms(m), i_max] = max(row);
    mat_min_lbl{m} = samples{valid_idx(i_min)};
    mat_max_lbl{m} = samples{valid_idx(i_max)};
end

% 4. Build figure
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'RMS Deviation by Material', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [3 3 fig_w_cm fig_h_cm]);

ax = axes(fig);
hold(ax, 'on');

x_vals     = 1:nM;
mean_color      = [0 0 0];   % black filled circle for mean
mean_edge_color = [0 0 0];

% ── 4a. Scatter: grey unlabelled sample RMS points per material ───────────
dot_color = [0.65 0.65 0.65];
for s = 1:nS
    x_pts = x_vals(~isnan(sample_rms(:, s)'));
    y_pts = sample_rms(~isnan(sample_rms(:, s)), s)';
    if isempty(x_pts), continue; end
    scatter(ax, x_pts, y_pts, 22, 'o', ...
        'MarkerFaceColor',   dot_color, ...
        'MarkerEdgeColor',   dot_color * 0.7, ...
        'LineWidth',         0.6, ...
        'HandleVisibility',  'off');
end

% ── 4b. Mean-of-RMS point + single asymmetric error bar ───────────────────
valid_m = ~isnan(mat_mean_rms);
lo_err  = mat_mean_rms(valid_m) - mat_min_rms(valid_m);   % mean → min
hi_err  = mat_max_rms(valid_m)  - mat_mean_rms(valid_m);  % mean → max

% Draw error bars manually: solid black stem + caps,
% then solid black circle mean marker on top.
bar_color = [0 0 0];   % solid black
cap_hw    = 0.12;      % half-width of cap in x-axis units
bar_lw    = 1.5;

vm = find(valid_m);
for mi = 1:numel(vm)
    m   = vm(mi);
    xm  = x_vals(m);
    ylo = mat_min_rms(m);
    yhi = mat_max_rms(m);
    % vertical stem
    line(ax, [xm xm], [ylo yhi], ...
        'LineStyle',  '--', ...
        'LineWidth',  bar_lw, ...
        'Color',      bar_color, ...
        'HandleVisibility', 'off');
    % bottom cap
    line(ax, [xm - cap_hw, xm + cap_hw], [ylo ylo], ...
        'LineStyle',  '-', ...
        'LineWidth',  bar_lw, ...
        'Color',      bar_color, ...
        'HandleVisibility', 'off');
    % top cap
    line(ax, [xm - cap_hw, xm + cap_hw], [yhi yhi], ...
        'LineStyle',  '-', ...
        'LineWidth',  bar_lw, ...
        'Color',      bar_color, ...
        'HandleVisibility', 'off');
end

% Mean marker (drawn last so it sits on top)
scatter(ax, x_vals(valid_m), mat_mean_rms(valid_m), 80, 'o', ...
    'MarkerFaceColor',  mean_color, ...
    'MarkerEdgeColor',  mean_edge_color, ...
    'LineWidth',        1.2, ...
    'HandleVisibility', 'off');

legend(ax, 'off');

% Zero-deviation reference line
yline(ax, 0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8, 'HandleVisibility', 'off');

% ── 4c. Sample labels at min and max caps ─────────────────────────────────
lbl_color  = [0.25 0.25 0.25];
lbl_offset = (max(mat_max_rms, [], 'omitnan') - min(mat_min_rms, [], 'omitnan')) * 0.025;
for m = 1:nM
    if isnan(mat_min_rms(m)), continue; end
    % label below min cap
    text(ax, x_vals(m), mat_min_rms(m) - lbl_offset, mat_min_lbl{m}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'top', ...
        'FontName',  fig_font, ...
        'FontSize',  font_sz_ax - 1, ...
        'Color',     lbl_color, ...
        'Interpreter', 'none');
    % label above max cap
    text(ax, x_vals(m), mat_max_rms(m) + lbl_offset, mat_max_lbl{m}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'bottom', ...
        'FontName',  fig_font, ...
        'FontSize',  font_sz_ax - 1, ...
        'Color',     lbl_color, ...
        'Interpreter', 'none');
end

% 5. Axes formatting — mirrors deviation_tables.m
all_vals = [mat_min_rms; mat_max_rms];
y_max = max(all_vals(isfinite(all_vals))) * 1.25;
y_min = 0;   % RMS is always non-negative
if isempty(y_max) || ~isfinite(y_max), y_max = 1; end

set(ax, ...
    'XTick',             x_vals, ...
    'XTickLabel',        materials, ...
    'TickLabelInterpreter', 'none', ...
    'XLim',              [0.5, nM + 0.5], ...
    'YLim',              [y_min, y_max], ...
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

ylabel(ax, 'RMS deviation  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
%xlabel(ax, 'Material', ...
    %'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax, 'RMS deviation per material  (mm)', ...
    'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');

% 6. Export
out_path = fullfile(base_dir, 'rms_errorbar_by_material.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);
