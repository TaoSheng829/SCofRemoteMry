% data2SWR_phase_PAC.m
% Main script to compute:
%   1. SWR (sharp-wave ripples) from amplitude channels (FPamp_ri)
%   2. Phase time series from phase channels (FPphs_ri)
%   3. Phase-amplitude coupling (PAC) maps between phase and amplitude signals
%   at the times of SWR peaks.
%
% The script processes all .mat files in a given folder, saves intermediate
% and final results into subfolders (SWR, Phase, phaseamplitudemap).

% ========================== Configuration ==================================
pl2_path = ''; % Root data folder

% Get list of all .mat files in that folder
file_list = dir([pl2_path, '*.mat']);
file_num = size(file_list, 1);

% Channel ranges (index numbers of FP fields in the loaded .mat structure)
FPphs_ri = [1 20];   % Phase channels (for low‑frequency phase extraction)
FPamp_ri = [33 52]; % Amplitude channels (for high‑frequency ripple detection)

% Frequency bands
ampband = [60 90];  % Amplitude (high‑gamma) band for PAC
phaband = [4 12];   % Phase (theta) band

% Time limits (seconds) and analysis parameters
timelim = [0 3600];        % Analyze from 0 to 3600 s (or until signal end)
numbins = 50;              % Number of phase bins for PAC histogram
nfreqs = 100;              % (Not used explicitly in this snippet, kept for compatibility)
fq = 1000;                 % Sampling frequency (Hz)

% Add utility folder to path (contains bz_* functions)
addpath ''

% ========================== Main loop over files ===========================
for i = 1:file_num
    % Full path to the current .mat file
    file_locat = [file_list(i).folder, '\', file_list(i).name];
    load(file_locat);   % Loads variable 'FP' containing FP01, FP02, ... fields

    % Adjust timelim if the recording is shorter than 3600 s
    if timelim(2) > fix(length(FP.FP01) / 1000)
        timelim(2) = fix(length(FP.FP01) / 1000);
    end

    % Initialize containers (not strictly necessary)
    Cphaseamplitudemap = {};
    CSWRpeakTime = {};
    rpeakrandomshift = 0;   % No random shift (can be used for shuffling)

    % Create output subfolders if they do not exist
    base_name = erase(file_list(i).name, '.mat');   % File name without extension
    if ~exist([pl2_path, '\', base_name, '\SWR\'], 'dir')
        mkdir([pl2_path, '\', base_name, '\SWR\']);
    end
    if ~exist([pl2_path, '\', base_name, '\Phase\'], 'dir')
        mkdir([pl2_path, '\', base_name, '\Phase\']);
    end
    if ~exist([pl2_path, '\', base_name, '\phaseamplitudemap\'], 'dir')
        mkdir([pl2_path, '\', base_name, '\phaseamplitudemap\']);
    end

    % ---- Step 1: Detect SWR events on amplitude channels ----
    for j_fpN = FPamp_ri(1):FPamp_ri(2)
        % Extract data for channel j_fpN within the time window
        eval(['tempFP = FP.FP', num2str(j_fpN, '%02d'), '(timelim(1)*1000+1:timelim(2)*1000);']);
        lengthFP = length(tempFP);
        timestamps = ((1/fq)):((1/fq)):((lengthFP/fq));

        % Use bz_FindRipples (from Buzsáki toolbox) to detect ripples
        % Thresholds: [3 5] standard deviations, duration 10‑100 ms,
        % passband 130‑200 Hz (classic ripple band)
        r = bz_FindRipples(tempFP, timestamps', ...
            'thresholds', [3 5], ...
            'durations', [10 100], ...
            'frequency', 1000, ...
            'passband', [130 200], ...
            'EMGThresh', 0);

        % Save ripple structure
        save([pl2_path, '\', base_name, '\SWR\', num2str(j_fpN, '%02d'), 'SWR.mat'], 'r');
        disp([file_list(i).name, ' data, channel ', num2str(j_fpN), ' SWR computed!']);
    end

    % ---- Step 2: Also compute SWR on phase channels (if needed) ----
    for j_fpN = FPphs_ri(1):FPphs_ri(2)
        eval(['tempFP = FP.FP', num2str(j_fpN, '%02d'), '(timelim(1)*1000+1:timelim(2)*1000);']);
        lengthFP = length(tempFP);
        timestamps = ((1/fq)):((1/fq)):((lengthFP/fq));

        r = bz_FindRipples(tempFP, timestamps', ...
            'thresholds', [3 5], ...
            'durations', [10 100], ...
            'frequency', 1000, ...
            'passband', [130 200], ...
            'EMGThresh', 0);

        save([pl2_path, '\', base_name, '\SWR\', num2str(j_fpN, '%02d'), 'SWR.mat'], 'r');
        disp([file_list(i).name, ' data, channel ', num2str(j_fpN), ' SWR computed!']);
    end

    % ---- Step 3: Compute phase time series for each phase channel ----
    for i_fpN = FPphs_ri(1):FPphs_ri(2)
        eval(['tempFP = FP.FP', num2str(i_fpN, '%02d'), '(timelim(1)*1000+1:timelim(2)*1000);']);
        lengthFP = length(tempFP);

        % Build a temporary LFP structure for bz_Filter
        lfpphs = struct();
        lfpphs.data = tempFP;
        lfpphs.timestamps = (0.001:0.001:(length(lfpphs.data)/1000))';
        lfpphs.samplingRate = 1000;

        % Band‑pass filter to extract phase (theta band)
        filtered_phase = bz_Filter(lfpphs, 'passband', phaband, 'filter', 'fir1');

        % Bin the phase values into 'numbins' bins between -π and π
        phasebins = linspace(-pi, pi, numbins + 1);
        phasecenters = phasebins(1:end-1) + (phasebins(2) - phasebins(1)); % bin centers

        % Histcounts returns bin indices for each sample
        [~, ~, phaseall] = histcounts(filtered_phase.phase, phasebins);

        % Save phase indices and center values
        save([pl2_path, '\', base_name, '\Phase\', num2str(i_fpN, '%02d'), 'Phase.mat'], ...
            'phaseall', 'phasecenters');
        disp([file_list(i).name, ' data, channel ', num2str(i_fpN), ' Phase computed!']);
    end

    % ---- Step 4: For each amplitude channel, compute PAC maps ----
    for j_fpN = FPamp_ri(1):FPamp_ri(2)
        % Load the SWR structure for this amplitude channel
        load([pl2_path, '\', base_name, '\SWR\', num2str(j_fpN, '%02d'), 'SWR.mat']);

        % Skip if no ripples were detected
        if isempty(r.peaks)
            continue;
        end
        disp([file_list(i).name, ' data, channel ', num2str(j_fpN), ' SWR loaded.']);

        % Extract raw data for amplitude channel
        eval(['tempFP = FP.FP', num2str(j_fpN, '%02d'), '(timelim(1)*1000+1:timelim(2)*1000);']);
        lengthFP = length(tempFP);

        % Build LFP structure for bz_WaveSpec
        lfpamp = struct();
        lfpamp.data = tempFP;
        lfpamp.timestamps = (0.001:0.001:(length(lfpamp.data)/1000))';
        lfpamp.samplingRate = 1000;

        % Compute amplitude envelope (power) in the ampband (high‑gamma)
        wavespec_amp = bz_WaveSpec(lfpamp, 'frange', ampband);
        wavespec_amp.data = log10(abs(wavespec_amp.data));  % log‑transform amplitude

        disp([file_list(i).name, ' data, channel ', num2str(j_fpN), ' Amp computed.']);

        % ---- For each phase channel, compute PAC around SWR peaks ----
        for i_fpN = FPphs_ri(1):FPphs_ri(2)
            % Load the phase bin indices for this phase channel
            load([pl2_path, '\', base_name, '\Phase\', num2str(i_fpN, '%02d'), 'Phase.mat'], ...
                'phaseall', 'phasecenters');

            % Call custom function to compute phase‑amplitude comodulation
            % at the times of ripple peaks (with optional random shift)
            [phaseamplitudemap, SWRpeakTime] = LimRgPAC_st2(...
                wavespec_amp, phaseall, (r.peaks + rpeakrandomshift), 1000);

            % (Optional) Fit a 2D Gaussian to the map – commented out
            % [phasemax,amplitudemax] = fit_gaussian2d_st(phaseamplitudemap, ampfreqs, phasecenters);
            % surf(phasecenters, ampfreqs, phaseamplitudemap');

            % Save the PAC map and the SWR peak times used
            save([pl2_path, '\', base_name, '\phaseamplitudemap\', ...
                num2str(i_fpN, '%02d'), '_', num2str(j_fpN, '%02d'), '_phaseamplitudemap.mat'], ...
                'phaseamplitudemap', 'SWRpeakTime');

            disp([file_list(i).name, ' data, phase ch ', num2str(i_fpN), ...
                ', amp ch ', num2str(j_fpN), ' phaseamplitudemap computed!']);
        end
    end

    % Reset timelim for next file (though it will be overwritten)
    timelim = [0 3600];
end