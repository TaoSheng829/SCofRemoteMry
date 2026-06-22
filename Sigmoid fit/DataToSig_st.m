function outputArg1 = DataToSig_st(xData, yData, inputArg3)
% DataToSig_st: Fit a four‑parameter sigmoid (logistic) curve to data.
%
%   This function normalises the y‑data to the range [0, 1], then fits a
%   sigmoid model using nonlinear least squares (lsqcurvefit). The model is:
%       y = a ./ (1 + exp(-b * (x - c))) + d
%   where:
%       a = vertical scaling (amplitude)
%       b = growth rate (slope at inflection)
%       c = x‑offset (inflection point, i.e., the x‑value at 50% of the rise)
%       d = vertical offset (baseline)
%
%   Since yData is normalised to [0, 1], the fitted parameters correspond to
%   this normalised scale. The function optionally plots the raw data, the
%   fitted curve, and a vertical line at the inflection point (c).
%
%   Inputs:
%       xData      : Vector of independent variable values.
%       yData      : Vector of dependent variable values (will be normalised).
%       inputArg3  : String or numeric flag to control plotting:
%                    '1' or 1 = show plot; any other value = no plot.
%
%   Output:
%       outputArg1 : The fitted parameters [a, b, c, d] from lsqcurvefit.
%
%   Example:
%       x = 0:0.1:10;
%       y = 1 ./ (1 + exp(-0.8 * (x - 5))) + 0.1 + 0.05*randn(size(x));
%       params = DataToSig_st(x, y, '1');
%
%   NOTE: yData is normalised using normalize(..., 'range'), which scales
%         the data to [0, 1]. The fitted parameters (especially a and d)
%         are relative to this normalised scale, not the original y‑units.

    % ---- Normalise y‑data to range [0, 1] ----
    % This ensures the sigmoid fit is robust regardless of the absolute scale
    % of the input yData. The returned parameters correspond to this
    % normalised y‑axis.
    yData = normalize(yData, 'range');

    % ---- Define the sigmoid model ----
    % Parameters:
    %   params(1) = a : amplitude (vertical scale) – in normalised units
    %   params(2) = b : growth rate (steepness of the curve)
    %   params(3) = c : x‑offset (inflection point, where y ≈ a/2 + d)
    %   params(4) = d : vertical offset (baseline) – in normalised units
    sigmoid = @(params, x) params(1) ./ (1 + exp(-params(2) .* (x - params(3)))) + params(4);

    % ---- Initial guess for parameters ----
    % These values should be adjusted based on the data and prior knowledge.
    % [a, b, c, d] – here: amplitude ~ -2 (note: after normalisation, a may be negative
    % if the data is inverted; usually a is positive for a rising sigmoid).
    initialGuess = [-2, 0, 7, 1.5];
    % Alternative guess (commented out): [0.1, 0.1, 8, 0]

    % ---- Perform nonlinear least‑squares fitting ----
    % Uses lsqcurvefit (requires Optimization Toolbox). The function
    % iteratively adjusts parameters to minimise the sum of squared errors.
    paramsFit = lsqcurvefit(sigmoid, initialGuess, xData, yData);

    % ---- Extract fitted parameters for convenience ----
    a = paramsFit(1);   % Amplitude (normalised scale)
    b = paramsFit(2);   % Growth rate
    c = paramsFit(3);   % Inflection point (x‑offset)
    d = paramsFit(4);   % Vertical offset (normalised scale)

    % ---- Generate smooth curve for plotting ----
    xFit = linspace(min(xData), max(xData), 100);
    yFit = sigmoid(paramsFit, xFit);

    % ---- Optional: Plot the results ----
    if inputArg3 == '1'   % Note: expects a string '1', not numeric 1
        figure;
        % Plot raw data points
        plot(xData, yData, 'o', 'LineWidth', 2.5);
        hold on;
        % Plot fitted sigmoid curve
        plot(xFit, yFit, '-', 'LineWidth', 2);
        % Plot vertical line at the inflection point (c)
        plot([paramsFit(3), paramsFit(3)], [0, 1], 'k--', 'LineWidth', 1.5);
        hold off;

        % (Optional) Additional formatting – commented out as they may not be needed
        % set(gca, 'xtick', 0:180:1);
        % set(gca, 'ytick', 0:1:0.01);
        % ylim([0 1]);

        grid on;
        legend('Data points', 'Fitted curve', 'Inflection point (c)', 'Location', 'best');
        title('Sigmoid Curve Fit');
        xlabel('x');
        ylabel('y (normalised)');
    end

    % ---- Return the fitted parameters ----
    outputArg1 = paramsFit;

end