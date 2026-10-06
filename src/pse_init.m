function st = pse_init(dt, T_filter, prefilter_hz, init, warm_start)
%PSE_INIT  Create the state of one phase-shift estimator.
%
%   st = pse_init(dt, T_filter)
%   st = pse_init(dt, T_filter, prefilter_hz)
%   st = pse_init(dt, T_filter, prefilter_hz, init, warm_start)
%
%   dt            Sample period of the calling loop [s].
%   T_filter      Time constant of the averaging low-pass filters [s].
%                 Larger = smoother but slower to respond.
%   prefilter_hz  Optional cut-off [Hz] of an identical 2nd-order low-pass
%                 applied to BOTH inputs before correlation. Use it for PWM
%                 or other harmonic-rich signals. 0 or [] = off (default).
%   init          Optional struct of initial filter values (fields mean1,
%                 mean2, prod, cross, sq1, sq2). [] = start from the data.
%   warm_start    true (default): during the first ~T_filter the averages
%                 are plain cumulative means (weight 1/k), then switch to the
%                 exponential weight. This removes the start-up transient
%                 caused by seeding the filters with one sample. Ignored
%                 (forced false) when INIT is given, to reproduce v1.
%
%   Each call returns an independent struct, so any number of estimators can
%   run side by side (unlike the original persistent-variable version).
%
%   See also PSE_STEP, PSE_RUN, PSE_BATCH.

    if nargin < 3 || isempty(prefilter_hz)
        prefilter_hz = 0;
    end
    if nargin < 4
        init = [];
    end
    if nargin < 5 || isempty(warm_start)
        warm_start = isempty(init);
    end
    if ~(isscalar(dt) && dt > 0)
        error('pse_init:dt', 'dt must be a positive scalar.');
    end
    if ~(isscalar(T_filter) && T_filter > 0)
        error('pse_init:T_filter', 'T_filter must be a positive scalar.');
    end

    st.dt       = dt;
    st.T_filter = T_filter;
    st.alpha    = dt / (T_filter + dt);   % first-order IIR (EWMA) weight
    st.rms_min  = 1e-3;                   % below this the output is held at 0
    st.warm_start = logical(warm_start) && isempty(init);
    st.k        = 0;                      % samples processed so far

    % Optional identical pre-filter (two cascaded first-order sections).
    st.prefilter_hz = prefilter_hz;
    if prefilter_hz > 0
        tau = 1 / (2*pi*prefilter_hz);
        st.alpha_pre = dt / (tau + dt);
    else
        st.alpha_pre = 0;
    end
    st.pre = zeros(2, 2);                 % [stage1 stage2] for each channel

    % Running averages
    if isempty(init)
        st.seeded = false;
        st.mean1 = 0;  st.mean2 = 0;
        st.prod  = 0;  st.cross = 0;
        st.sq1   = 0;  st.sq2   = 0;
    else
        st.seeded = true;
        st.mean1 = init.mean1;  st.mean2 = init.mean2;
        st.prod  = init.prod;   st.cross = init.cross;
        st.sq1   = init.sq1;    st.sq2   = init.sq2;
    end
    st.prev_ac1 = 0;

    % Diagnostics from the most recent step
    st.cos_phi = NaN;
    st.rms1    = 0;
    st.rms2    = 0;
end
