%% pl22Co.m: Compute coherence between selected LFP channel pairs for all PL2 files
% This script loads pre‑converted .mat files (from PL2) containing 64‑channel
% LFP data, and computes the magnitude‑squared coherence (using the Chronux
% function cohgramc) for selected cross‑area channel pairs:
%   - PFC (channels 1,6,11,16) vs. ACC (21,26,31)
%   - PFC vs. HPC (33,38,43)
%   - PFC vs. PPC (49,54,59)
%   - ACC vs. HPC
%   - ACC vs. PPC
%   - HPC vs. PPC
%
% The coherence is computed with a moving window (1‑s window, 0.5‑s step),
% and the results are saved as .mat files in the same folder as the original
% PL2 file (inside a subdirectory with the same base name).

clear; clc;

%% ---- Configuration ----
path1 = '';   % Root folder containing .pl2 files
cd(path1);

% Get list of all .pl2 files in the folder
file_list = dir([path1, '*.pl2']);
file_num = size(file_list, 1);

%% ---- Loop over each PL2 file ----
for i = 1:file_num
    f = [file_list(i).folder, '\', file_list(i).name];

    % Create a subfolder named after the .pl2 file (without extension)
    baseName = erase(f, '.pl2');
    if ~exist([baseName, '\'], 'dir')
        mkdir([baseName, '\']);
    end

    % Load the .mat file (assumes it was previously converted from PL2)
    % This file should contain a structure 'FP' with fields FP01, FP02, ..., FP64.
    load([baseName, '.mat']);

    % ---- Build a matrix of all 64 LFP channels (time × channel) ----
    % Note: 'tempFP' is cleared and re‑built for each file.
    clearvars tempFP
    for ch_i = 1:64
        eval(['tempFP(:, ch_i) = FP.FP', num2str(ch_i, '%02d'), ';']);
    end
    clearvars FP   % Free memory after extracting

    % ---- Set parameters for coherence analysis (Chronux toolbox) ----
    % movingwin: [window_length (s), step_size (s)]
    % tapers: [time‑bandwidth product, number of tapers]
    % pad: 0 = no padding
    % Fs: sampling rate (Hz)
    % fpass: [low_freq, high_freq] in Hz
    % err: [0,1] = no error bars
    % trialave: 0 = no averaging across trials
    params.movingwin = [1, 0.5];
    params.tapers = [5, 9];
    params.pad = 0;
    params.Fs = 1000;
    params.fpass = [0, 120];
    params.err = [0, 1];
    params.trialave = 0;

    %% ---- Compute coherence for each selected channel pair ----
    % The selected channels represent:
    %   PFC:  [1, 6, 11, 16]
    %   ACC:  [21, 26, 31]
    %   HPC:  [33, 38, 43]
    %   PPC:  [49, 54, 59]
    % Only a subset of cross‑area pairs is computed (as listed below).

    % ---- PFC vs. ACC ----
    for ch_i = [1, 6, 11, 16]
        for ch_j = [21, 26, 31]
            % cohgramc returns magnitude‑squared coherence (C) and time/frequency axes
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);   % Square to get magnitude‑squared coherence (if needed)
            % Save the result
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end

    % ---- PFC vs. HPC ----
    for ch_i = [1, 6, 11, 16]
        for ch_j = [33, 38, 43]
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end

    % ---- PFC vs. PPC ----
    for ch_i = [1, 6, 11, 16]
        for ch_j = [49, 54, 59]
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end

    % ---- ACC vs. HPC ----
    for ch_i = [21, 26, 31]
        for ch_j = [33, 38, 43]
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end

    % ---- ACC vs. PPC ----
    for ch_i = [21, 26, 31]
        for ch_j = [49, 54, 59]
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end

    % ---- HPC vs. PPC ----
    for ch_i = [33, 38, 43]
        for ch_j = [49, 54, 59]
            [C, ~, ~, ~, ~, t, F] = cohgramc(tempFP(:, ch_i), tempFP(:, ch_j), ...
                                              params.movingwin, params);
            c = (C .* C);
            save([baseName, '\', 'c', num2str(ch_i, '%02d'), '&', ...
                  num2str(ch_j, '%02d'), '.mat'], 'c', 't', 'F');
            disp([file_list(i).name, ' data, channels ', num2str(ch_i), ...
                  ' & ', num2str(ch_j), ' coherence computed!']);
        end
    end
end