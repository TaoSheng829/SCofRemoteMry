% Sort_response_data_sum.m
% This script builds a structured experimental dataset for multiple animals
% across multiple days (post‑surgery days -1 to 28). It collects file paths
% for LFP, motion (video), and state labels, loads AI (analog input) data,
% aligns motion data to LFP timestamps, and applies a state classification
% function (classify_awake_states). The resulting structure is saved as
% 'full_response_experiment_datapath.mat' (loaded at the beginning of the
% second section).
%
% The script is organized into several parts:
%   1. Define the main experiment structure with metadata.
%   2. Manually add animal-specific path information (only one animal is
%      populated in this snippet; others are likely added similarly).
%   3. Populate the file location list from PL2 files.
%   4. Load the saved experiment structure and process each day: load AI,
%      motion data, state labels, align and classify states.

%% ================== PART 1: Build main experiment structure ==================
% Initialize the main experiment container
experiment = struct();

% Experiment-level metadata
experiment.Info.AnimalCount = 6;                           % Total number of animals
experiment.Info.Days = -1:28;                              % Days relative to surgery (day 0 = surgery)
experiment.Info.Motion_SamplingRate = 1;                   % Motion data sampling rate (Hz)
experiment.Info.LFP_SamplingRate = 1000;                  % LFP sampling rate (Hz)
experiment.Info.oximeter_SamplingRate = 15;               % Oximeter (respiration) sampling rate (Hz)
experiment.Info.Animalidlist = {};

% Define state labels with hierarchical numbering (used for sleep/wake scoring)
experiment.StateLabels = {
    1, 'REM';
    2, 'Awake';
        2.1, 'Awake_resting';
        2.2, 'Awake_locomotion';
    3, 'NREM';
    4, 'Invalid'
};

% Initialize the cell array that will hold per-animal structures
experiment.Animals = {};

%% ================== PART 2: Manually add animal data ========================
% This section adds information for the first animal (index 1). Additional
% animals would be added in a similar loop or by repeating this block.
animalIdx = 1;
animal = struct();
animal.ID = experiment.Info.Animalidlist{animalIdx};      % Animal ID string
animal.StateInterval = 2.5;                               % Epoch length for state scoring (seconds)
animal.oximeterNA = false;                                % Flag: true if oximeter data is not available

% Loop over all days (from -1 to 28)
for dayIdx = 1:length(experiment.Info.Days)
    dayNum = experiment.Info.Days(dayIdx);
    animal.Days(dayIdx).DayNumber = dayNum;

    % Paths for LFP data (AI channels) – will be filled later from file list
    animal.Days(dayIdx).LFP_AI_path = char(file_locat(dayIdx, 1));
    animal.Days(dayIdx).LFP_AI_foldname = char(file_locat(dayIdx, 2));

    % Path for state label files (pre‑computed sleep/wake scoring)
    animal.Days(dayIdx).State_path = ['Y:\数据备份\AAA_response\', animal.ID, '\state\label\epoch', num2str(animal.StateInterval), '\'];
    animal.Days(dayIdx).State_data = [];

    % Path for motion (video‑derived) data
    animal.Days(dayIdx).Motion_path = ['Y:\数据备份\AAA_response\', animal.ID, '\video\', animal.Days(dayIdx).LFP_AI_foldname, '\'];
    animal.Days(dayIdx).Motion_data = [];

    % If oximeter data is available, set its path (currently disabled)
    if animal.oximeterNA
        animal.Days(dayIdx).oximeter_path = ['Y:\数据备份\AAA_response\', animal.ID, '\respiration\csv\', animal.Days(dayIdx).LFP_AI_foldname, '\'];
        animal.Days(dayIdx).oximeter_data = [];
    end
end

% Store the completed animal structure in the experiment container
experiment.Animals{animalIdx} = animal;

%% ================== PART 3: Populate file location list =====================
% This section generates the LFP_AI_path and foldername for each PL2 file
% found in the animal's main directory. It is executed before the loop above,
% so that 'file_locat' is defined when used in the animal.Days assignment.
%
% NOTE: In the original script, this block appears after the animal structure
% definition. However, it is executed in the same workspace, so 'file_locat'
% is available when building the Days structure (as used above).
pl2_path = ['Y:\数据备份\AAA_response\', animal.ID, '\'];
file_list = dir([pl2_path, '*.pl2']);
file_num = size(file_list, 1);
file_locat = {};

for i = 1:file_num
    % For each .pl2 file, store the folder containing the extracted 'FP' data
    file_locat{i, 1} = [file_list(i).folder, '\', strrep(file_list(i).name, '.pl2', '\FP\')];
    % Store the base filename (without extension)
    file_locat{i, 2} = strrep(file_list(i).name, '.pl2', '');
end

%% ================== PART 4: Process each day using saved structure =========
% Clear workspace and load the previously saved experiment structure
clear; clc; close all;
load(['Y:\数据备份\AAA_response\A_response_data_sum\full_response_experiment_datapath.mat']);

animalIdx = 1;   % Only processing the first animal in this snippet

% Loop over all days for this animal
for dayIdx = 1:length(experiment.Info.Days)
    fold_name = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_foldname;
    LFP_AI_path = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_path;
    load([LFP_AI_path, 'AI.mat']);   % Loads variable 'AI' (structure with AI01...AI64)

    % ---- Load motion data from the video folder ----
    Motion_path = experiment.Animals{animalIdx}.Days(dayIdx).Motion_path;
    Motion_result = [];
    % Concatenate all .mat files in the motion folder (each contains Cssimval0)
    for f = dir([Motion_path, '*.mat'])'
        Motion_result = [Motion_result; load([Motion_path, f.name], 'Cssimval0').Cssimval0(:)];
    end
    % (Optional) plot the raw motion data
    % plot(Motion_result);

    % Interpolate outliers (values >15) using linear interpolation from valid points
    Motion_result(Motion_result > 15) = interp1(find(Motion_result <= 15), ...
        Motion_result(Motion_result <= 15), find(Motion_result > 15), 'linear', 'extrap');
    % figure; plot(Motion_result);

    % Store the processed motion data back into the experiment structure
    experiment.Animals{animalIdx}.Days(dayIdx).Motion_data = Motion_result;

    % ---- Determine the start time of the AI recording ----
    % Find the first sample where AI04 exceeds 2000 (presumably a TTL or sync pulse)
    first_time = find(AI.AI04 > 2000, 1, 'first') / 1000;   % Convert samples to seconds
    if isempty(first_time)
        first_time = -1;   % If no pulse found, set to -1 as a flag
    end

    % ---- Manual offset correction using a GUI input dialog ----
    % This allows the user to specify a known time offset (minutes:seconds)
    winopen(Motion_path);   % Open the motion folder in Windows Explorer (for reference)
    input_vals = inputdlg({'分钟:', '秒:'}, '输入时间', 1, {'0', '0'});
    input_seconds = str2double(input_vals{1}) * 60 + str2double(input_vals{2});

    % Compute offset: if first_time exists, use it; otherwise use the input as a negative offset
    offset = (first_time ~= -1) * (first_time - input_seconds) - (first_time == -1) * input_seconds;

    % Align motion data to the AI recording length (truncate or pad)
    Motion_result_aligned = Motion_result(max(1, round(offset + 1)) : ...
        min(length(Motion_result), round(offset + length(AI.AI04) / 1000)));

    % ---- Load state labels (sleep/wake scoring) ----
    State_path = experiment.Animals{animalIdx}.Days(dayIdx).State_path;
    load([State_path, fold_name]);   % Loads variable 'labels' (epoch‑wise state labels)

    % ---- Classify awake states into resting vs. locomotion ----
    % The function classify_awake_states uses motion data to refine the labels
    [new_labels, ~] = classify_awake_states(Motion_result_aligned, labels, 2.5);
    % plot(new_labels); figure; plot(labels);

    % At this point, the aligned motion data and refined state labels are
    % available in the workspace but are not yet stored back into the
    % experiment structure. This may be done later in the full script.

    % (The loop continues to the next day)
end