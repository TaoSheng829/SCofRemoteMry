%% SpikeMat_for_tet_nontet.m: Build and extend the spike table with new data
% This script performs two main tasks:
%   1. For older data (1‑155): adds 'matdata_path' and 'wave' columns to
%      the existing spike table by loading from encoding folders.
%   2. For newer tetrode data: processes .mat files containing ts/wave
%      structures, groups units by 4‑channel blocks, selects the best unit
%      per group (largest waveform amplitude), and appends to the spike table.

%% ===================== Part 1: Process older data (1‑155) =====================
% Add 'matdata_path' (path to .mat file) and 'wave' (waveform matrix)
% columns to the spike table for existing data.

clear; clc;
LFPpath = '';
load('SpikeTable2.mat');
load([LFPpath, 'encodelist.mat']);

% ---- 1a: Build matdata_path for each row ----
matdata_path = {};
for i = 1:155
    tempName = char(spike.animal(i));
    AnmID = tempName(1:7);                     % First 7 characters = animal ID
    matdata_path{i} = [LFPpath, AnmID, '\', tempName, '.mat'];
end
spike = addvars(spike, matdata_path', 'NewVariableNames', 'matdata_path');

% ---- 1b: Load waveform data for each unit ----
wave_temp = {};
kk = 1;
temppath_pre = [];

for i = 1:155
    temppath = spike.matdata_path{i};

    % Only load the .mat file if it's different from the previous one
    if i == 1 || ~isequaln(temppath, temppath_pre)
        load(spike.matdata_path{i});   % Loads 'tsList', 'ts', 'wave'

        % For each unit in tsList, extract the corresponding waveform
        for ii = 1:length(tsList)
            tsName = tsList{ii};
            waveName = strrep(tsName, 'ts', 'wave');   % 'ts_01_2' → 'wave_01_2'
            wave_temp{kk} = eval(['wave.', waveName]);
            kk = kk + 1;
        end
        temppath_pre = temppath;
    else
        fprintf('Skipping row %d: duplicate file path\n', i);
    end
end

spike = addvars(spike, wave_temp', 'NewVariableNames', 'wave');

%% ===================== Part 2: Process new tetrode data =======================
% Read .mat files from a tetrode recording folder, group units by channel
% blocks, select the best unit per group, and append to the spike table.

clear; clc;
load('**.mat');

pl2_path = '';
file_list = dir([pl2_path, '*.mat']);
file_num = size(file_list, 1);

for i = 1:file_num
    file_locat = [file_list(i).folder, '\', file_list(i).name];
    load(file_locat);   % Loads 'tsList', 'ts', 'wave'

    % ---- Step 1: Group units by 4‑channel blocks ----
    groupedData = groupTSList(tsList);

    % ---- Step 2: For each group, select the unit with largest waveform amplitude ----
    selectedChannels = selectChannelsByWaveAmplitude(groupedData, ts, wave);

    % ---- Step 3: Append selected units to the spike table ----
    for ii = 1:length(selectedChannels)
        tsName = selectedChannels{ii};
        newRow_channel = str2double(tsName(4:5));       % Extract channel number
        newRow_ts = eval(['ts.', tsName]);              % Timestamp data
        waveName = strrep(tsName, 'ts', 'wave');        % Waveform field name
        newRow_wave = eval(['wave.', waveName]);        % Waveform matrix

        % Determine brain region based on channel number
        if newRow_channel >= 1 && newRow_channel <= 16
            newRow_region = 'HPC';
        else
            newRow_region = 'PFC';
        end

        newRow_animal = strrep(file_list(i).name, '.mat', '');
        newRow_matdata_path = file_locat;

        % Create a new row as a cell array and append
        newRow = {newRow_channel, newRow_ts, newRow_region, newRow_animal, ...
                  [], newRow_matdata_path, newRow_wave};
        spike = [spike; newRow];
    end

    fprintf('%s   done\n', file_locat);
end