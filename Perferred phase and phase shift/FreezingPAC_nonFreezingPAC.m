% FreezingPAC_nonFreezingPAC.m
% This script analyzes phase‑amplitude coupling (PAC) during freezing and
% non‑freezing states. It processes LFP data from a single animal (defined by
% 'Almid') and for a given conditioning type (CSonly or CSUS). The main steps:
%
%   1. Load behavioural freezing data (from video tracking) and LFP data.
%   2. Convert freezing similarity values into a binary freezing indicator.
%   3. For each ITI epoch, extract phase and amplitude signals, then compute
%      PAC maps separately for freezing and non‑freezing periods.
%   4. (Later sections) Extract the preferred phase (max amplitude) per ITI,
%      then perform circular‑linear correlation and linear regression to
%      assess phase precession across the 5 ITI epochs.

clear; clc;

% ----------------------------- Configuration ------------------------------
src = 2;    % 1 for 'CSonly' ; 2 for 'CSUS'
Almid = 4;  % Animal/subject index

cdpath = '';
cd(cdpath);
load([cdpath, 'pre_data\timestamp.mat']);   % General timestamp info (not used directly)

% Load condition‑specific data structure 'encode'
if src == 1
    cdpath = [cdpath, 'CSonly\'];
    load([cdpath, 'encode_csonly.mat']);
end
if src == 2
    cdpath = [cdpath, 'CSUS\'];
    load([cdpath, 'encode_csus.mat']);
end

% Extract animal‑specific metadata
filename = char(encode.filename(Almid));        % e.g., 'E230519_0524D1-2'
load([cdpath, '/', filename(1:7), '/', filename(1:7), 'training.mat']);   % Contains Cssimval0 (similarity values)
load([cdpath, '/', filename(1:7), '/', filename, '.mat']);                 % Contains FP structure (LFP data)

lengthTit = encode.lengthTitlist(Almid);        % Total trial length (not used)
AlmidCsl  = encode.csl{Almid};                  % Channel selection index
kFPphs_ri = floor((AlmidCsl - 1) / 2) + 1;      % Index for phase channel (1 or 2)
kFPamp_ri = mod((AlmidCsl - 1), 2) + 1;         % Index for amplitude channel (1 or 2)
srtlag = encode.strlag(Almid);                  % Start lag (samples) for LFP alignment

% ----------------------------- Analysis Parameters -------------------------
FPphs_ri   = [1 20];      % Phase channels (PFC theta)
phaserange = [4 12];     % Phase frequency band (theta)
FPamp_ri   = [33 48];    % Amplitude channels (HPC gamma)
amprange   = [60 90];    % Amplitude frequency band (gamma)
nfreqs = 100;            % Number of frequency bins for amplitude spectrogram
ncyc = 7;                % Number of cycles for wavelet (not used directly)
sf_LFP = 1000;           % Sampling rate (Hz)
irange = [3 6 9 12 15];  % Indices for ITI epochs (recordlist positions)

% ---------- Convert video-based similarity to freezing indicator ----------
% Cssimval0: vector of similarity values from video tracking (length ~5099)
% A threshold (limTst) defines freezing when similarity is low.
Csslim = zeros(5099, 1);
limTst = 10;
Csslim(Cssimval0(1:5099) < (min(Cssimval0) + limTst)) = 1;  % 1 = freezing
Csslim = [0; Csslim];   % Prepend a zero to align indices

% Upsample the freezing indicator from ~7.5 Hz (video frame rate) to 1000 Hz
FCsslim = zeros(680000, 1);
for ff = 1:680000
    FCsslim(ff) = Csslim(ceil(ff / (1000 / 7.5)));  % Map each ms to the corresponding video frame
end

% ------------------- Loop over ITI epochs (5 epochs) ----------------------
for i = irange
    % Current epoch name (e.g., 'iti1')
    temprl = char(stgl(i));   % NOTE: stgl is defined later in the script, but here it's used; likely loaded from training.mat or a global variable.
    
    % Create output folder for this epoch if it doesn't exist
    if ~exist([cdpath, '\', filename(1:7), '\FCSprt\', temprl, ], 'dir')
        mkdir([cdpath, '\', filename(1:7), '\FCSprt\', temprl, ]);
    end
    
    % Get start and end times (in seconds) for this epoch from variable 'stgl{i}'
    eval(['ks0 = ', char(stgl(i)), ';']);   % ks0 = [start, end]
    % Extract the binary freezing indicator for this epoch (at 1000 Hz)
    FCsslimbb = FCsslim(ks0(1)*1000 : ks0(2)*1000 - 1);
    
    % Duration of the epoch (seconds)
    eval(['timelim = ', char(stgl(i)), '(2) - ', char(stgl(i)), '(1);']);
    
    % Select the specific phase and amplitude channel for this animal
    i_fpN = FPphs_ri(kFPphs_ri);
    j_fpN = FPamp_ri(kFPamp_ri);
    
    % ---- Extract phase signal ----
    lfpphs = {};
    eval(['lfpphs.data = FP.FP', num2str(i_fpN, '%02d'), ...
          '(srtlag + ', char(stgl(i)), '(1)*1000 : srtlag + ', char(stgl(i)), '(2)*1000);']);
    lfpphs.timestamps = (0.001:0.001:timelim)';
    lfpphs.samplingRate = 1000;
    
    % Band‑pass filter to obtain phase (theta band)
    filtered_phase = bz_Filter(lfpphs, 'passband', phaserange, 'filter', 'fir1');
    
    % Bin the phase into 50 bins between -π and π
    numbins = 50;
    phasebins = linspace(-pi, pi, numbins + 1);
    phasecenters = phasebins(1:end-1) + (phasebins(2) - phasebins(1));
    [~, ~, phaseall] = histcounts(filtered_phase.phase, phasebins);
    
    % Separate phase samples into non‑freezing and freezing subsets
    % phaseall0: non‑freezing (set freezing samples to 0, which will be ignored)
    phaseall0 = phaseall;
    phaseall0(FCsslimbb == 1) = 0;   % Remove freezing samples
    % phaseall1: freezing (set non‑freezing samples to 0)
    phaseall1 = phaseall;
    phaseall1(FCsslimbb == 0) = 0;   % Remove non‑freezing samples
    
    % ---- Extract amplitude envelope ----
    lfpamp = {};
    eval(['lfpamp.data = FP.FP', num2str(j_fpN, '%02d'), ...
          '(srtlag + ', char(stgl(i)), '(1)*1000 : srtlag + ', char(stgl(i)), '(2)*1000);']);
    lfpamp.timestamps = (0.001:0.001:timelim)';
    lfpamp.samplingRate = 1000;
    
    % Compute amplitude spectrogram (wavelet) in the gamma band
    wavespec_amp = bz_WaveSpec(lfpamp, 'frange', amprange);
    wavespec_amp.data = log10(abs(wavespec_amp.data));   % Log‑transform for normality
    wavespec_amp.mean = mean(wavespec_amp.data, 1);      % Mean across time for normalization
    
    % Preallocate PAC maps: all, non‑freezing, freezing
    phaseamplitudemap  = zeros(numbins, nfreqs);
    phaseamplitudemap0 = zeros(numbins, nfreqs);
    phaseamplitudemap1 = zeros(numbins, nfreqs);
    
    % For each phase bin, compute the mean amplitude (normalized by the mean over time)
    for bb = 1:numbins
        phaseamplitudemap(bb, :)  = mean(wavespec_amp.data(phaseall == bb, :), 1)  ./ wavespec_amp.mean;
        phaseamplitudemap0(bb, :) = mean(wavespec_amp.data(phaseall0 == bb, :), 1) ./ wavespec_amp.mean;
        phaseamplitudemap1(bb, :) = mean(wavespec_amp.data(phaseall1 == bb, :), 1) ./ wavespec_amp.mean;
    end
    ampfreqs = wavespec_amp.freqs;   % Frequency bins (not used in plotting below)
    
    % ---- Plotting and saving (currently commented out) ----
    % Plot for all data
    a = mean(phaseamplitudemap(:, 33:100), 2);   % Average over a subset of high‑frequency bins
    a = Smooth(a, 3, 'type', 'c');               % Smooth with 3‑point causal filter
    imagesc(0, phasecenters, a)
    % caxis([0.995 1.005]);
    colorbar
    colormap jet
    % (save commands are commented out)
    
    % Plot for non‑freezing data
    a = mean(phaseamplitudemap0(:, 33:100), 2);
    a = Smooth(a, 3, 'type', 'c');
    imagesc(0, phasecenters, a)
    colorbar
    colormap jet
    
    % Plot for freezing data
    a = mean(phaseamplitudemap1(:, 33:100), 2);
    a = Smooth(a, 3, 'type', 'c');
    imagesc(0, phasecenters, a)
    colorbar
    colormap jet
    
    i   % Display current epoch index (for progress tracking)
end



%% ========== SECTION: Compute correlation (r) and regression slope ===========
% This part loads the previously saved PAC maps (freezing and non‑freezing)
% for each ITI, extracts the phase of maximum amplitude, then performs
% circular‑linear correlation and linear regression across the 5 ITIs to
% test for phase precession.

clear; clc;

src = 2;    % 1 for 'CSonly' ; 2 for 'CSUS'
Almid = 5;  % Different animal than above

cdpath = '';
cd(cdpath);
load([cdpath, 'pre_data\timestamp.mat']);

if src == 1
    cdpath = [cdpath, 'CSonly\'];
    load([cdpath, 'encode_csonly.mat']);
end
if src == 2
    cdpath = [cdpath, 'CSUS\'];
    load([cdpath, 'encode_csus.mat']);
end

% Define epoch labels (sound, trace, ITI for each of 5 trials)
stgl = {'sound1', 'trace1', 'iti1', 'sound2', 'trace2', 'iti2', ...
        'sound3', 'trace3', 'iti3', 'sound4', 'trace4', 'iti4', ...
        'sound5', 'trace5', 'iti5'};

% Extract metadata for this animal
lengthTit = encode.lengthTitlist(Almid);
AlmidCsl = encode.csl{Almid};
kFPphs_ri = floor((AlmidCsl - 1) / 2) + 1;
kFPamp_ri = mod((AlmidCsl - 1), 2) + 1;
filename = char(encode.filename(Almid));
srtlag = encode.strlag(Almid);

% Analysis parameters (same as before)
FPphs_ri = [1 20];
phaserange = [4 12];
FPamp_ri = [33 58];
amprange = [60 90];
ncyc = 7;
sf_LFP = 1000;
numbins = 50;
nfreqs = 100;

% Build a suffix string for file naming (not used in this section)
Sfilename = ['_', num2str(FPphs_ri(1), '%02d'), '_', num2str(FPphs_ri(2), '%02d'), '_', ...
             num2str(phaserange(1)), '_', num2str(phaserange(2)), '_', ...
             num2str(FPamp_ri(1), '%02d'), '_', num2str(FPamp_ri(2), '%02d'), '_', ...
             num2str(amprange(1)), '_', num2str(amprange(2))];

recordlist = {'sound1','trace1','iti1','sound2','trace2','iti2', ...
              'sound3','trace3','iti3','sound4','trace4','iti4', ...
              'sound5','trace5','iti5'};
temparr = [3, 6, 9, 12, 15];   % Only ITI epochs

% ------------------------ Freezing condition -------------------------------
kk = 1;
r2data = [];   % Will store preferred phase (max amplitude) for each ITI

for bb = temparr
    temprl = char(recordlist(bb));
    i_fpN = FPphs_ri(kFPphs_ri);
    j_fpN = FPamp_ri(kFPamp_ri);
    
    % Load the freezing PAC map for this epoch
    load([cdpath, '\', filename(1:7), '\FCSprt\', temprl, '\', filename, ...
          '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_Frz.mat']);
    
    % Average over selected high‑frequency bins (columns 33:100)
    a = mean(phaseamplitudemap1(:, 33:100), 2);
    a = Smooth(a, 3, 'type', 'c');
    disp([filename, ' data, phase ch ', num2str(i_fpN), ', amp ch ', num2str(j_fpN), ' r2 completed!']);
    
    % Find the phase bin with maximum amplitude (preferred phase)
    Am = phasecenters(find(a == max(a)));
    r2data(kk) = Am;
    kk = kk + 1;
end

% Circular‑linear correlation between preferred phase and ITI index (1..5)
X = [1 2 3 4 5]';
[rval, pval] = circ_corrcl(r2data', X);
r2val = rval * rval;

% Adjust first and last phase values by adding multiples of 2π (for phase unwrapping)
r2data(1) = r2data(1) + 2 * pi * encode.fpar1{Almid};
r2data(5) = r2data(5) + 2 * pi * encode.fpar5{Almid};

% Linear regression: phase vs. ITI index
X1 = [1; 2; 3; 4; 5];
x1 = ones(size(X1,1), 1);
X1 = [x1 X1];
[b, ~, ~, ~, stats] = regress(r2data', X1);

% Plot: phase (with wrap) vs. ITI index
plot(r2data', X);
hold on
plot(r2data' + 2*pi, X);
hold off
ax = gca;
set(ax, 'YDir', 'reverse');
xlim([-pi 3*pi]);
xlabel(sprintf('p: %.2f | r2: %.2f | slope: %.2f', pval, r2val, b(2)));

% Save the figure in multiple formats
saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_Frz.eps'], 'psc2');
saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_Frz.fig']);
saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_Frz.jpg']);

% ------------------------ Non‑freezing condition ---------------------------
kk = 1;
r2data = [];

for bb = temparr
    temprl = char(recordlist(bb));
    i_fpN = FPphs_ri(kFPphs_ri);
    j_fpN = FPamp_ri(kFPamp_ri);
    
    % Load the non‑freezing PAC map
    load([cdpath, '\', filename(1:7), '\FCSprt\', temprl, '\', filename, ...
          '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_nonFrz.mat']);
    
    a = mean(phaseamplitudemap0(:, 33:100), 2);
    a = Smooth(a, 3, 'type', 'c');
    disp([filename, ' data, phase ch ', num2str(i_fpN), ', amp ch ', num2str(j_fpN), ' r2 completed!']);
    
    Am = phasecenters(find(a == max(a)));
    r2data(kk) = Am;
    kk = kk + 1;
end

% Circular‑linear correlation
X = [1 2 3 4 5]';
[rval, pval] = circ_corrcl(r2data', X);
r2val = rval * rval;

% Unwrap with non‑freezing specific multipliers
r2data(1) = r2data(1) + 2 * pi * encode.nfpar1{Almid};
r2data(5) = r2data(5) + 2 * pi * encode.nfpar5{Almid};

% Linear regression
X1 = [1; 2; 3; 4; 5];
x1 = ones(size(X1,1), 1);
X1 = [x1 X1];
[b, ~, ~, ~, stats] = regress(r2data', X1);

% Plot and save
plot(r2data', X);
hold on
plot(r2data' + 2*pi, X);
hold off
ax = gca;
set(ax, 'YDir', 'reverse');
xlim([-pi 3*pi]);
xlabel(sprintf('p: %.2f | r2: %.2f | slope: %.2f', pval, r2val, b(2)));

saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_nonFrz.eps'], 'psc2');
saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_nonFrz.fig']);
saveas(gcf, [cdpath, '\', filename(1:7), '\FCSprt\', filename, ...
              '_', num2str(Almid), '_', num2str(i_fpN), 'PfcTheta_', num2str(j_fpN), 'HpcGamma_nonFrz.jpg']);

