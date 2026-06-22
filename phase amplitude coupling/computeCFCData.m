function [tempPAC_CSUS, r2val_all, b2_all] = computeCFCData(phase_channels, amp_channels)
% computeCFCData: Compute cross‑frequency coupling (CFC) metrics and phase‑precession statistics.
%
%   This function processes two experimental groups (CSonly and CSUS) by loading
%   LFP data, calculating phase‑amplitude coupling (PAC) for specified channel
%   ranges, and computing:
%     1) For each animal, the preferred phase (circular mean) across five ITI
%        epochs, followed by linear regression and circular‑linear correlation
%        to assess phase precession (r² and slope).
%     2) For the CSUS group only, the modulation index (MI) for low‑gamma
%        (30‑60 Hz) and high‑gamma (60‑90 Hz) in two periods: pre‑FC (baseline)
%        and ITI1, across all valid channel pairs. These MI values are averaged
%        and returned as a 4×8 matrix.
%
%   Inputs:
%       phase_channels : 1×2 vector [start_ch, end_ch] for phase channels (LFP theta).
%       amp_channels   : 1×2 vector [start_ch, end_ch] for amplitude channels (LFP gamma).
%
%   Outputs:
%       tempPAC_CSUS   : 4×8 matrix (rows: preFC low‑gamma, preFC high‑gamma,
%                        ITI1 low‑gamma, ITI1 high‑gamma) – each column is one CSUS animal.
%       r2val_all      : 8×2 matrix; column 1 = CSonly r², column 2 = CSUS r².
%       b2_all         : 8×2 matrix; column 1 = CSonly slope, column 2 = CSUS slope.

    % ---- 1. Initialise paths and load data ----
    cdpath = 'Y:\巩固文章写作\20240520整图\f1 encoding phase precession\f1data整合\';
    cd(cdpath);
    load([cdpath, 'pre_data\timestamp.mat']);   % Loads time windows (sound1, iti1, etc.)

    % Load encoding structures for both groups
    cdpath_csonly = [cdpath, 'CSonly\'];
    cdpath_csus   = [cdpath, 'CSUS\'];
    load([cdpath_csonly, 'encode_csonly.mat']);   % Variable 'encode_csonly'
    encode_csonly = encode;
    load([cdpath_csus, 'encode_csus.mat']);       % Variable 'encode_csus'
    encode_csus = encode;

    addpath('Y:\数据备份\encoding');   % For additional helper functions

    % ---- 2. Parameters ----
    phaserange = [4 12];   % Theta band for phase extraction
    amprange   = [60 90];  % High‑gamma band for amplitude
    nfreqs = 100;          % Number of frequency bins (for wavelet spectrogram)
    numbins = 50;          % Number of phase bins for PAC

    % Epoch labels (full sequence of 15 segments: 5 sounds, 5 traces, 5 ITIs)
    recordlist = {'sound1','trace1','iti1','sound2','trace2','iti2', ...
                  'sound3','trace3','iti3','sound4','trace4','iti4', ...
                  'sound5','trace5','iti5'};
    temparr = [3, 6, 9, 12, 15];   % Indices of the 5 ITI epochs

    % ---- 3. Initialise output arrays ----
    num_animals = 8;
    tempPAC_CSUS = zeros(4, num_animals);
    r2val_all = zeros(num_animals, 2);   % col1 = CSonly, col2 = CSUS
    b2_all    = zeros(num_animals, 2);   % col1 = CSonly, col2 = CSUS

    % ---- 4. Process CSonly group (phase‑precession only) ----
    fprintf('Processing CSonly group...\n');
    for fi = 1:num_animals
        fprintf('   Animal %d/%d: %s\n', fi, num_animals, encode_csonly.filename{fi});

        dis_ch = encode_csonly.dis(fi);          % Disconnected channel (skip)
        filename = char(encode_csonly.filename(fi));
        srtlag = encode_csonly.strlag(fi);       % Start lag (samples)

        % Load LFP data for this animal
        file_path = [cdpath_csonly, filename(1:7), '\', filename, '.mat'];
        load(file_path, 'FP');

        % ---- 5. Compute r² and slope (phase precession across ITI epochs) ----
        fprintf('     Computing r² and slope...\n');
        r2data = zeros(1, length(temparr));

        for kk = 1:length(temparr)
            bb = temparr(kk);
            temprl = char(recordlist(bb));        % e.g., 'iti1'
            eval(['time_window = ', temprl, ';']);
            timelim_seg = time_window(2) - time_window(1);

            % Temporary storage for PAC vectors across channel pairs
            tempr2 = [];
            kk2 = 1;

            % Loop over all phase channels (within range, excluding disconnected)
            for i_fpN = phase_channels(1):phase_channels(2)
                if i_fpN == dis_ch
                    continue;
                end

                % Extract phase signal, filter to theta band
                lfpphs = struct();
                eval(['lfpphs.data = FP.FP', num2str(i_fpN, '%02d'), ...
                      '(srtlag+', temprl, '(1)*1000:srtlag+', temprl, '(2)*1000);']);
                lfpphs.timestamps = (0.001:0.001:timelim_seg)';
                lfpphs.samplingRate = 1000;
                filtered_phase = bz_Filter(lfpphs, 'passband', phaserange, 'filter', 'fir1');

                % Bin the phase into 50 bins
                phasebins = linspace(-pi, pi, numbins+1);
                phasecenters = phasebins(1:end-1) + (phasebins(2)-phasebins(1))/2;
                [~, ~, phaseall] = histcounts(filtered_phase.phase, phasebins);

                % Loop over amplitude channels
                for j_fpN = amp_channels(1):amp_channels(2)
                    if j_fpN == dis_ch
                        continue;
                    end

                    % Extract amplitude signal and compute wavelet spectrogram
                    lfpamp = struct();
                    eval(['lfpamp.data = FP.FP', num2str(j_fpN, '%02d'), ...
                          '(srtlag+', temprl, '(1)*1000:srtlag+', temprl, '(2)*1000);']);
                    lfpamp.timestamps = (0.001:0.001:timelim_seg)';
                    lfpamp.samplingRate = 1000;
                    wavespec_amp = bz_WaveSpec(lfpamp, 'frange', amprange);
                    wavespec_amp.data = log10(abs(wavespec_amp.data));
                    wavespec_amp.mean = mean(wavespec_amp.data, 1);

                    % Compute PAC map: mean amplitude per phase bin (normalised)
                    phaseamplitudemap = zeros(numbins, nfreqs);
                    for bb_bin = 1:numbins
                        phaseamplitudemap(bb_bin, :) = ...
                            mean(wavespec_amp.data(phaseall == bb_bin, :), 1) ./ wavespec_amp.mean;
                    end

                    % Average over high‑gamma frequencies (60‑90 Hz: indices 33‑100)
                    a = mean(phaseamplitudemap(:, 33:100), 2);
                    a = Smooth(a, 3, 'type', 'c');   % Causal smoothing

                    tempr2(:, kk2) = a;
                    kk2 = kk2 + 1;
                end
            end

            % Use the channel specified by csl to compute circular mean
            kk1 = encode_csonly.csl{fi};
            [Am, ~, ~] = circ_mean(phasecenters, mean(tempr2(:, kk1), 2)', 2);
            r2data(kk) = Am;
        end

        % Adjust phase values to avoid wrap‑around discontinuities
        if isfield(encode_csonly, 'par1')
            r2data(1) = r2data(1) + 2 * pi * encode_csonly.par1{fi};
            r2data(5) = r2data(5) + 2 * pi * encode_csonly.par5{fi};
        end

        % Linear regression: phase vs. ITI index (1‑5)
        X = [1; 2; 3; 4; 5];
        X1 = [ones(size(X, 1), 1), X];
        [b, ~, ~, ~, stats] = regress(r2data', X1);

        % Circular‑linear correlation
        [rval, pval] = circ_corrcl(r2data', X);

        r2val_all(fi, 1) = rval * rval;
        b2_all(fi, 1) = b(2);
    end

    % ---- 6. Process CSUS group (both phase‑precession and PAC) ----
    fprintf('Processing CSUS group...\n');
    for fi = 1:num_animals
        fprintf('   Animal %d/%d: %s\n', fi, num_animals, encode_csus.filename{fi});

        dis_ch = encode_csus.dis(fi);
        filename = char(encode_csus.filename(fi));
        srtlag = encode_csus.strlag(fi);

        % Define time points for pre‑FC (baseline) and ITI1
        % (These variables are loaded from timestamp.mat)
        s1 = sound1(1) - 100;
        s2 = sound1(1) - 10;
        s3 = iti1(1) + 5;
        s4 = iti1(2) - 1;
        timelim  = [srtlag + s1*1000 + 1, srtlag + s2*1000];   % pre‑FC window
        timelim1 = [srtlag + s3*1000 + 1, srtlag + s4*1000];    % ITI1 window

        % Load LFP data
        file_path = [cdpath_csus, filename(1:7), '\', filename, '.mat'];
        load(file_path, 'FP');

        % ---- 7. Compute modulation indices for pre‑FC and ITI1 ----
        fprintf('     Computing tempPAC (MI)...\n');
        tempPAC_col = zeros(4, 1);   % [pre‑FC low‑gamma, pre‑FC high‑gamma,
                                      %  ITI1 low‑gamma, ITI1 high‑gamma]

        for i_fpN = phase_channels(1):phase_channels(2)
            if i_fpN == dis_ch
                continue;
            end
            for j_fpN = amp_channels(1):amp_channels(2)
                if j_fpN == dis_ch
                    continue;
                end

                % ---- pre‑FC period ----
                lfpphs = struct();
                eval(['lfpphs.data = FP.FP', num2str(i_fpN, '%02d'), ...
                      '(timelim(1):timelim(2));']);
                lfpphs.timestamps = (0.001:0.001:(timelim(2)-timelim(1)+1)/1000)';
                lfpphs.samplingRate = 1000;

                lfpamp = struct();
                eval(['lfpamp.data = FP.FP', num2str(j_fpN, '%02d'), ...
                      '(timelim(1):timelim(2));']);
                lfpamp.timestamps = (0.001:0.001:(timelim(2)-timelim(1)+1)/1000)';
                lfpamp.samplingRate = 1000;

                % bz_ModIndexCF computes a 2D modulation index matrix
                % (phase frequencies × amplitude frequencies) and optionally plots.
                b_pre = bz_ModIndexCF(lfpphs, lfpamp, (4:2:50), (5:2:150), 0);
                % (4:2:50) = phase frequencies (4‑50 Hz, step 2)
                % (5:2:150) = amplitude frequencies (5‑150 Hz, step 2)

                % ---- ITI1 period ----
                lfpphs.data = eval(['FP.FP', num2str(i_fpN, '%02d'), ...
                                    '(timelim1(1):timelim1(2));']);
                lfpphs.timestamps = (0.001:0.001:(timelim1(2)-timelim1(1)+1)/1000)';

                lfpamp.data = eval(['FP.FP', num2str(j_fpN, '%02d'), ...
                                    '(timelim1(1):timelim1(2));']);
                lfpamp.timestamps = (0.001:0.001:(timelim1(2)-timelim1(1)+1)/1000)';

                b_iti1 = bz_ModIndexCF(lfpphs, lfpamp, (4:2:50), (5:2:150), 0);

                % Extract and accumulate MI for low‑gamma (30‑60 Hz) and high‑gamma (60‑90 Hz)
                % Indices in b matrix: phase bins (columns) and amplitude bins (rows).
                % Here we average across the first 5 phase frequency bins (for theta)
                % and the relevant amplitude ranges.
                tempPAC_col(1) = tempPAC_col(1) + mean(mean(b_pre(12:28, 1:5)));   % preFC low‑gamma
                tempPAC_col(2) = tempPAC_col(2) + mean(mean(b_pre(28:43, 1:5)));   % preFC high‑gamma
                tempPAC_col(3) = tempPAC_col(3) + mean(mean(b_iti1(12:28, 1:5)));  % ITI1 low‑gamma
                tempPAC_col(4) = tempPAC_col(4) + mean(mean(b_iti1(28:43, 1:5)));  % ITI1 high‑gamma
            end
        end

        % Average across all channel pairs
        num_phase_ch = length(phase_channels(1):phase_channels(2));
        num_amp_ch = length(amp_channels(1):amp_channels(2));
        tempPAC_CSUS(:, fi) = tempPAC_col / (num_phase_ch * num_amp_ch);

        % ---- 8. Compute CSUS phase‑precession (r² and slope) ----
        fprintf('     Computing r² and slope for CSUS...\n');
        r2data = zeros(1, length(temparr));

        for kk = 1:length(temparr)
            bb = temparr(kk);
            temprl = char(recordlist(bb));
            eval(['time_window = ', temprl, ';']);
            timelim_seg = time_window(2) - time_window(1);

            tempr2 = [];
            kk2 = 1;

            for i_fpN = phase_channels(1):phase_channels(2)
                if i_fpN == dis_ch
                    continue;
                end

                lfpphs = struct();
                eval(['lfpphs.data = FP.FP', num2str(i_fpN, '%02d'), ...
                      '(srtlag+', temprl, '(1)*1000:srtlag+', temprl, '(2)*1000);']);
                lfpphs.timestamps = (0.001:0.001:timelim_seg)';
                lfpphs.samplingRate = 1000;
                filtered_phase = bz_Filter(lfpphs, 'passband', phaserange, 'filter', 'fir1');

                phasebins = linspace(-pi, pi, numbins+1);
                phasecenters = phasebins(1:end-1) + (phasebins(2)-phasebins(1))/2;
                [~, ~, phaseall] = histcounts(filtered_phase.phase, phasebins);

                for j_fpN = amp_channels(1):amp_channels(2)
                    if j_fpN == dis_ch
                        continue;
                    end

                    lfpamp = struct();
                    eval(['lfpamp.data = FP.FP', num2str(j_fpN, '%02d'), ...
                          '(srtlag+', temprl, '(1)*1000:srtlag+', temprl, '(2)*1000);']);
                    lfpamp.timestamps = (0.001:0.001:timelim_seg)';
                    lfpamp.samplingRate = 1000;
                    wavespec_amp = bz_WaveSpec(lfpamp, 'frange', amprange);
                    wavespec_amp.data = log10(abs(wavespec_amp.data));
                    wavespec_amp.mean = mean(wavespec_amp.data, 1);

                    phaseamplitudemap = zeros(numbins, nfreqs);
                    for bb_bin = 1:numbins
                        phaseamplitudemap(bb_bin, :) = ...
                            mean(wavespec_amp.data(phaseall == bb_bin, :), 1) ./ wavespec_amp.mean;
                    end

                    a = mean(phaseamplitudemap(:, 33:100), 2);
                    a = Smooth(a, 3, 'type', 'c');
                    tempr2(:, kk2) = a;
                    kk2 = kk2 + 1;
                end
            end

            % Use the first channel (index 1) for circular mean (original code uses kk1=1)
            kk1 = 1;
            [Am, ~, ~] = circ_mean(phasecenters, mean(tempr2(:, kk1), 2)', 2);
            r2data(kk) = Am;
        end

        % (Optional phase adjustment – commented out in original)
        % if isfield(encode_csus, 'par1')
        %     r2data(1) = r2data(1) + 2 * pi * encode_csus.par1{fi};
        %     r2data(5) = r2data(5) + 2 * pi * encode_csus.par5{fi};
        % end

        X = [1; 2; 3; 4; 5];
        X1 = [ones(size(X, 1), 1), X];
        [b, ~, ~, ~, stats] = regress(r2data', X1);
        [rval, pval] = circ_corrcl(r2data', X);

        r2val_all(fi, 2) = rval * rval;
        b2_all(fi, 2) = b(2);
    end

    % ---- 9. Scale the MI values for better visualisation ----
    tempPAC_CSUS = tempPAC_CSUS * 1e4;

    fprintf('All processing complete!\n');
end