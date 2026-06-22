%% GLM_for_speed1.m: Linear Mixed‑effects Model of Coherence vs. Speed and Learning
% This script loads experimental data (coherence, speed, state labels) for a
% specified animal, day(s), and channel pair. It aligns coherence time series
% with speed data, extracts average coherence in a target frequency band
% (theta or gamma) for each speed window, determines the dominant brain state
% for each window, and builds a linear mixed‑effects model to test whether
% coherence is influenced by running speed, learning (pre‑ vs. post‑training),
% and their interaction, with animal as a random effect.

clear; clc;

% ---- Load the master experiment structure ----
load('**.mat');

%% ===================== 0. Parameter settings ==============================
fs = 1000;                     % EEG sampling rate (Hz)
window_len_sec = 0.5;          % Analysis window length (s), matches speed data resolution
nAnimals = 6;                  % Number of animals in the dataset

% ---------- Select the channel pair and frequency band ----------
ch1 = '33';                    % First channel (e.g., HPC)
ch2 = '1';                    % Second channel (e.g., PFC)
% freq_band = [4, 12];         % Theta band (uncomment if needed)
freq_band = [60, 90];          % Gamma band (currently used)

animalIdx = 1;                 % Only one animal is processed in this version
totalDays = length(experiment.Animals{animalIdx}.Days) - 28;   % Total days available
preDay = 1;                    % Pre‑training day (day 1)
dayidxN = [preDay, 7];         % Days to analyse: day 1 (pre) and day 7 (post)
% (To analyse all days, replace with: 1:totalDays)

% ---- Accumulator arrays for all data ----
allCoh      = [];              % Average coherence per window
allSpeed    = [];              % Running speed (m/s)
allState    = [];              % Dominant state label per window
allLearning = [];              % Binary: 0 = pre‑training, 1 = post‑training
allAnimal   = [];              % Animal index (1‑6)

%% ===================== Loop over days =====================================
for dayIdx = dayidxN
    fprintf('Processing Day %d / %d ...\n', dayIdx, totalDays);

    %% 1. Load coherence, AI, state, and speed for this day
    LFP_path = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_path;
    coh_path = LFP_path(1:end-3);   % Remove the trailing 'FP\' part

    % Load pre‑computed coherence file (assumed naming: 'c<ch1>&<ch2>.mat')
    cohFile = [coh_path, 'c', ch1, '&', ch2, '.mat'];
    if ~exist(cohFile, 'file')
        error('Coherence file not found: %s\nPlease check file name and path.', cohFile);
    end
    cohData = load(cohFile);
    c_mat = cohData.c;          % Time × frequency matrix
    t_coh = cohData.t;          % Time vector (seconds), aligned with LFP
    F_coh = cohData.F;          % Frequency vector (Hz)

    % Load AI (analog input, used for synchronisation), state labels, and speed
    load([LFP_path, 'AI.mat']);
    state_1kHz = experiment.Animals{animalIdx}.Days(dayIdx).State_all_data(:);
    speed_05s  = experiment.Animals{animalIdx}.Days(dayIdx).avg_speed_m_per_s(:);
    manualTime = experiment.Animals{animalIdx}.Days(dayIdx).ManualTime;

    % Trim all signals to the same length (AI length)
    len_sec = min(length(AI.AI04), min(length(state_1kHz), length(speed_05s) * 0.5 * fs / fs)) / fs;
    AI_trimmed = AI.AI04(1 : round(len_sec * fs));
    state_1kHz = state_1kHz(1 : round(len_sec * fs));

    %% 2. Compute offset for speed alignment (based on AI04 trigger)
    % Find the first sample where AI04 exceeds 2000 (sync pulse)
    first_sample = find(AI_trimmed > 2000, 1, 'first');
    if isempty(first_sample)
        first_time = -1;
    else
        first_time = first_sample / fs;
    end
    if first_time ~= -1
        offset = first_time - manualTime;   % Offset in seconds
    else
        offset = -manualTime;
    end

    % Split speed data into segments for each animal
    segLen_win = floor(length(speed_05s) / nAnimals);

    % ---- Loop over each animal (only one animal is actually processed) ----
    for animal = 1:nAnimals
        % Extract speed segment for this animal
        speed_ani = speed_05s((animal-1)*segLen_win + 1 : animal*segLen_win);

        % Speed time axis (window centres, absolute time relative to recording start)
        speed_time_ani = (0.25 : 0.5 : 0.25 + (segLen_win-1)*0.5)' + offset;

        % Keep only windows whose centre falls within the valid time range
        valid_idx = speed_time_ani >= 0 & speed_time_ani < len_sec;
        speed_aligned   = speed_ani(valid_idx);
        speed_center_t  = speed_time_ani(valid_idx);
        n_windows = length(speed_aligned);

        if n_windows == 0
            continue;
        end

        %% 3. Extract the average coherence in the target frequency band for each window
        % Interpolate coherence matrix at the window centre times
        coh_at_windows = interp1(t_coh, c_mat, speed_center_t, 'linear');   % nWins × nFreqs

        % Find indices of frequencies within the band
        freq_idx = F_coh >= freq_band(1) & F_coh <= freq_band(2);
        if ~any(freq_idx)
            error('No frequency points in the specified band.');
        end
        % Average over frequencies for each window
        coh_avg = mean(coh_at_windows(:, freq_idx), 2);

        %% 4. Determine the dominant brain state for each window (from state_1kHz)
        dominant_state = zeros(n_windows, 1);
        for w = 1:n_windows
            t_center = speed_center_t(w);
            start_samp = round((t_center - window_len_sec/2) * fs) + 1;
            end_samp   = round((t_center + window_len_sec/2) * fs);
            % Clamp to valid indices
            start_samp = max(1, min(length(state_1kHz), start_samp));
            end_samp   = max(1, min(length(state_1kHz), end_samp));

            states_in_win = state_1kHz(start_samp:end_samp);
            % Exclude invalid state (label 4)
            valid_states = states_in_win(states_in_win ~= 4);
            if isempty(valid_states)
                dominant_state(w) = NaN;
            else
                state_cats = unique(valid_states);
                counts = histc(valid_states, state_cats);
                [~, max_idx] = max(counts);
                dominant_state(w) = state_cats(max_idx);
            end
        end

        % Remove windows with NaN or invalid states
        keep = ~isnan(coh_avg) & ~isnan(dominant_state) & dominant_state ~= 4;
        coh_avg = coh_avg(keep);
        speed_aligned = speed_aligned(keep);
        dominant_state = dominant_state(keep);

        n_valid = length(coh_avg);
        if n_valid == 0
            continue;
        end

        %% 5. Add learning label (0 = pre‑training, 1 = post‑training)
        learn_label = (dayIdx ~= preDay);
        animal_label = repmat(animal, n_valid, 1);

        %% 6. Accumulate into global arrays
        allCoh      = [allCoh;      coh_avg];
        allSpeed    = [allSpeed;    speed_aligned];
        allState    = [allState;    dominant_state];
        allLearning = [allLearning; repmat(learn_label, n_valid, 1)];
        allAnimal   = [allAnimal;   animal_label];
    end
end

%% ===================== 7. Prepare data for modelling ======================
% Keep only awake states (2.1 = Awake_resting, 2.2 = Awake_locomotion)
awake_idx = (allState == 2.1) | (allState == 2.2);
coh_all   = allCoh(awake_idx);
speed_all = allSpeed(awake_idx);
learn_all = allLearning(awake_idx);
animal_all = allAnimal(awake_idx);

% Convert animal index to categorical variable
animal_cat = categorical(animal_all, 1:6, ...
    {'Animal1','Animal2','Animal3','Animal4','Animal5','Animal6'});

% Build a table for modelling (coherence values are typically in [0,1];
% optionally apply Fisher‑z transformation for normality)
tbl = table(coh_all, speed_all, learn_all, animal_cat, ...
    'VariableNames', {'Coherence', 'Speed', 'Learning', 'Animal'});
tbl = rmmissing(tbl);   % Remove any rows with missing data

%% ===================== 8. Fit linear mixed‑effects models =================
% ---- Full model: Coherence ~ Speed + Learning + Speed:Learning + (1|Animal) ----
fprintf('----- Full Mixed Model (Awake only, %s-%s, %.0f-%.0f Hz) -----\n', ...
    ch1, ch2, freq_band(1), freq_band(2));
mdl_full = fitglme(tbl, ...
    'Coherence ~ Speed + Learning + Speed:Learning + (1|Animal)', ...
    'Distribution', 'normal', 'Link', 'identity');
disp(mdl_full)

% Display fixed‑effects coefficients
disp('Fixed effects coefficients:');
disp(mdl_full.Coefficients);

% Display random effects (BLUPs)
[B, Bnames, ~] = randomEffects(mdl_full);
fprintf('\nRandom effects (BLUPs):\n');
disp(table(Bnames, B));

% ---- Reduced model (no Learning effect) ----
fprintf('----- Reduced Mixed Model (no Learning) -----\n');
mdl_noLearn = fitglme(tbl, ...
    'Coherence ~ Speed + (1|Animal)', ...
    'Distribution', 'normal', 'Link', 'identity');
disp(mdl_noLearn)

% ---- Likelihood Ratio Test to compare models ----
fprintf('\n=== Likelihood Ratio Test (Learning effect) ===\n');
comp = compare(mdl_full, mdl_noLearn);
disp(comp);