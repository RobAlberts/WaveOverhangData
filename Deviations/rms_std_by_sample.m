%% Wave Overhang — RMS + Std Deviation per Material by Sample (two-panel)
% Left panel  : RMS deviation  — one smooth line per material
% Right panel : Standard deviation — same layout
% X-axis      : test samples (TS01–TS06) with thumbnails below
% Lines       : one per material (PLA, PLA-CF, PLA-GF, PETG, PETG-CF, ABS)
%
% Lines are smoothed with pchip interpolation between sample points.
%
% Folder structure expected:
%   <script_dir>/<Material>/TS0X.csv
%   <script_dir>/Images/TS0X.png   (optional thumbnails for x-axis)

clear; clc; close all;

% ── Configuration ─────────────────────────────────────────────────────────
base_dir = fileparts(mfilename('fullpath'));
dev_dir  = base_dir;
dev_col  = 'Dev';
img_dir  = fullfile(base_dir, 'Images');

fig_font    = 'Times New Roman';
font_sz_ax  = 9;
font_sz_ttl = 12;
font_sz_thn = 10;
fig_w_mm    = 280;
fig_h_mm    = 140;   % slightly taller to fit thumbnails below x-axis
dpi         = 300;
thumb_h     = 0.08;  % thumbnail height in normalised figure units

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

% 3. Colors and markers — one per material
material_colors = [
    0.18, 0.55, 0.25;   % PLA     — green
    0.12, 0.47, 0.71;   % PLA-CF  — blue
    0.58, 0.20, 0.58;   % PLA-GF  — purple
    0.88, 0.43, 0.06;   % PETG    — orange
    0.79, 0.17, 0.17;   % PETG-CF — red
    0.40, 0.40, 0.40;   % ABS     — grey
];
marker_styles = {'o', 's', '^', 'd', 'v', 'p'};

% 4. Figure layout (all in normalised figure units)
fig_w_cm = fig_w_mm / 10;
fig_h_cm = fig_h_mm / 10;
fig = figure('Name', 'RMS and Std Deviation by Sample', 'Color', 'w', ...
             'Units', 'centimeters', ...
             'Position', [2 2 fig_w_cm fig_h_cm]);

lm    = 0.07;   % left margin
bm    = 0.16;   % bottom margin (room for thumbnails below x-axis)
tm    = 0.10;   % top margin
gap   = 0.04;   % gap between the two plots
pw    = (1 - lm - gap) / 2;   % each panel width
ph    = 1 - bm - tm;          % panel height

ax1 = axes(fig, 'Position', [lm,        bm, pw, ph]);
ax2 = axes(fig, 'Position', [lm+pw+gap, bm, pw, ph]);

x_vals = 1:nS;   % x-axis = sample indices

% 5. Draw both panels
panels = {ax1, ax2};
datas  = {rms_mat, std_mat};
titles = {'RMS deviation  (mm)', 'Standard deviation  (mm)'};
ylbls  = {'RMS deviation  (mm)', 'Standard deviation  (mm)'};

leg_handles = gobjects(nM, 1);   % legend handles from ax2

for panel = 1:2
    ax  = panels{panel};
    dat = datas{panel};   % nS × nM
    hold(ax, 'on');

    for m = 1:nM
        col_m = dat(:, m)';         % 1 × nS values for this material
        valid  = ~isnan(col_m);
        if sum(valid) < 1, continue; end
        xv  = x_vals(valid);
        yv  = col_m(valid);
        col = material_colors(min(m, size(material_colors, 1)), :);
        mk  = marker_styles{min(m, numel(marker_styles))};

        % Smooth pchip curve through valid sample points
        if sum(valid) >= 3
            xf = linspace(min(xv), max(xv), 400);
            yf = pchip(xv, yv, xf);
        elseif sum(valid) == 2
            xf = xv;  yf = yv;
        else
            xf = xv;  yf = yv;
        end

        plot(ax, xf, yf, '-', ...
            'Color',             col, ...
            'LineWidth',         1.5, ...
            'HandleVisibility',  'off');

        h = scatter(ax, xv, yv, 32, mk, ...
            'MarkerFaceColor',   col, ...
            'MarkerEdgeColor',   col * 0.60, ...
            'LineWidth',         0.8, ...
            'DisplayName',       materials{m});

        % Collect legend handles from the second panel only
        if panel == 2
            leg_handles(m) = h;
        else
            set(h, 'HandleVisibility', 'off');
        end
    end

    all_vals = dat(:);
    y_max = max(all_vals(isfinite(all_vals))) * 1.15;
    if isempty(y_max) || ~isfinite(y_max), y_max = 1; end

    set(ax, ...
        'XTick',             x_vals, ...
        'XTickLabel',        {}, ...   % replaced by thumbnails below
        'XLim',              [0.5, nS + 0.5], ...
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
end

% 6. Legend on ax2 (right panel)
valid_handles = leg_handles(isgraphics(leg_handles));
legend(ax2, valid_handles, ...
    'Location',  'northeast', ...
    'FontName',  fig_font, ...
    'FontSize',  font_sz_ax, ...
    'EdgeColor', [0.75 0.75 0.75], ...
    'Color',     'w', ...
    'TextColor', 'k', ...
    'Box',       'on');

% 7. Thumbnails below x-axis — one set per panel
add_image_labels(fig, ax1, samples, img_dir, thumb_h, font_sz_thn, fig_font);
add_image_labels(fig, ax2, samples, img_dir, thumb_h, font_sz_thn, fig_font);

% 8. Export
out_path = fullfile(base_dir, 'rms_std_by_sample.png');
exportgraphics(fig, out_path, 'Resolution', dpi, 'BackgroundColor', 'w');
fprintf('Saved: %s\n', out_path);


%% ── Helpers ───────────────────────────────────────────────────────────────

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
