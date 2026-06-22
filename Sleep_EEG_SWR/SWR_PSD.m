%% SWR_PSD.m: Generate multi-panel figures for each detected SWR event
% This script loads PFC and HPC data, detects ripples in the HPC channel,
% and for each ripple event (only during NREM), creates a 9‑panel figure
% showing wavelet spectra, filtered traces, and ripple band details for
% both PFC and HPC. All figures are saved as JPEGs.

clear; clc;

load('**.mat');
animalIdx = 1;
dayIdx = 22;

fold_name = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_foldname;
LFP_AI_path = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_path;
labels_state = experiment.Animals{animalIdx}.Days(dayIdx).State_all_data';

% Loop over HPC channels 33‑48
for HPC_i = 33:48

    % Load PFC channel (fixed FP01)
    load([LFP_AI_path, 'FP01']);
    tempPfcFP = tempFP;
    Filter_tempPfcFP1 = bz_Filter(tempPfcFP, 'passband', [4 12], 'filter', 'fir1');
    Filter_tempPfcFP2 = bz_Filter(tempPfcFP, 'passband', [30 45], 'filter', 'fir1');
    Filter_tempPfcFP3 = bz_Filter(tempPfcFP, 'passband', [60 90], 'filter', 'fir1');

    % Load HPC channel
    load([LFP_AI_path, 'FP', num2str(HPC_i, '%02d')]);
    tempHpcFP = tempFP;

    % Detect ripples
    fq = 1000;
    timestamps = ((1/fq)):((1/fq)):((length(tempHpcFP)/fq));
    r = bz_FindRipples(tempHpcFP, timestamps', 'thresholds', [3 5], ...
                       'durations', [10 100], 'frequency', 1100, ...
                       'passband', [130 200], 'EMGThresh', 0);

    % Pre‑filter HPC bands
    Filter_tempHpcFP1 = bz_Filter(tempHpcFP, 'passband', [4 12], 'filter', 'fir1');
    Filter_tempHpcFP2 = bz_Filter(tempHpcFP, 'passband', [30 45], 'filter', 'fir1');
    Filter_tempHpcFP3 = bz_Filter(tempHpcFP, 'passband', [60 90], 'filter', 'fir1');
    Filter_tempFP = bz_Filter(tempHpcFP, 'passband', [130 200], 'filter', 'fir1');
    Filter_tempFP0 = bz_Filter(tempHpcFP, 'passband', [1 inf], 'filter', 'fir1');

    % Create output directory
    save_dir = [cd, '\Aid_', num2str(animalIdx), '_dayIdx_', num2str(dayIdx), ...
                '\', num2str(HPC_i, '%02d'), '_SWR_PSDtrace\'];
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    t = .001:.001:(1100*0.001)+0.001;   % Time vector for 1100‑ms windows
    colormap_jet = jet;

    set(0,'DefaultFigureVisible','off');
    set(0,'DefaultFigureRenderer','painters');

    % Loop over all detected ripple events
    for ii = 1:length(r.peaks)
        tempRs = fix(r.peaks(ii)*1000);

        % Only consider NREM epochs
        if labels_state(tempRs) ~= 3
            fprintf('Skipped! %.0f \n', ii);
            continue;
        end
        if tempRs + 1100 > length(tempFP)
            continue;
        end

        try
            fig = figure('Visible','off','OuterPosition',[85 57 1068 1300]);

            % Subplot 1: State label around ripple
            subplot(9,1,1);
            plot(labels_state(tempRs-100:tempRs+1000));
            ylabel('State');
            set(gca,'TickDir','out');
            xlim([0 1100]);

            % Subplot 2: PFC CWT (0‑140 Hz)
            subplot(9,1,2);
            [cfs,f] = cwt(tempPfcFP(tempRs-100:tempRs+1000), 1100);
            pcolor(t, f, abs(cfs));
            shading interp;
            ylim([0 140]);
            colorbar;
            colormap(gca, colormap_jet);
            set(gca,'TickDir','out');
            xlabel(sprintf(['Almid: %.0f | Name: %s | PFC: 33 | HPC: %d | Window: %d'],...
                           animalIdx, fold_name, HPC_i, ii));
            ylabel('Frequency (Hz)');

            % Subplot 3: PFC raw + theta
            subplot(9,1,3);
            plot(tempPfcFP(tempRs-100:tempRs+1000));
            hold on;
            plot(Filter_tempPfcFP1(tempRs-100:tempRs+1000), 'r');
            hold off;
            set(gca,'TickDir','out');
            ylabel('Amplitude');
            legend({'Raw', '4-12Hz'}, 'Location', 'best');
            xlim([0 1100]);

            % Subplot 4: PFC gamma bands
            subplot(9,1,4);
            plot(Filter_tempPfcFP2(tempRs-100:tempRs+1000));
            hold on;
            plot(Filter_tempPfcFP3(tempRs-100:tempRs+1000), 'r');
            hold off;
            set(gca,'TickDir','out');
            ylabel('Amplitude');
            legend({'30-45Hz', '60-90Hz'}, 'Location', 'best');
            xlim([0 1100]);

            % Subplot 5: HPC CWT
            subplot(9,1,5);
            [cfs,f] = cwt(tempHpcFP(tempRs-100:tempRs+1000), 1100);
            pcolor(t, f, abs(cfs));
            shading interp;
            ylim([0 140]);
            colorbar;
            colormap(gca, colormap_jet);
            set(gca,'TickDir','out');
            xlabel('Time (s)');
            ylabel('Frequency (Hz)');

            % Subplot 6: HPC raw (broadband) + theta
            subplot(9,1,6);
            plot(Filter_tempFP0(tempRs-100:tempRs+1000));
            hold on;
            plot(Filter_tempHpcFP1(tempRs-100:tempRs+1000), 'r');
            hold off;
            set(gca,'TickDir','out');
            xlabel('Time (s)');
            ylabel('Amplitude');
            legend({'Broadband', '4-12Hz'}, 'Location', 'best');
            xlim([0 1100]);

            % Subplot 7: HPC gamma bands
            subplot(9,1,7);
            plot(Filter_tempHpcFP2(tempRs-100:tempRs+1000));
            hold on;
            plot(Filter_tempHpcFP3(tempRs-100:tempRs+1000), 'r');
            hold off;
            set(gca,'TickDir','out');
            xlabel('Time (s)');
            ylabel('Amplitude');
            legend({'30-45Hz', '60-90Hz'}, 'Location', 'best');
            xlim([0 1100]);

            % Subplot 8: Ripple‑band (130‑200 Hz) trace
            subplot(9,1,8);
            plot(Filter_tempFP(tempRs-100:tempRs+1000));
            set(gca,'TickDir','out');
            xlim([0 1100]);
            xlabel('Time (ms)');
            title(sprintf('Ch %d, ripple #%d', HPC_i, ii));

            % Subplot 9: CWT of ripple‑band (60‑200 Hz)
            subplot(9,1,9);
            [cfs,f] = cwt(tempFP(tempRs-100:tempRs+1000), 1100);
            pcolor(t, f, abs(cfs));
            shading interp;
            ylim([60 200]);
            colormap(gca, colormap_jet);
            caxis([0 0.2]);
            set(gca,'TickDir','out');
            xlabel('Time (s)');
            ylabel('Frequency (Hz)');

            % Save
            filename = sprintf('PFC01_HPC33_SWR_%04d.jpg', ii);
            saveas(fig, fullfile(save_dir, filename));
            close(fig);

            if mod(ii, 50) == 0
                fprintf('Processed %d/%d windows\n', ii, length(r.peaks));
            end

        catch ME
            fprintf('Error at ripple %d: %s\n', ii, ME.message);
            if exist('fig', 'var') && ishandle(fig)
                close(fig);
            end
            continue;
        end
    end
end

set(0,'DefaultFigureVisible','on');
fprintf('All SWR windows processed.\n');
