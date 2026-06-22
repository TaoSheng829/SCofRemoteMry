% PL22MAT: Convert Plexon PL2 files to MAT files and save them in the same folder.
% This script reads all .pl2 files in a given directory (including subfolders),
% extracts continuous LFP (FP) channels and spike waveforms (SPK) with their timestamps,
% and saves the data into a single .mat file per .pl2 file.

% ========================== Configuration ==================================
pl2_path = '';  % Root folder containing .pl2 files

% (Optional) Uncomment below to call a function version – here we do inline processing.
% list = pl22mat(pl2_path,'lfp'); % Run the function and save MAT files

% Get a list of all .pl2 files recursively (including subfolders)
file_list = dir([pl2_path, '**\*.pl2']);
file_num = size(file_list, 1);

% ========================== Main loop over .pl2 files ======================
for i = 1:file_num
    % Full path to the current .pl2 file
    file_locat = [file_list(i).folder, '\', file_list(i).name];

    % Initialize containers for LFP, spike timestamps, and spike waveforms
    tsList = {};   % Cell array to store names of spike timestamp fields
    ts = {};       % Structure to hold spike timestamps (e.g., ts.ts_01_0)
    wave = {};     % Structure to hold spike waveforms (e.g., wave.wave_01_0)
    FP = {};       % Structure to hold continuous LFP channels (e.g., FP.FP01)

    % ---- Extract LFP and spike data for each channel (1 to 64) ----
    for channel = 1:64   % Depends on the electrode array size (e.g., 64 channels)
        % --- LFP (continuous) extraction ---
        % Use PL2Ad to read the analog data for channel 'FPxx'
        eval(['tempFP = PL2Ad(file_locat, ''FP', num2str(channel, '%02d'), ''');']);
        if ~isempty(tempFP.Values)
            eval(['FP.FP', num2str(channel, '%02d'), ' = tempFP.Values;']);
        end

        % --- Spike extraction (up to 6 units per channel) ---
        % Unit numbers typically range from 0 (unsorted) to 6 (sorted units)
        for Unit_n = 0:6
            % Use PL2Waves to read spike waveforms and timestamps for 'SPKxx' channel
            % Note: 'SPK_FILT_WB' is the channel name as assigned in Offline Sorter.
            eval(['tempSPK = PL2Waves(file_locat, ''SPK', num2str(channel, '%02d'), ''', ', num2str(Unit_n), ');']);
            if ~isempty(tempSPK.Ts)
                % If spikes exist, store timestamps and waveforms in the structures
                ts_field = ['ts_', num2str(channel, '%02d'), '_', num2str(Unit_n)];
                wave_field = ['wave_', num2str(channel, '%02d'), '_', num2str(Unit_n)];
                eval(['tsList = [tsList ''', ts_field, '''];']);   % Append field name to list
                eval(['ts.', ts_field, ' = tempSPK.Ts;']);
                eval(['wave.', wave_field, ' = tempSPK.Waves;']);
            end
        end
    end

    % (Optional) Clear temporary variables to keep workspace clean
    % clearvars Unit_n i tempFP tempSPK file_path;

    % Build the output filename: remove the '.pl2' extension
    % Note: 'filename' holds the full path without extension (used as a meta variable)
    filename = file_locat(1:end-4);   % e.g., 'Y:\...\MyFile' (without .pl2)

    % Save all collected data into a .mat file in the same folder as the .pl2 file
    % The saved variables: filename (path string), FP (LFP struct),
    % tsList (list of spike field names), ts (spike timestamps), wave (spike waveforms)
    save([file_list(i).folder, '\', file_list(i).name(1:end-4), '.mat'], ...
         'filename', 'FP', 'tsList', 'ts', 'wave');
end