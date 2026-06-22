% phase2slope.m
% This script computes the linear regression slope for two sets of data
% (CSonly and CSUS) across 5 equally spaced X values (1 to 5).
% It loads a precomputed .mat file containing the variables CSonly and CSUS,
% then fits a simple linear model y = b1 + b2*X for each of the 8 rows
% (presumably 8 subjects or 8 experimental conditions).
%
% The slopes (b2) are stored in separate vectors for later analysis.

clear; clc;  % Clear workspace and command window

% Load the pre-processed data containing 'CSonly' and 'CSUS' matrices.
% Expected dimensions: both should be 8x5 (8 rows, 5 columns).
load('**.mat');

% Initialize output arrays for slopes (one per row)
slope_CSonly = zeros(8, 1);
slope_CSUS   = zeros(8, 1);

% Define the independent variable (common to all regressions)
% Here we assume X represents 5 ordered bins or time points (e.g., positions along a track).
X1 = [1; 2; 3; 4; 5];   % 5 levels
X = [ones(size(X1,1), 1), X1];   % Design matrix with intercept column

% ---- Regression for CSonly data ----
for i = 1:8
    % Extract the i-th row as the dependent variable (5 data points)
    y = CSonly(i, :)';   % Transpose to column vector

    % Perform multiple linear regression (model: y = b1 + b2*X1)
    % The 'regress' function returns coefficients, confidence intervals,
    % residuals, and statistics (R², F, p-value, error variance).
    [b, ~, ~, ~, stats] = regress(y, X);

    % Store the slope (coefficient for X1)
    slope_CSonly(i) = b(2);
end

% ---- Regression for CSUS data ----
for i = 1:8
    y = CSUS(i, :)';   % Dependent variable for the i-th row

    [b, ~, ~, ~, stats] = regress(y, X);

    slope_CSUS(i) = b(2);
end

% At this point, slope_CSonly and slope_CSUS each contain 8 slope values
% which can be saved or used for further statistical comparisons.