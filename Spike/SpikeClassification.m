%% SpikeClassification.m: Comprehensive spike classification and analysis pipeline
% This script performs multiple analyses on spike data:
%   1. Calculates mean waveform parameters (half‑width, firing rate)
%   2. Performs K‑means clustering to classify neurons into two types
%   3. Labels neurons as PN (putative pyramidal) or IN (putative interneuron)
%   4. Tests for theta phase locking (using PFC theta)
%   5. Tests for theta phase locking (using HPC theta for older data)
%   6. Generates and saves individual waveform plots with SEM shading

clear; clc;
load('**.mat');

%% ===================== 1. Compute mean waveform parameters ====================
% The spike table's 7th column ('wave') is assumed to be an n×32 matrix.
% For each unit, compute half‑width (μs) and firing rate (Hz).
HPC_spike_param = [];
PFC_spike_param = [];

for i = 1:height(spike)
    wave_data = spike.wave{i};          % n×32 waveform matrix
    ts_data = spike.ts{i};              % Spike timestamps (seconds)
    region_data = spike.region{i};      % Brain region: 'HPC' or 'PFC'

    [hw, fr] = calculateMeanSpikeParams(wave_data, ts_data);

    % Store results with row index, half‑width, and firing rate
    if strcmp(region_data, 'HPC')
        HPC_spike_param = [HPC_spike_param; i, hw, fr];
    else
        PFC_spike_param = [PFC_spike_param; i, hw, fr];
    end
end

%% ===================== 2. K‑means clustering for classification ===============
% Use half‑width and firing rate to cluster neurons into two types.
% X = HPC_spike_param(:, 2:3);   % For HPC neurons only
X = PFC_spike_param(:, 2:3);      % For PFC neurons only

opts = statset('Display', 'final');
[idx, C] = kmeans(X, 2, 'Distance', 'sqeuclidean', ...
    'Replicates', 5, 'Options', opts);

% Count samples in each cluster
cluster1_count = sum(idx == 1);
cluster2_count = sum(idx == 2);

% ---- Visualise clustering results ----
figure;

% Cluster 1: red filled circles
plot(X(idx == 1, 1), X(idx == 1, 2), 'ro', ...
    'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 8);
hold on;

% Cluster 2: blue filled circles
plot(X(idx == 2, 1), X(idx == 2, 2), 'bo', ...
    'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'MarkerSize', 8);

% Cluster centroids: black crosses
plot(C(:, 1), C(:, 2), 'kx', 'MarkerSize', 15, 'LineWidth', 3);

legend(sprintf('Cluster 1 (n=%d)', cluster1_count), ...
       sprintf('Cluster 2 (n=%d)', cluster2_count), ...
       'Centroids', 'Location', 'NW');

title(sprintf('Cluster Assignments (Total n=%d)\nCluster 1: n=%d, Cluster 2: n=%d', ...
      size(X, 1), cluster1_count, cluster2_count));
hold off;

%% ===================== 3. Write classification labels to table ================
% Label cluster 1 as 'PN' (putative pyramidal) and cluster 2 as 'IN' (interneuron).
% Note: This logic may need reversal depending on the data.
spike.cf = zeros(height(spike), 0);   % 'cf' = cell type classification

for i = 1:length(PFC_spike_param)
    if idx(i) == 1
        spike.cf{PFC_spike_param(i, 1)} = 'PN';
    else
        spike.cf{PFC_spike_param(i, 1)} = 'IN';
    end
end

for i = 1:length(HPC_spike_param)
    if idx(i) == 1
        spike.cf{HPC_spike_param(i, 1)} = 'PN';
    else
        spike.cf{HPC_spike_param(i, 1)} = 'IN';
    end
end

%% ===================== 4. Theta phase locking (PFC theta, newer data) ========
% For units 156‑326 (newer data), test locking to PFC theta (FP17).
clear; clc;
load('**.mat');

spike.lockpd = zeros(height(spike), 0);

for data_n = 156:326
    load(spike.matdata_path{data_n}, 'FP');
    voltage_data = FP.FP17;     % PFC channel for theta
    fs = 1000;
    spike_times = spike.ts{data_n};
    analysis_window = [40, 100];   % Window for phase locking test

    [is_locked, p_value, mean_phase, strength] = check_theta_phase_locking(...
        voltage_data, spike_times, analysis_window, fs);

    if is_locked
        spike.lockpd{data_n} = 'locked';
    else
        spike.lockpd{data_n} = 'non-locked';
    end
end

%% ===================== 5. Theta phase locking (HPC theta, older data) ========
% For units 1‑155 (older data), test locking to HPC theta (FP34) using
% encoding session timing (bft + lag).
LFPpath = '';
load([LFPpath, 'encodelist.mat']);
load([LFPpath, 'timestamp.mat']);

for data_n = 1:155
    load(spike.matdata_path{data_n}, 'FP');

    tempName = char(spike.animal(data_n));
    strlag = encode.strlag(find(encode.filename == tempName));   % Start lag (samples)

    voltage_data = FP.FP34;      % HPC channel for theta
    fs = 1000;
    spike_times = spike.ts{data_n};

    % Use baseline + first ITI as analysis window (with lag correction)
    analysis_window = bft + strlag / 1000;

    [is_locked, p_value, mean_phase, strength] = check_theta_phase_locking(...
        voltage_data, spike_times, analysis_window, fs);

    if is_locked
        spike.lockpd{data_n} = 'locked';
    else
        spike.lockpd{data_n} = 'non-locked';
    end
end

%% ===================== 6. Generate and save waveform plots ===================
% For each unit (1‑326), plot the mean waveform with SEM shading and save
% as both EPS and JPG.
clear; clc;
load('**.mat');

for data_n = 1:326
    tempTs = spike.wave{data_n};   % n×32 waveform matrix

    % Compute mean and standard error (SEM)
    mean_data = mean(tempTs, 1);                % 1×32 mean vector
    std_data = std(tempTs, 0, 1);               % 1×32 SD vector
    n = size(tempTs, 1);
    sem_data = std_data;                        % (or /sqrt(n) for SEM)

    upper_bound = mean_data + sem_data;
    lower_bound = mean_data - sem_data;

    % Create figure
    hold on;

    line_color = 'b';
    shade_color = [0.8, 0.8, 1];   % Light blue

    % Plot SEM shading using fill
    x_shade = 1:length(mean_data);
    fill([x_shade, fliplr(x_shade)], ...
         [upper_bound, fliplr(lower_bound)], ...
         shade_color, 'EdgeColor', 'none', 'FaceAlpha', 0.3);

    % Plot mean waveform
    plot(x_shade, mean_data, 'Color', line_color, 'LineWidth', 1.5);

    xlabel('Sample index (1‑32)');
    ylabel('Amplitude (mV)');
    title(sprintf('Mean ± SEM (n=%d)', n));
    grid on;
    hold off;

    ylim([-0.3, 0.2]);
    xlim([1, 32]);

    set(gcf, 'Renderer', 'painters');
    saveas(gca, ['\wave_', num2str(data_n), '.eps'], 'psc2');
    saveas(gca, ['\wave_', num2str(data_n), '.jpg']);
end