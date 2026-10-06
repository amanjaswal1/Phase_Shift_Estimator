function [phi_deg, diag] = pse_batch(sig1, sig2, dt, T_filter, prefilter_hz, warm_start)
%PSE_BATCH  Vectorised estimator for whole signal vectors (offline use).
%
%   phi_deg = pse_batch(sig1, sig2, dt, T_filter)
%   phi_deg = pse_batch(sig1, sig2, dt, T_filter, prefilter_hz)
%   phi_deg = pse_batch(sig1, sig2, dt, T_filter, prefilter_hz, warm_start)
%   [phi_deg, diag] = pse_batch(...)
%
%   Gives the same output as PSE_RUN (sample-by-sample loop) but runs one
%   or two orders of magnitude faster. This works because every stage of
%   the estimator - the DC-removal means, the correlation products and the
%   RMS estimates - is a first-order linear IIR filter
%
%       y[k] = (1 - a) * y[k-1] + a * x[k],     a = dt / (T_filter + dt)
%
%   applied to the output of the previous stage, so each stage can be
%   computed for the whole record with FILTER(). Only the final acos and the
%   lead/lag decision are point-wise non-linear operations.
%
%   With warm_start (default true) each filter uses a_k = max(a, 1/k): the
%   plain cumulative mean for the first ~T_filter/dt samples, then the fixed
%   exponential weight - see PSE_INIT.
%
%   diag (optional) returns the intermediate series: cos_phi, rms1, rms2,
%   prod and cross.
%
%   See also PSE_RUN, PSE_STEP, PSE_INIT.

    if nargin < 5 || isempty(prefilter_hz)
        prefilter_hz = 0;
    end
    if nargin < 6 || isempty(warm_start)
        warm_start = true;
    end
    if numel(sig1) ~= numel(sig2)
        error('pse_batch:size', 'sig1 and sig2 must have the same length.');
    end
    shape = size(sig1);
    x1 = sig1(:);
    x2 = sig2(:);

    % Optional identical pre-filter (2 cascaded first-order sections),
    % seeded with the first sample exactly like PSE_STEP.
    if prefilter_hz > 0
        tau = 1 / (2*pi*prefilter_hz);
        ap  = dt / (tau + dt);
        x1 = ewma(ewma(x1, ap, x1(1), false), ap, x1(1), false);
        x2 = ewma(ewma(x2, ap, x2(1), false), ap, x2(1), false);
    end

    a = dt / (T_filter + dt);

    % 1. DC removal
    ac1 = x1 - ewma(x1, a, x1(1), warm_start);
    ac2 = x2 - ewma(x2, a, x2(1), warm_start);

    % 2. Correlation products and RMS
    prod  = ewma(ac1 .* ac2, a, 0, warm_start);
    d_ac1 = [ac1(1); diff(ac1)] / dt;
    cross = ewma(d_ac1 .* ac2, a, 0, warm_start);
    rms1  = sqrt(ewma(ac1 .^ 2, a, 0, warm_start));
    rms2  = sqrt(ewma(ac2 .^ 2, a, 0, warm_start));

    % 3./4. Magnitude and sign
    rms_min = 1e-3;
    ok = (rms1 > rms_min) & (rms2 > rms_min);
    c = zeros(size(prod));
    c(ok) = prod(ok) ./ (rms1(ok) .* rms2(ok));
    c = max(-1, min(1, c));
    phi = acos(c) * 180 / pi;
    phi(cross > 0) = -phi(cross > 0);
    phi(~ok) = 0;

    phi_deg = reshape(phi, shape);
    if nargout > 1
        c(~ok) = NaN;
        diag = struct('cos_phi', reshape(c, shape), ...
                      'rms1', reshape(rms1, shape), 'rms2', reshape(rms2, shape), ...
                      'prod', reshape(prod, shape), 'cross', reshape(cross, shape));
    end
end

function y = ewma(x, a, y_prev, warm)
% First-order IIR low-pass  y[k] = (1-a_k) y[k-1] + a_k x[k],  y[0] = y_prev.
% warm = false: a_k = a.   warm = true: a_k = max(a, 1/k), i.e. the plain
% cumulative mean for the first K samples, then the fixed exponential weight.
    if ~warm
        y = filter(a, [1, -(1 - a)], x, (1 - a) * y_prev);
        return
    end
    K = floor(1 / a);                       % last k with 1/k > a
    if K >= 1 && 1 / K <= a, K = K - 1; end
    if 1 / (K + 1) > a,      K = K + 1; end
    K = min(K, numel(x));
    y = zeros(size(x));
    y(1:K) = cumsum(x(1:K)) ./ (1:K)';
    if K < numel(x)
        y_K = 0;
        if K > 0, y_K = y(K); end
        y(K+1:end) = filter(a, [1, -(1 - a)], x(K+1:end), (1 - a) * y_K);
    end
end
