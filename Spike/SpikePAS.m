%% SpikePAS.m: Compute phase precession (PAS) and firing rate metrics
% This script calculates phase precession (phase vs. ITI index) using
% the theta phase of either PFC or HPC, and also computes firing rates
% during baseline and the first ITI. It processes newer data (rows 156‑326)
% and older data (rows 1‑155) separately.

clear; clc;
load('**.mat');

%% ===================== Example: Single unit analysis =====================
% Demonstrates usage of calculate_phase_preference for one unit.
data_n = 162;
load(spike.matdata_path{data_n}, 'FP');
voltage_data = FP.FP17;   % PFC theta
fs = 1000;
spike_times = spike.ts{data_n};

time_windows = [40, 100; 140, 200; 240, 300; 340, 400; 440, 500];
result = calculate_phase_preference(voltage_data, spike_times, time_windows, 1000);

%% ===================== Part 1: PAS for newer data (PFC theta) ============
% Compute phase precession (r², p, slope) using PFC theta (FP17) for units 156‑326.
clear; clc;
load('**.mat');

spike.r2 = zeros(height(spike), 0);
spike.p = zeros(height(spike), 0);
spike.slope = zeros(height(spike), 0);

for data_n = 156:326
    load(spike.matdata_path{data_n}, 'FP');
    voltage_data = FP.FP17;   % PFC theta channel
    fs = 1000;
    spike_times = spike.ts{data_n};

    time_windows = [40, 100; 140, 200; 240, 300; 340, 400; 440, 500];

    result = calculate_phase_preference(voltage_data, spike_times, time_windows, 1000);

    spike.r2{data_n} = result.r2;
    spike.p{data_n} = result.p;
    spike.slope{data_n} = result.slope;

    fprintf('Processed unit %d\n', data_n);
end

% ---- Compute firing rates for baseline and first ITI ----
spike.preFC_FR = zeros(height(spike), 0);
spike.ITI1_FR = zeros(height(spike), 0);

for data_n = 156:326
    load(spike.matdata_path{data_n}, 'FP');
    voltage_data = FP.FP17;
    fs = 1000;
    spike_times = spike.ts{data_n};

    time_windows = [0, 40; 40, 100];   % Baseline and first ITI

    [rates, ~, ~] = calculate_firing_rate(spike_times, time_windows);
    spike.preFC_FR{data_n} = rates(1);
    spike.ITI1_FR{data_n} = rates(2);

    fprintf('Processed firing rates for unit %d\n', data_n);
end

%% ===================== Part 2: PAS for newer data (HPC theta) ============
% Same as Part 1 but using HPC theta (FP02) instead of PFC.
clear; clc;
load('**.mat');

spike.r2 = zeros(height(spike), 0);
spike.p = zeros(height(spike), 0);
spike.slope = zeros(height(spike), 0);

for data_n = 156:326
    load(spike.matdata_path{data_n}, 'FP');
    voltage_data = FP.FP02;   % HPC theta channel (Note: FP02 is used for HPC theta)
    fs = 1000;
    spike_times = spike.ts{data_n};

    time_windows = [40, 100; 140, 200; 240, 300; 340, 400; 440, 500];

    result = calculate_phase_preference(voltage_data, spike_times, time_windows, 1000);

    spike.r2{data_n} = result.r2;
    spike.p{data_n} = result.p;
    spike.slope{data_n} = result.slope;

    fprintf('Processed unit %d\n', data_n);
end

% Firing rates using HPC theta (same windows)
spike.preFC_FR = zeros(height(spike), 0);
spike.ITI1_FR = zeros(height(spike), 0);

for data_n = 156:326
    load(spike.matdata_path{data_n}, 'FP');
    voltage_data = FP.FP02;
    fs = 1000;
    spike_times = spike.ts{data_n};

    time_windows = [0, 40; 40, 100];

    [rates, ~, ~] = calculate_firing_rate(spike_times, time_windows);
    spike.preFC_FR{data_n} = rates(1);
    spike.ITI1_FR{data_n} = rates(2);

    fprintf('Processed firing rates for unit %d\n', data_n);
end

%% ===================== Part 3: PAS for older data (HPC theta) ============
% Compute phase precession using HPC theta (FP34) for units 1‑155,
% using encoding session timing (iti1‑iti5 and bft).
LFPpath = '';
load([LFPpath, 'encodelist.mat']);
load([LFPpath, 'timestamp.mat']);

for data_n = 1:155
    load(spike.matdata_path{data_n}, 'FP');

    tempName = char(spike.animal(data_n));
    strlag = encode.strlag(find(encode.filename == tempName));

    voltage_data = FP.FP34;   % HPC theta
    fs = 1000;
    spike_times = spike.ts{data_n};

    % ITI windows for phase precession (5 ITIs)
    time_windows = [iti1; iti2; iti3; iti4; iti5] + strlag / 1000;
    result = calculate_phase_preference(voltage_data, spike_times, time_windows, 1000);

    spike.r2{data_n} = result.r2;
    spike.p{data_n} = result.p;
    spike.slope{data_n} = result.slope;

    % Firing rates: baseline (bft) and first ITI
    time_windows_fr = [bft; iti1] + strlag / 1000;
    [rates, ~, ~] = calculate_firing_rate(spike_times, time_windows_fr);

    spike.preFC_FR{data_n} = rates(1);
    spike.ITI1_FR{data_n} = rates(2);

    fprintf('Processed unit %d\n', data_n);
end

%% ===================== Part 4: Extract HPC data for plotting =============
% Collect HPC unit metrics (r², p, slope, preFC_FR, ITI1_FR) into a table.
clear; clc;
load('**.mat');

HPC_table = [];
kk = 1;

for data_n = 156:326
    region_data = spike.region{data_n};
    if strcmp(region_data, 'HPC')
        HPC_table = [HPC_table; ...
            spike.r2{data_n}, spike.p{data_n}, spike.slope{data_n}, ...
            spike.preFC_FR{data_n}, spike.ITI1_FR{data_n}];
        kk = kk + 1;
    end
end