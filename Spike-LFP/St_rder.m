function [outputArg1] = St_rder(tempM)
% St_rder: Sort rows of a matrix based on the index of the maximum value in each row.
%   This function takes a matrix where each row represents a neuron's response
%   vector (e.g., normalized lag vector). For each row, it finds the column index
%   at which the maximum value occurs (the peak position). It then sorts the rows
%   in descending order of this peak index (i.e., rows with larger peak positions
%   are moved to the top).
%
%   Input:
%       tempM : Numeric matrix of size [NeurNum x N], where each row is a vector
%               to be sorted.
%   Output:
%       outputArg1 : The same matrix with rows reordered according to the peak
%                    position (descending order).
%
%   Example:
%       M = [1 2 3; 4 5 1; 2 9 8];   % peaks at cols 3, 2, 3 (ties resolved first)
%       sortedM = St_rder(M);        % rows with peak at col 3 first, then col 2

% Determine the number of rows (neurons)
NeurNum = length(tempM(:, 1));

% Initialize a copy of the input matrix (will be reordered)
vector_norm = tempM;
r_ts = [];   % Preallocate a vector to store the peak index for each row

% -------------------------------------------------------------------------
% Step 1: For each row, find the column index of the maximum value.
%         Note: If there are multiple maxima, 'find' returns the first occurrence.
% -------------------------------------------------------------------------
for i = 1:NeurNum
    % Find the first column where the row reaches its maximum
    r_ts(i) = min(find(vector_norm(i, :) == max(vector_norm(i, :))));
end

% -------------------------------------------------------------------------
% Step 2: Sort rows in descending order of their peak indices (r_ts).
%         A simple bubble‑sort algorithm swaps rows when the current row's
%         peak index is smaller than the next row's (to bring larger indices up).
% -------------------------------------------------------------------------
for m = 1:NeurNum - 1
    for n = m + 1:NeurNum
        if r_ts(m) < r_ts(n)
            % Swap the peak indices
            rtp = r_ts(n);
            r_ts(n) = r_ts(m);
            r_ts(m) = rtp;
            
            % Swap the corresponding rows in the matrix
            rtp1 = vector_norm(n, :);
            vector_norm(n, :) = vector_norm(m, :);
            vector_norm(m, :) = rtp1;
        end
    end
end

% Return the reordered matrix
outputArg1 = vector_norm;

end