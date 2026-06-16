%% Wave Overhang Deviation Summary Tables
% Generates two colour-coded heatmap tables:
%   Table 1 — RMS deviation per material x sample (mm)
%   Table 2 — Standard deviation per material x sample (mm)
%
% Folder structure expected:
%   <script_dir>/Deviations/<Material>/TS0X.csv
%   <script_dir>/Deviations/Images/TS01.png  (optional thumbnails)
% Auto-discovers whatever material folders and CSV files exist.

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;   % script lives inside the Deviations folder
dev_col  = 'Dev';
img_dir  = fullfile(base_dir, 'Images');   % folder with TS01.png, TS02.png …
thumb_h  = 0.08;   % thumbnail height in normalised figure units  (tune if needed)

% ── Paper typography (IEEEtran two-column, A4) ────────────────────────────
fig_font    = 'Times New Roman';   % matches NimbusRomNo9L used in the paper
font_sz_ax  = 9;    % axis tick labels & colorbar  (pt)
font_sz_lbl = 9;    % cell value labels            (pt)
font_sz_ttl = 12;   % subplot title                (pt)
font_sz_thn = 10;   % thumbnail captions           (pt)
fig_w_mm    = 186;  % full text width — spans both columns (mm)
fig_h_mm    = 110;  % figure height per table      (mm)  — tune if needed
dpi         = 300;  % export resolution

% Apply font defaults for this session
set(0, 'defaultAxesFontName',  fig_font);
set(0, 'defaultTextFontName',  fig_font);
set(0, 'defaultAxesFontSize',  font_sz_ax);
set(0, 'defaultTextFontSize',  font_sz_ax);
% ──────────────────────────────────────────────────────────────────────────

% 1. Discover materials and samples
mat_entries = dir(dev_dir);
mat_entries = mat_entries([mat_entries.isdir] & ~startsWith({mat_entries.name}, '.'));
material_order = {'PLA', 'PLA-CF', 'PLA-GF', 'PETG', 'PETG-CF', 'ABS'};
found      = {mat_entries.name};
materials  = material_order(ismember(material_order, found));  % keep order, skip missing

all_samples = {};
for m = 1:numel(materials)
    csv_files = dir(fullfile(dev_dir, materials{m}, 'TS*.csv'));
    for f = 1:numel(csv_files)
        [~, name, ~] = fileparts(csv_files(f).name);
        all_samples{end+1} = name; %#ok<AGROW>
    end
end
samples = unique(all_samples);
samples = samples(~strcmp(samples, 'TS00'));  % exclude calibration sample

nM = numel(materials);
nS = numel(samples);

rms_mat = nan(nM, nS);
std_mat = nan(nM, nS);

% 2. Read CSVs and compute statistics
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

% 3. Column labels with geometry descriptions
geo_keys = {'TS00','TS01','TS02','TS03','TS04','TS05','TS06'};
geo_vals = {'Monolayer cal.','Baseline 3mm','Thick OVH 10mm', ...
            '85deg incline','Looped+Narrow','Looped+Holes','Bridge'};
geo_desc = containers.Map(geo_keys, geo_vals);

col_labels = samples;   % TS00, TS01, ... TS06

% 4. Build colormaps
cmap_seq = sequential_colormap(256);  % white-red (both tables: RMS and sigma)

% Figure dimensions in centimeters (Units must be set before Position)
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;

%% Figure 1 — RMS deviation
fig_rms = figure('Name', 'RMS Deviation', 'Color', 'w', ...
                 'Units', 'centimeters', ...
                 'Position', [3 3 fig_w_cm fig_h_cm]);
ax_rms = axes(fig_rms);
rms_disp = rms_mat;  rms_disp(isnan(rms_mat)) = 0;
imagesc(ax_rms, rms_disp);
colormap(ax_rms, cmap_seq);
mx1 = max(rms_mat(:));  mx1 = max([mx1, 0.01]);
if ~isfinite(mx1), mx1 = 1; end
clim(ax_rms, [0, mx1 * 1.05]);
set(ax_rms, 'XTick', 1:nS, 'XTickLabel', {}, ...
            'YTick', 1:nM, 'YTickLabel', materials, ...
            'TickLabelInterpreter', 'none', ...
            'FontName', fig_font, 'FontSize', font_sz_ax, ...
            'XColor', 'k', 'YColor', 'k');
cb1 = colorbar(ax_rms);
cb1.Color = 'k';
ylabel(cb1, 'mm', 'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax_rms, 'RMS deviation  (mm)', ...
      'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');
add_cell_labels(ax_rms, rms_mat, '%.2f', cmap_seq, clim(ax_rms), font_sz_lbl, fig_font);
draw_nan_cells(ax_rms, rms_mat, font_sz_lbl, fig_font);
add_image_labels(fig_rms, ax_rms, samples, img_dir, thumb_h, font_sz_thn, fig_font);
exportgraphics(fig_rms, fullfile(base_dir, 'deviation_rms.png'), 'Resolution', dpi);

%% Figure 2 — Standard deviation
fig_std = figure('Name', 'Standard Deviation', 'Color', 'w', ...
                 'Units', 'centimeters', ...
                 'Position', [3 + fig_w_cm + 0.5 3 fig_w_cm fig_h_cm]);
ax_std = axes(fig_std);
std_disp = std_mat;  std_disp(isnan(std_mat)) = 0;
imagesc(ax_std, std_disp);
colormap(ax_std, cmap_seq);
mx2 = max(std_mat(:));  mx2 = max([mx2, 0.01]);
if ~isfinite(mx2), mx2 = 1; end
clim(ax_std, [0, mx2 * 1.05]);
set(ax_std, 'XTick', 1:nS, 'XTickLabel', {}, ...
            'YTick', 1:nM, 'YTickLabel', materials, ...
            'TickLabelInterpreter', 'none', ...
            'FontName', fig_font, 'FontSize', font_sz_ax, ...
            'XColor', 'k', 'YColor', 'k');
cb2 = colorbar(ax_std);
cb2.Color = 'k';
ylabel(cb2, 'mm', 'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
title(ax_std, 'Standard deviation  (mm)', ...
      'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');
add_cell_labels(ax_std, std_mat, '%.2f', cmap_seq, clim(ax_std), font_sz_lbl, fig_font);
draw_nan_cells(ax_std, std_mat, font_sz_lbl, fig_font);
add_image_labels(fig_std, ax_std, samples, img_dir, thumb_h, font_sz_thn, fig_font);
exportgraphics(fig_std, fullfile(base_dir, 'deviation_sigma.png'), 'Resolution', dpi);

fprintf('Done. %d material(s) x %d sample(s).\n', nM, nS);

%% ── Helper functions ──────────────────────────────────────────────────────

function add_cell_labels(ax, data, fmt, cmap, climvals, fsize, fname)
    [nR, nC] = size(data);
    for r = 1:nR
        for c = 1:nC
            if isnan(data(r, c))
                txt = '-';
                col = [0.5 0.5 0.5];
            else
                txt = sprintf(fmt, data(r, c));
                col = label_color(data(r, c), cmap, climvals);
            end
            text(ax, c, r, txt, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'FontName', fname, 'FontSize', fsize, 'FontWeight', 'bold', ...
                'Color', col);
        end
    end
end

function col = label_color(val, cmap, climvals)
% Black or white text depending on background brightness
    t   = (val - climvals(1)) / (climvals(2) - climvals(1));
    t   = max(0, min(1, t));
    idx = round(t * (size(cmap, 1) - 1)) + 1;
    bg  = cmap(idx, :);
    lum = 0.299*bg(1) + 0.587*bg(2) + 0.114*bg(3);
    if lum < 0.55
        col = [1 1 1];
    else
        col = [0 0 0];
    end
end

function cmap = symmetric_white_red(n)
% White at centre (zero deviation), red at both extremes
    half = floor(n / 2);
    gamma = 0.8;
    t  = linspace(0, 1, half)';
    tc = t .^ gamma;
    % white -> red
    w2r = [ones(half,1), (1-tc), (1-tc)];   % R stays 1, G and B drop
    cmap = [flipud(w2r); w2r];              % mirror: red-white-red
end

function cmap = accuracy_colormap(n)
% Green at zero, red at extremes, with power curve for sharper gradient
    gamma = 0.8;   % <1 = more red sooner; increase toward 1.0 for more green
    half  = floor(n / 2);
    t     = linspace(0, 1, half)';
    tc    = t .^ gamma;           % nonlinear: ramps up quickly from zero

    % left half: red (extreme negative) -> green (zero)
    r2g = [(1 - tc) * 0.85 + tc * 0.15, ...   % R: 0.85 -> 0.15
           (1 - tc) * 0.15 + tc * 0.75, ...   % G: 0.15 -> 0.75
           zeros(half, 1) + 0.15];            % B: flat

    % right half: green (zero) -> red (extreme positive)  [mirror]
    g2r = flipud(r2g);
    if mod(n, 2) ~= 0
        g2r = [r2g(end,:); g2r];   % odd n: duplicate midpoint
    end

    cmap = [r2g; g2r];
end

function cmap = sequential_colormap(n)
% White (low) -- Red (high)
    cmap = [linspace(1, 0.85, n)', ...
            linspace(1, 0.15, n)', ...
            linspace(1, 0.15, n)'];
end

function cmap = sequential_green_red(n)
% Green (low/good) -- Red (high/bad), with power curve for contrast
    gamma = 0.4;
    t  = linspace(0, 1, n)';
    tc = t .^ gamma;
    cmap = [(tc * 0.85 + (1-tc) * 0.15), ...   % R: 0.15 -> 0.85
            ((1-tc) * 0.75 + tc * 0.15), ...   % G: 0.75 -> 0.15
            zeros(n, 1) + 0.15];               % B: flat
end

function draw_nan_cells(ax, data, fsize, fname)
% Draw a grey patch with 'N/A' text over every NaN cell
    [nR, nC] = size(data);
    for r = 1:nR
        for c = 1:nC
            if isnan(data(r, c))
                patch(ax, ...
                    [c-0.5, c+0.5, c+0.5, c-0.5], ...
                    [r-0.5, r-0.5, r+0.5, r+0.5], ...
                    [0.75 0.75 0.75], 'EdgeColor', 'none');
                text(ax, c, r, 'N/A', ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontName', fname, 'FontSize', fsize, 'Color', [0.4 0.4 0.4]);
            end
        end
    end
end

function add_image_labels(fig, ax, samples, img_dir, thumb_h, fsize, fname)
% Place thumbnails + sample name labels below ax.
% Shifts the axes up to make room. Falls back to text if no image found.
    nS      = numel(samples);
    gap     = 0.012;   % gap between axes bottom and thumbnails
    label_h = 0.030;   % height reserved for the text label below each thumbnail
    total   = thumb_h + gap + label_h + 0.01;

    % Shrink axes from the bottom to free space for thumbnails (top stays fixed)
    p = ax.Position;
    ax.Position = [p(1), p(2) + total, p(3), p(4) - total];

    % Reference position from the (now shifted) axes
    pos   = ax.Position;
    col_w = pos(3) / nS;

    for s = 1:nS
        x_c = pos(1) + (s - 0.5) * col_w;
        w   = col_w * 0.82;
        y_img = pos(2) - gap - thumb_h;
        y_lbl = y_img - label_h + 0.004;

        % --- thumbnail axes ---
        th = axes(fig, ...
            'Position',  [x_c - w/2, y_img, w, thumb_h], ...
            'XTick', [], 'YTick', [], ...
            'Box', 'on', 'LineWidth', 0.5, ...
            'XColor', [0.7 0.7 0.7], 'YColor', [0.7 0.7 0.7]);

        img_path = find_sample_image(img_dir, samples{s});
        if ~isempty(img_path)
            imshow(imread(img_path), 'Parent', th);
        else
            % Placeholder: light grey box with sample name
            fill(th, [0 1 1 0], [0 0 1 1], [0.93 0.93 0.93], 'EdgeColor', 'none');
            text(th, 0.5, 0.5, samples{s}, ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'FontName', fname, 'FontSize', fsize, 'Color', [0.55 0.55 0.55]);
            xlim(th, [0 1]); ylim(th, [0 1]);
        end

        % --- text label below thumbnail ---
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
% Return path to first matching image, or '' if none found.
    p = '';
    if ~isfolder(img_dir), return; end
    for ext = {'.png', '.jpg', '.jpeg', '.PNG', '.JPG', '.tif', '.tiff'}
        c = fullfile(img_dir, [sample_name ext{1}]);
        if isfile(c), p = c; return; end
    end
end
