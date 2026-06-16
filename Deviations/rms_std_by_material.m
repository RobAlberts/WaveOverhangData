%% Wave Overhang — RMS + Std Deviation per Sample by Material (two separate figures)
% Figure (a): RMS deviation  — one smooth line per sample (TS01–TS06)
% Figure (b): Standard deviation — same layout
% Right column of each: thumbnail legend aligned with the plot area
% Outputs: rms_by_material.png, std_by_material.png
%
% Lines are smoothed with pchip interpolation between material points.
%
% Folder structure expected:
%   <script_dir>/<Material>/TS0X.csv
%   <script_dir>/Images/TS0X.png   (optional thumbnails for legend)

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;
dev_col  = 'Dev';
img_dir  = fullfile(base_dir, 'Images');

fig_font    = 'Times New Roman';
font_sz_ax  = 9;
font_sz_ttl = 12;
fig_w_mm    = 160;
fig_h_mm    = 130;
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

% 2. Read CSVs — rows = samples, cols = materials
rms_mat = nan(nS, nM);
std_mat = nan(nS, nM);

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
            rms_mat(s, m) = sqrt(mean(vals.^2));
            std_mat(s, m) = std(vals);
        catch
            warning('Could not read %s', fpath);
        end
    end
end

% 3. Colors and markers — one per sample
sample_colors = [
    0.18, 0.55, 0.25;   % TS01 — green
    0.12, 0.47, 0.71;   % TS02 — blue
    0.58, 0.20, 0.58;   % TS03 — purple
    0.88, 0.43, 0.06;   % TS04 — orange
    0.79, 0.17, 0.17;   % TS05 — red
    0.40, 0.40, 0.40;   % TS06 — grey
];
marker_styles = {'o', 's', '^', 'd', 'v', 'p'};

% 4. Per-figure settings
x_vals    = 1:nM;
fig_w_cm  = fig_w_mm / 10;
fig_h_cm  = fig_h_mm / 10;

datas     = {rms_mat,              std_mat};
titles    = {'RMS deviation  (mm)', 'Standard deviation  (mm)'};
ylbls     = {'RMS deviation  (mm)', 'Standard deviation  (mm)'};
out_names = {'rms_by_material.png', 'std_by_material.png'};

lm      = 0.09;   % left margin
rm      = 0.03;   % right margin (no thumbnail)
bm      = 0.13;   % bottom margin
tm      = 0.10;   % top margin
th_gap  = 0.025;  % gap between plot and thumbnail column
th_w    = 0.18;   % thumbnail column width

% show_thumbnails(panel): true for rms, false for std
show_thumbnails = [true, false];

% 5. Build and export each figure separately
for panel = 1:2
    if show_thumbnails(panel)
        pw = 1 - lm - th_gap - th_w;
    else
        pw = 1 - lm - rm;
    end
    ph = 1 - bm - tm;

    fig = figure('Name', titles{panel}, 'Color', 'w', ...
                 'Units', 'centimeters', ...
                 'Position', [2 2 fig_w_cm fig_h_cm]);

    ax  = axes(fig, 'Position', [lm, bm, pw, ph]);
    dat = datas{panel};
    hold(ax, 'on');

    if show_thumbnails(panel)
        scatter_handle_vis = 'off';
    else
        scatter_handle_vis = 'on';
    end

    for s = 1:nS
        row   = dat(s, :);
        valid = ~isnan(row);
        if sum(valid) < 1, continue; end
        xv  = x_vals(valid);
        yv  = row(valid);
        col = sample_colors(min(s, size(sample_colors, 1)), :);
        mk  = marker_styles{min(s, numel(marker_styles))};

        if sum(valid) >= 3
            xf = linspace(min(xv), max(xv), 400);
            yf = pchip(xv, yv, xf);
        elseif sum(valid) == 2
            xf = linspace(xv(1), xv(end), 2);
            yf = interp1(xv, yv, xf, 'linear');
        else
            xf = xv;  yf = yv;
        end

        plot(ax, xf, yf, '-', ...
            'Color',     col, ...
            'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
        scatter(ax, xv, yv, 32, mk, ...
            'MarkerFaceColor', col, ...
            'MarkerEdgeColor', col * 0.60, ...
            'LineWidth',       0.8, ...
            'DisplayName',     samples{s}, ...
            'HandleVisibility', scatter_handle_vis);
    end

    all_vals = dat(:);
    y_max = max(all_vals(isfinite(all_vals))) * 1.15;
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

    ylabel(ax, ylbls{panel}, ...
        'FontName', fig_font, 'FontSize', font_sz_ax, 'Color', 'k');
    title(ax, titles{panel}, ...
        'FontName', fig_font, 'FontSize', font_sz_ttl, 'FontWeight', 'bold', 'Color', 'k');
    hold(ax, 'off');

    % 6. Thumbnail legend column (rms figure) / simple legend (std figure)
    if ~show_thumbnails(panel)
        legend(ax, 'Location', 'northeast', ...
            'FontName',  fig_font, ...
            'FontSize',  font_sz_ax, ...
            'EdgeColor', [0.75 0.75 0.75], ...
            'Color',     'w', ...
            'TextColor', 'k', ...
            'Box',       'on');

        out_path = fullfile(base_dir, out_names{panel});
        exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
        fprintf('Saved: %s\n', out_path);
        close(fig);
        continue;
    end
    th_col_x  = lm + pw + th_gap;
    row_h     = ph / nS;
    th_img_w  = th_w * 0.55;
    th_img_h  = row_h * 0.68;
    lbl_x_off = th_img_w + 0.010;

    for s = 1:nS
        row_cy = bm + ph - (s - 0.5) * row_h;
        col    = sample_colors(min(s, size(sample_colors, 1)), :);

        th_ax = axes(fig, ...
            'Position',  [th_col_x, row_cy - th_img_h/2, th_img_w, th_img_h], ...
            'XTick', [], 'YTick', [], ...
            'Box',       'on', ...
            'LineWidth', 0.5, ...
            'XColor',    [0.70 0.70 0.70], ...
            'YColor',    [0.70 0.70 0.70]);

        img_path = find_sample_image(img_dir, samples{s});
        if ~isempty(img_path)
            imshow(imread(img_path), 'Parent', th_ax);
        else
            fill(th_ax, [0 1 1 0], [0 0 1 1], [0.93 0.93 0.93], 'EdgeColor', 'none');
            text(th_ax, 0.5, 0.5, samples{s}, ...
                'Units',               'normalized', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'FontName',            fig_font, ...
                'FontSize',            font_sz_ax - 1, ...
                'Color',               [0.55 0.55 0.55]);
            xlim(th_ax, [0 1]); ylim(th_ax, [0 1]);
        end

        annotation(fig, 'textbox', ...
            [th_col_x + lbl_x_off, row_cy - row_h*0.22, th_w - lbl_x_off, row_h*0.44], ...
            'String',              samples{s}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment',   'middle', ...
            'EdgeColor',           'none', ...
            'Color',               col, ...
            'FontName',            fig_font, ...
            'FontSize',            font_sz_ax, ...
            'FontWeight',          'bold', ...
            'Interpreter',         'none');
    end

    % 7. Export
    out_path = fullfile(base_dir, out_names{panel});
    exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
    fprintf('Saved: %s\n', out_path);
    close(fig);
end


%% ── Helper ────────────────────────────────────────────────────────────────
function p = find_sample_image(img_dir, sample_name)
    p = '';
    if ~isfolder(img_dir), return; end
    for ext = {'.png', '.jpg', '.jpeg', '.PNG', '.JPG', '.tif', '.tiff'}
        c = fullfile(img_dir, [sample_name ext{1}]);
        if isfile(c), p = c; return; end
    end
end
