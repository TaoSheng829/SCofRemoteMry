% compute_PPC_Figure2.m
% This script analyzes spike‑LFP phase‑phase coupling (PPC) across multiple
% animals and channels. It loads pre‑computed PPC data (from
% 'filename_theta_ppc.mat'), identifies for each spike unit the LFP channel
% with the smallest p‑value, extracts the corresponding phase‑lag vector,
% and produces several plots corresponding to Figure 2F‑J of the paper.
%
% The script processes a list of subjects, selects spikes from a specified
% brain region (based on ts_ri channel range), and finds the best‑fitting
% LFP channel (within FP_ri) for each unit. Results are compiled into
% matrices for further visualization.

% Figure 2F‑J
clear;

% List of animal/filenames to process
filelist = {};

titlename = 'theta';   % Frequency band label (used in the saved file names)

% Channel ranges
FP_ri  = [1 20];   % LFP channels to search (e.g., PFC)
ts_ri  = [49 64];  % Spike channels of interest (e.g., PPC – posterior parietal cortex)

% Initialize storage arrays
ppc_pack      = [];   % Column1: minimum p‑value; Column2: corresponding lag (at bin 11)
i_pack        = 1;
ppc_005pack   = [];   % Stores full lag‑vectors for units with p < 0.05
i_005pack     = 1;
ppc_095pack   = [];   % Stores only p‑value and lag for units with p >= 0.05 (not used later)
i_095pack     = 1;

% ===================== Main loop over subjects ============================
for i_list = 1:length(filelist)
    filename = filelist{i_list};
    % Load the pre‑computed PPC structure for this subject
    load(['Y:\数据备份\AAA_orgaized by zjx\PPC spikes\', filename, '_', titlename, '_ppc.mat']);

    % Loop over all spike units (tsList contains unit names like 'ts_01_0')
    for i_ts = 1:length(tsList)
        % Check if this unit belongs to the selected brain region (ts_ri range)
        % tsList{i_ts} format: 'ts_XX_Y' where XX is channel number
        if ismember(str2double(tsList{i_ts}(4:5)), ts_ri(1):ts_ri(2))
            % Initialize a variable to track the minimum p‑value across LFP channels
            temp_pmin = ones(1, 11) + 1;   % A large initial value (>1)

            % Find the LFP channel (within FP_ri) that gives the smallest p‑value
            for i_fpN = FP_ri(1):FP_ri(2)
                eval(['temppv = ppc_pvalue.v', num2str(i_fpN), '(i_ts);']);
                if temppv < temp_pmin
                    temp_pmin = temppv;
                    temp_imax = i_fpN;
                end
            end

            % Store the minimum p‑value and the corresponding lag (11th bin)
            ppc_pack(i_pack, 1) = temp_pmin;
            eval(['ppc_pack(i_pack, 2) = lag_vector.v', num2str(temp_imax), '(i_ts, 11);']);
            i_pack = i_pack + 1;

            % If p < 0.05, store the entire lag‑vector (11 bins) for significant units
            if temp_pmin < 0.05
                eval(['ppc_005pack(i_005pack, :) = lag_vector.v', num2str(temp_imax), '(i_ts, :);']);
                i_005pack = i_005pack + 1;
            else
                % For non‑significant units, store only the p‑value and the lag
                ppc_095pack(i_095pack, 1) = temp_pmin;
                eval(['ppc_095pack(i_095pack, 2) = lag_vector.v', num2str(temp_imax), '(i_ts, 11);']);
                i_095pack = i_095pack + 1;
            end
        end
    end

    % Clear all variables except the ones we need to accumulate across files
    clearvars -except filelist titlename FP_ri ts_ri ppc_pack i_pack ...
              ppc_005pack i_005pack ppc_095pack i_095pack i_list;
end

% ===================== Figure 2I: Normalized lag vectors ===================
% Normalize each unit's lag vector to [0,1] range, then sort by the position
% of the maximum (peak) to create a raster plot.
NeurNum = length(ppc_005pack(:, 1));
lag_vector_norm = [];
r_ts = [];

for i = 1:NeurNum
    temp_max = max(ppc_005pack(i, :));
    temp_min = min(ppc_005pack(i, :));
    lag_vector_norm(i, :) = (ppc_005pack(i, :) - temp_min) / (temp_max - temp_min);
    r_ts(i) = min(find(lag_vector_norm(i, :) == max(lag_vector_norm(i, :))));
end

% Sort neurons by the position of their peak (descending order)
% (i.e., neurons with later peaks appear at the top of the plot)
for m = 1:NeurNum - 1
    for n = m + 1:NeurNum
        if r_ts(m) < r_ts(n)
            % Swap r_ts
            rtp = r_ts(n);
            r_ts(n) = r_ts(m);
            r_ts(m) = rtp;
            % Swap corresponding normalized vectors
            rtp1 = lag_vector_norm(n, :);
            lag_vector_norm(n, :) = lag_vector_norm(m, :);
            lag_vector_norm(m, :) = rtp1;
        end
    end
end

% Plot the normalized lag vectors as an image (raster)
figure
imagesc(-40:4:40, 1:NeurNum, lag_vector_norm);  % x‑axis: lag in ms (-40 to 40 in steps of 4)
colorbar
colormap jet
title('Normalized lag vectors (p<0.05)');
xlabel('Lag (ms)');
ylabel('Neuron # (sorted by peak latency)');

% ===================== Figure 2J: Histogram of peak positions ==============
% Count how many neurons have their maximum (peak) at each lag bin.
lag_vector_max = zeros(1, length(lag_vector_norm(1, :)));
for i = 1:length(lag_vector_norm(1, :))
    lag_vector_max(i) = length(find(lag_vector_norm(:, i) == 1));
end

figure
bar(-40:4:40, lag_vector_max);
xlabel('Lag (ms)');
ylabel('Number of neurons with peak at this lag');
title('Distribution of peak positions (p<0.05)');

% ===================== Figure 2F: Mean normalized lag curve ================
% Compute and plot the average of all normalized lag vectors.
figure
a = mean(lag_vector_norm, 1);   % Mean across neurons
plot(-40:4:40, a, 'LineWidth', 2);
xlabel('Lag (ms)');
ylabel('Mean normalized phase coupling');
title('Average lag vector across significant neurons');
grid on;

% ===================== Figure 2G: (Placeholder) ============================
% The variable 'lag_p_max' is declared but not used; possibly intended for
% a different plot. It is left here for completeness.
lag_p_max = [];

% Adjust y‑axis limits for the current figure (if applicable)
ylim([0, 10]);

% Save the currently active figure(s) – this will only save the last one.
% You may want to save each figure separately with descriptive names.
saveas(gcf, ['C:\Users\Administrator\Desktop\111.eps']);
saveas(gcf, ['C:\Users\Administrator\Desktop\112.jpg']);

% Note: The above save commands overwrite each other – only the last plot is saved.
% To save all four figures, you should assign figure handles or use separate save calls.