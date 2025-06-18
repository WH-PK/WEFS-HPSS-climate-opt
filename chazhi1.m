function [z] = chazhi1(x, y, x0)
% Linear interpolation function (1D)
% Inputs:
%   x  - vector of known x values (must be sorted in ascending order)
%   y  - corresponding y values at x
%   x0 - query points at which to interpolate
% Output:
%   z  - interpolated values at x0

mm = length(x);
nn = length(x0);
z = zeros(size(x0));  % Initialize output

for jj = 1:nn
    xc = x0(jj);  % Current interpolation point

    % Case 1: extrapolation to left
    if xc <= min(x)
        z(jj) = min(y);
        continue;
    end

    % Case 2: extrapolation to right
    if xc >= max(x)
        z(jj) = max(y);
        continue;
    end

    % Case 3: interpolation within bounds
    for ii = 1:mm-1
        if xc == x(ii)
            z(jj) = y(ii);
            break;
        elseif xc > x(ii) && xc < x(ii+1)
            % Linear interpolation formula
            z(jj) = y(ii) * (x(ii+1) - xc) / (x(ii+1) - x(ii)) + ...
                    y(ii+1) * (xc - x(ii)) / (x(ii+1) - x(ii));
            break;
        end
    end
end
end
