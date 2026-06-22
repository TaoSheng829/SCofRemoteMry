% compute_encoding_phase_centers.m
% This script loads encoding‑phase data (CSonly or CSUS) and computes,
% for each of 8 animals, the circular mean phase across multiple channel
% combinations and five trial epochs (sound1, trace1, iti1, ... sound5).
% The resulting phase centers are stored in the variable 'r2data'
% (though the naming suggests it might have been intended for R² values).
%
% Data source: Pre‑computed phase‑amplitude comodulation (PAC) maps
% from an earlier analysis pipeline (see data2SWR_phase_PAC.m).
%
% The script processes one condition at a time (CSonly or CSUS) as set
% by the variable 'src' at the top.

clear; clc;  % Clear workspace and command window

% ----------------------------- Configuration ------------------------------
src = 1;   % 1 for 'CSonly' ; 2 for 'CSUS'

% Root directory containing the data
cdpath = '';
cd(cdpath);

% Load a timestamp file (though not used later in this snippet)
load([cdpath, 'pre_data\timestamp.mat']);

% Condition‑specific subfolder and data loading
if src == 1
    cdpath = [cdpath, 'CSonly\'];
    load([cdpath, 'encode_csonly.mat']);   % loads variable 'encode'
end
if src == 2
    cdpath = [cdpath, 'CSUS\'];
    load([cdpath, 'encode_csus.mat']);     % loads variable 'encode'
end

% Channel and frequency band definitions (matching prior PAC analysis)
FPphs_ri   = [1 20];   % Phase channels (range of FP indices)
phaserange = [4 12];    % Phase frequency band (theta)
FPamp_ri   = [33 48];   % Amplitude channels (range)
amprange   = [60 90];   % Amplitude frequency band (high‑gamma)
numbins    = 50;        % Number of phase bins (used in PAC maps)
nfreqs     = 100;       % Number of amplitude frequencies (for reference)

% Preallocate a variable that appears unused (kept for compatibility)
tempSlopeAndR2 = zeros(8, 2);

% Loop over the 8 animals/subjects (from encode.filename)
for Almid = 1:8
    % Extract the base filename (e.g., 'CS01_...')
    filename = char(encode.filename(Almid));

    % Construct a string for subfolder names (includes channel and band info)
    Sfilename = ['_', num2str(FPphs_ri(1), '%02d'), '_', num2str(FPphs_ri(2), '%02d'), '_', ...
                 num2str(phaserange(1)), '_', num2str(phaserange(2)), '_', ...
                 num2str(FPamp_ri(1), '%02d'), '_', num2str(FPamp_ri(2), '%02d'), '_', ...
                 num2str(amprange(1)), '_', num2str(amprange(2))];

    % List of 15 trial epochs (5 sounds, 5 traces, 5 ITIs)
    recordlist = {'sound1','trace1','iti1','sound2','trace2','iti2', ...
                  'sound3','trace3','iti3','sound4','trace4','iti4', ...
                  'sound5','trace5','iti5'};
    temparr = [3, 6, 9, 12, 15];   % Indices for trace? Actually, these are ITI? Wait: originally used bb = 3,6,9,12,15 – these are the ITI epochs? Let's check: recordlist(3)='iti1', (6)='iti2', (9)='iti3', (12)='iti4', (15)='iti5'. So the script only processes ITI epochs. This is deliberate – it seems to focus on inter‑trial intervals.

    kk = 1;   % Counter for storing phase centers across the 5 ITI epochs

    % Loop over the selected epoch indices (only ITI epochs)
    for bb = temparr
        % Current epoch name (e.g., 'iti1')
        temprl = char(recordlist(bb));

        tempr2 = [];   % Matrix to hold phase‑amplitude data from different channel pairs
        kk2 = 1;

        % Loop over all phase channels (except the one marked as 'dis' – disconnected?)
        for i_fpN = FPphs_ri(1):FPphs_ri(2)
            % Skip the channel that is marked as 'dis' (probably a bad channel)
            if i_fpN == encode.dis(Almid)
                continue;
            end

            % Loop over amplitude channels
            for j_fpN = FPamp_ri(1):FPamp_ri(2)
                % Load the pre‑computed PAC map for this channel pair and epoch
                load([cdpath, '\', filename(1:7), '\CrossFreCp\', filename, Sfilename, '\', ...
                      temprl, '\CrFreCp_', temprl, '_', num2str(i_fpN, '%02d'), '&', ...
                      num2str(j_fpN, '%02d'), '.mat']);

                % Extract the mean across the high‑frequency amplitude bins (33:100)
                % Note: This assumes amplitude frequencies are arranged in columns.
                a = mean(phaseamplitudemap(:, 33:100), 2);
                % Smooth the resulting phase profile with a 3‑point causal filter
                a = Smooth(a, 3, 'type', 'c');
                % Store this smoothed vector as a column in tempr2
                tempr2(:, kk2) = a;
                kk2 = kk2 + 1;

                disp([filename, ' data, phase ch ', num2str(i_fpN), ...
                      ', amp ch ', num2str(j_fpN), ' R² completed!']);
            end
        end

        % Compute the circular mean of the phase centers across channel pairs
        % Here, phasecenters is a variable from the loaded .mat file (bin centers)
        % We take the mean across the second dimension (columns) of tempr2,
        % then compute the circular mean weighted by that average profile.
        [Am, ~, ~] = circ_mean(phasecenters, mean(tempr2(:, 1), 2)', 2);
        % Store the resulting mean phase for this ITI epoch
        r2data(kk) = Am;
        kk = kk + 1;
    end

    % At the end of the animal loop, 'r2data' contains 5 values (one per ITI)
    % but it is not saved or further processed – likely intended for later use.
    % The variable 'tempSlopeAndR2' is never used; it may be a placeholder.
end

% After the loop, the script ends without saving the results.
% Consider adding a save command to preserve the 'r2data' array:
% save([cdpath, 'phase_centers_ITI.mat'], 'r2data');