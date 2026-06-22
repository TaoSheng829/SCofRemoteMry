%% spike_test.m: Simulated data and K‑means clustering for spike classification
% This script generates synthetic spike data with two distinct neuron types,
% performs K‑means clustering, and visualises the results with multiple
% diagnostic plots to assess clustering quality.

clear; clc; close all;

%% ===================== 1. Create simulated data ===========================
fprintf('Creating simulated data...\n');

rng(42);   % Set random seed for reproducibility

% ---- Type A neurons (putative interneurons) ----
n_typeA = 15;
% Characteristics: higher firing rate, larger AUC, wider spikes
typeA_data = [
    (1:n_typeA)', ...                          % Neuron ID
    normrnd(200, 105, n_typeA, 1), ...         % AUC (arbitrary units)
    normrnd(250, 40, n_typeA, 1), ...          % Spike half‑width (μs)
    normrnd(25, 10, n_typeA, 1)                % Firing rate (Hz)
];

% ---- Type B neurons (putative projection neurons) ----
n_typeB = 130;
% Characteristics: lower firing rate, smaller AUC, narrower spikes
typeB_data = [
    (n_typeA + 1:n_typeA + n_typeB)', ...      % Neuron ID
    normrnd(500, 50, n_typeB, 1), ...          % AUC
    normrnd(450, 70, n_typeB, 1), ...          % Half‑width (μs)
    normrnd(10, 3, n_typeB, 1)                 % Firing rate (Hz)
];

% ---- Merge and shuffle ----
data = [typeA_data; typeB_data];
shuffle_idx = randperm(size(data, 1));
data = data(shuffle_idx, :);

fprintf('Simulated data created!\n');
fprintf('Total neurons: %d\n', size(data, 1));
fprintf('Columns: [ID, AUC, Half‑width, Firing rate]\n\n');

%% ===================== 2. Data preprocessing ==============================
fprintf('Preprocessing data...\n');

features = data(:, 2:4);   % Extract feature columns

% Display summary statistics
fprintf('Feature statistics:\n');
feature_names = {'Firing rate (Hz)', 'AUC', 'Half‑width (μs)'};
for i = 1:3
    fprintf('  %s: mean=%.2f, std=%.2f, range=[%.2f, %.2f]\n', ...
        feature_names{i}, mean(features(:,i)), std(features(:,i)), ...
        min(features(:,i)), max(features(:,i)));
end

% Z‑score standardisation
features_scaled = zscore(features);
fprintf('Data standardised (Z‑score).\n\n');

%% ===================== 3. K‑means clustering ==============================
fprintf('Performing K‑means clustering...\n');

numClusters = 2;

[idx, centroids, sumd] = kmeans(features_scaled, numClusters, ...
    'Replicates', 20, ...    % Run 20 times to avoid local optima
    'MaxIter', 1000, ...
    'Display', 'final');

% Cluster sizes
cluster_sizes = zeros(numClusters, 1);
for i = 1:numClusters
    cluster_sizes(i) = sum(idx == i);
end

fprintf('Clustering complete!\n');
for i = 1:numClusters
    fprintf('  Cluster %d: %d neurons (%.1f%%)\n', ...
        i, cluster_sizes(i), 100 * cluster_sizes(i) / sum(cluster_sizes));
end

%% ===================== 4. Identify clusters ===============================
% Find the cluster that contains the 15 Type A neurons.
fprintf('\nIdentifying interneuron cluster...\n');

[~, cluster_with_one_idx] = min(abs(cluster_sizes - n_typeA));

if cluster_sizes(cluster_with_one_idx) == n_typeA
    fprintf('Found cluster with %d neurons: Cluster %d\n', n_typeA, cluster_with_one_idx);
else
    fprintf('Closest cluster: Cluster %d (n=%d)\n', ...
        cluster_with_one_idx, cluster_sizes(cluster_with_one_idx));
end

other_cluster_idx = setdiff(1:numClusters, cluster_with_one_idx);
cluster_one_idx = find(idx == cluster_with_one_idx);
cluster_other_idx = find(idx == other_cluster_idx);

%% ===================== 5. Visualise results ===============================
fprintf('\nGenerating visualisations...\n');

% ---- Main 3D scatter plot ----
figure('Position', [100, 100, 700, 600], 'Name', 'Neuron Clustering');
hold on;

% Interneuron cluster (red)
scatter3(features_scaled(cluster_one_idx, 1), ...
         features_scaled(cluster_one_idx, 2), ...
         features_scaled(cluster_one_idx, 3), ...
         100, 'b', 'o', 'filled', ...
         'LineWidth', 1, 'MarkerEdgeColor', 'k', ...
         'DisplayName', sprintf('Putative interneurons (n=%d)', length(cluster_one_idx)));

% Projection neuron cluster (blue)
scatter3(features_scaled(cluster_other_idx, 1), ...
         features_scaled(cluster_other_idx, 2), ...
         features_scaled(cluster_other_idx, 3), ...
         60, 'r', 'o', 'filled', ...
         'LineWidth', 1, 'MarkerEdgeColor', 'k', ...
         'DisplayName', sprintf('Putative projection neurons (n=%d)', length(cluster_other_idx)));

xlabel('Firing rate (Norm.)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('AUC (Norm.)', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('Spike Half‑width (Norm.)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;
view(45, 30);
hold off;

%% ===================== 6. Display neuron IDs ==============================
fprintf('\n=== Clustering details ===\n');

fprintf('\nInterneuron cluster (n=%d, IDs):\n', length(cluster_one_idx));
neuron_ids_int = data(cluster_one_idx, 1);
disp(reshape(neuron_ids_int, 1, []));

fprintf('\nProjection neuron cluster (n=%d, IDs):\n', length(cluster_other_idx));
neuron_ids_proj = data(cluster_other_idx, 1);
disp(reshape(neuron_ids_proj, 10, [])');

%% ===================== 7. Clustering quality assessment ===================
fprintf('\n=== Clustering quality assessment ===\n');

% Silhouette coefficient
silhouette_vals = silhouette(features_scaled, idx);
avg_silhouette = mean(silhouette_vals);

% Within‑cluster distances
within_cluster_dist = zeros(numClusters, 1);
for i = 1:numClusters
    cluster_points = features_scaled(idx == i, :);
    cluster_center = centroids(i, :);
    distances = sqrt(sum((cluster_points - cluster_center).^2, 2));
    within_cluster_dist(i) = mean(distances);
end

% Between‑cluster distance
between_cluster_dist = sqrt(sum((centroids(1,:) - centroids(2,:)).^2));

fprintf('Average silhouette: %.4f\n', avg_silhouette);
fprintf('  Interpretation: 0.7+ = strong, 0.5‑0.7 = moderate, 0.25‑0.5 = weak, <0.25 = none\n');
fprintf('\nInterneuron mean within‑cluster distance: %.4f\n', within_cluster_dist(cluster_with_one_idx));
fprintf('Projection neuron mean within‑cluster distance: %.4f\n', within_cluster_dist(other_cluster_idx));
fprintf('Between‑cluster distance: %.4f\n', between_cluster_dist);
fprintf('Distance ratio (between/within): %.4f\n', ...
    between_cluster_dist / mean(within_cluster_dist));

%% ===================== 8. Silhouette plot =================================
figure('Position', [100, 100, 800, 600], 'Name', 'Silhouette Plot');

[silhouette_vals_sorted, idx_sorted] = sort(silhouette_vals);
idx_sorted_labels = idx(idx_sorted);

% Colour by cluster
h = barh(1:length(silhouette_vals_sorted), silhouette_vals_sorted, 'FaceColor', 'flat');
for i = 1:length(silhouette_vals_sorted)
    if idx_sorted_labels(i) == cluster_with_one_idx
        h.CData(i,:) = [1, 0, 0];   % Red for interneuron cluster
    else
        h.CData(i,:) = [0, 0, 1];   % Blue for projection neuron cluster
    end
end

xlabel('Silhouette value', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Neuron index (sorted)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Silhouette Distribution (mean = %.4f)', avg_silhouette), ...
      'FontSize', 14, 'FontWeight', 'bold');
grid on;
xlim([-1, 1]);
line([0, 0], [0, length(silhouette_vals_sorted)+1], 'Color', 'k', 'LineStyle', '--');

%% ===================== 9. Feature distribution histograms =================
figure('Position', [100, 100, 1200, 800], 'Name', 'Feature Distributions');

feature_titles = {'Firing rate (Hz)', 'AUC', 'Half‑width (μs)'};

for i = 1:3
    % Histogram
    subplot(2, 3, i);
    hold on;
    histogram(features(cluster_one_idx, i), 'FaceColor', 'r', ...
              'EdgeColor', 'k', 'BinWidth', std(features(:,i))/5, ...
              'Normalization', 'probability', 'DisplayName', 'Interneurons');
    histogram(features(cluster_other_idx, i), 'FaceColor', 'b', ...
              'EdgeColor', 'k', 'BinWidth', std(features(:,i))/5, ...
              'Normalization', 'probability', 'DisplayName', 'Projection');
    xlabel(feature_titles{i}, 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Probability', 'FontSize', 11, 'FontWeight', 'bold');
    title(feature_titles{i}, 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    hold off;

    % Boxplot
    subplot(2, 3, i+3);
    box_data = [features(cluster_one_idx, i); features(cluster_other_idx, i)];
    group = [ones(length(cluster_one_idx), 1); 2*ones(length(cluster_other_idx), 1)];
    boxplot(box_data, group, 'Labels', {'Interneurons', 'Projection'}, 'Colors', 'rb');
    ylabel(feature_titles{i}, 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('%s (boxplot)', feature_titles{i}), 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
end