%% plot_multimodal_physiological_data.m
% This script contains multiple independent blocks for plotting and
% preprocessing various physiological signals:
%   1. State labels and EMG (from FP channel)
%   2. Motion index (video-based similarity) – concatenation, cleaning, interpolation
%   3. Binary motion index (thresholded)
%   4. Blood oxygen saturation (SpO2) – cleaning and interpolation
%   5. Heart rate – cleaning and interpolation
%   6. Breathing rate – cleaning and interpolation
%
% Each block can be run separately. The plotting commands are included but
% save commands are commented out (use as needed).

%% ===================== 1. State labels and EMG ============================
% Load a pre-existing 'labels' variable and FP structure, then plot.

plot(labels);        % Plot state labels (1=REM, 2=Awake, 3=NREM, etc.)
% filename = '**.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

EMG = FP.FP31;       % Extract EMG channel (assumes FP structure in workspace)
plot(EMG);           % Plot raw EMG
ylim([-0.2 0.2]);    % Set Y-axis limits for EMG
% filename = '**.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

%% ===================== 2. Motion index (video similarity) ==================
% Concatenate all .mat files in a folder (each contains 'Cssimval0' vector),
% then clean outliers (>20) and interpolate missing values using pchip.

clear; clc;

path1 = '';   % Folder with video-derived .mat files
file_list = dir([path1, '*.mat']);                      % List all .mat files
file_num = size(file_list, 1);
Cssimval00 = [];

% Concatenate all similarity vectors
for i = 1:file_num
    f = [file_list(i).folder, '\', file_list(i).name];
    load(f);                     % Loads 'Cssimval0'
    Cssimval00 = [Cssimval00, Cssimval0];
end

% plot(Cssimval00);              % (Optional) raw concatenated data

%% ===================== 2b. Clean and interpolate motion index ==============
% Set values >20 to NaN (artifacts), then interpolate with pchip.

data_cleaned = Cssimval00;
data_cleaned(data_cleaned > 20) = NaN;

x = 1:length(Cssimval00);
valid_mask = ~isnan(data_cleaned);
interpolated_data = interp1(x(valid_mask), data_cleaned(valid_mask), x, 'pchip');

plot(interpolated_data);
% filename = 'Y:\数据备份\AAA_response\问题分解与对应程序\resting and NREM\Rem sample\MotionIndex.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

%% ===================== 3. Binary motion index ==============================
% Convert the interpolated motion index to binary (1 = motion, 0 = rest)
% using a threshold of 1.2.

binary_array = interpolated_data > 1.2;
plot(binary_array);

%% ===================== 4. Blood oxygen saturation (SpO2) ==================
% Load Export15Hz structure (from a pulse oximeter), clean error codes
% and outliers, then interpolate.

A = Export15Hz.ArterialO2;   % SpO2 values
B = Export15Hz.Error;        % Error codes

% Remove points with error codes: 4,6,7,8,9  and values below 90
A_cleaned = A;
remove_indices = ismember(B, [4, 6, 7, 8, 9]);
A_cleaned(remove_indices) = NaN;
A_cleaned(A_cleaned < 90) = NaN;

% Interpolate missing values
x = 1:length(A_cleaned);
valid_mask = ~isnan(A_cleaned);
A_interpolated = interp1(x(valid_mask), A_cleaned(valid_mask), x, 'pchip');

plot(A_interpolated);
ylim([50 100]);
% filename = 'Y:\数据备份\AAA_response\问题分解与对应程序\resting and NREM\Rem sample\SpO2.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

%% ===================== 5. Heart rate ======================================
% Clean heart rate data using error codes and outliers (>500), then interpolate.

% (Optional) Quick raw plot with error overlay:
% plot(Export15Hz.Heart);
% hold on;
% plot(Export15Hz.Error*10);
% hold off;

A = Export15Hz.Heart;
B = Export15Hz.Error;

A_cleaned = A;
remove_indices = ismember(B, [2, 6, 8, 9]);   % Error codes to remove
A_cleaned(remove_indices) = NaN;
A_cleaned(A_cleaned > 500) = NaN;

x = 1:length(A_cleaned);
valid_mask = ~isnan(A_cleaned);
A_interpolated = interp1(x(valid_mask), A_cleaned(valid_mask), x, 'pchip');

plot(A_interpolated);
ylim([200 800]);
% filename = 'Y:\数据备份\AAA_response\问题分解与对应程序\resting and NREM\Rem sample\HR.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

%% ===================== 6. Breathing rate ==================================
% Clean breathing rate data with error codes and outliers (>500), then interpolate.

% (Original quick plot commented out)
% plot(Export15Hz.Breath);

A = Export15Hz.Breath;
B = Export15Hz.Error;

A_cleaned = A;
remove_indices = ismember(B, [2, 3, 6, 7, 8, 9]);
A_cleaned(remove_indices) = NaN;
A_cleaned(A_cleaned > 500) = NaN;

x = 1:length(A_cleaned);
valid_mask = ~isnan(A_cleaned);
A_interpolated = interp1(x(valid_mask), A_cleaned(valid_mask), x, 'pchip');

plot(A_interpolated);
ylim([50 250]);
% filename = 'Y:\数据备份\AAA_response\问题分解与对应程序\resting and NREM\Rem sample\BR.eps';
% print(gcf, '-depsc', '-painters', '-r300', filename);

%% ===================== 7. Miscellaneous ====================================
% This line (caxis) is likely from a previous spectrogram plot and is not
% used in this script – kept as a placeholder.
caxis([0 0.0008]);