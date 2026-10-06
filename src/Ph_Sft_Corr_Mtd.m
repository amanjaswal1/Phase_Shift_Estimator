function phi_deg = Ph_Sft_Corr_Mtd(sig1, sig2, cmd)
%PH_SFT_CORR_MTD  Original single-instance API (kept for compatibility).
%
%   phi_deg = Ph_Sft_Corr_Mtd(sig1, sig2)   % call once per sample
%   Ph_Sft_Corr_Mtd([], [], 'reset')        % clear the internal state
%
%   Same behaviour as version 1: dt = 1e-4 s, T_filter = 0.1 s, filters
%   seeded for 0..1 PWM-level signals. Because the state is persistent,
%   only ONE estimator can run per MATLAB session with this function.
%   For new code use PSE_INIT / PSE_STEP, which have no such limit and let
%   you set dt, T_filter and an optional pre-filter.
%
%   Output: phase of sig2 relative to sig1 in degrees
%           (positive = sig2 lags, negative = sig2 leads).

    persistent st

    if nargin == 3 && strcmpi(cmd, 'reset')
        st = [];
        phi_deg = 0;
        return
    end

    if isempty(st)
        init = struct('mean1', 0.5, 'mean2', 0.5, 'prod', 0.0, ...
                      'cross', 0.0, 'sq1', 0.2, 'sq2', 0.2);
        st = pse_init(1e-4, 0.1, 0, init);
    end

    [phi_deg, st] = pse_step(st, sig1, sig2);
end
