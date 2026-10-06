function phi_deg = pse_run(sig1, sig2, dt, T_filter, prefilter_hz, warm_start)
%PSE_RUN  Run the phase-shift estimator over two whole signal vectors.
%
%   phi_deg = pse_run(sig1, sig2, dt, T_filter)
%   phi_deg = pse_run(sig1, sig2, dt, T_filter, prefilter_hz)
%   phi_deg = pse_run(sig1, sig2, dt, T_filter, prefilter_hz, warm_start)
%
%   Convenience wrapper for offline analysis: it feeds the samples one by
%   one through PSE_STEP (exactly what a real-time loop would do) and
%   returns the estimate at every sample.
%
%   See also PSE_INIT, PSE_STEP, PSE_BATCH.

    if nargin < 5
        prefilter_hz = 0;
    end
    if nargin < 6
        warm_start = true;
    end
    if numel(sig1) ~= numel(sig2)
        error('pse_run:size', 'sig1 and sig2 must have the same length.');
    end

    st = pse_init(dt, T_filter, prefilter_hz, [], warm_start);
    phi_deg = zeros(size(sig1));
    for k = 1:numel(sig1)
        [phi_deg(k), st] = pse_step(st, sig1(k), sig2(k));
    end
end
