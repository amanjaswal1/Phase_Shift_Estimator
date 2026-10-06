function [phi_deg, st] = pse_step(st, sig1, sig2)
%PSE_STEP  Advance a phase-shift estimator by one sample.
%
%   [phi_deg, st] = pse_step(st, sig1, sig2)
%
%   sig1, sig2  Current samples of the reference and the measured signal.
%   phi_deg     Estimated phase of sig2 relative to sig1 [deg].
%               Positive = sig2 LAGS sig1, negative = sig2 LEADS sig1.
%
%   Method (correlation method, all averages are first-order IIR filters,
%   i.e. exponentially weighted moving averages):
%     1. DC removal:      ac_i = sig_i - EWMA(sig_i)
%     2. Correlation:     cos(phi) = EWMA(ac1*ac2) / (rms1 * rms2)
%     3. Magnitude:       |phi| = acos(cos(phi))
%     4. Sign:            sign of EWMA(d(ac1)/dt * ac2) decides lead/lag
%
%   See also PSE_INIT, PSE_RUN, PSE_BATCH.

    st.k = st.k + 1;
    if st.warm_start
        a = max(st.alpha, 1 / st.k);       % cumulative mean, then EWMA
    else
        a = st.alpha;
    end

    % --- Optional identical pre-filter on both channels -------------------
    if st.alpha_pre > 0
        ap = st.alpha_pre;
        if ~st.seeded
            st.pre(1, :) = sig1;
            st.pre(2, :) = sig2;
        end
        st.pre(1, 1) = st.pre(1, 1) + ap * (sig1          - st.pre(1, 1));
        st.pre(1, 2) = st.pre(1, 2) + ap * (st.pre(1, 1)  - st.pre(1, 2));
        st.pre(2, 1) = st.pre(2, 1) + ap * (sig2          - st.pre(2, 1));
        st.pre(2, 2) = st.pre(2, 2) + ap * (st.pre(2, 1)  - st.pre(2, 2));
        sig1 = st.pre(1, 2);
        sig2 = st.pre(2, 2);
    end

    % --- Seed the means from the first sample -----------------------------
    if ~st.seeded
        st.mean1    = sig1;
        st.mean2    = sig2;
        st.prev_ac1 = 0;
        st.seeded   = true;
    end

    % --- 1. DC removal (low-pass estimate of the mean) ---------------------
    st.mean1 = (1 - a) * st.mean1 + a * sig1;
    st.mean2 = (1 - a) * st.mean2 + a * sig2;
    ac1 = sig1 - st.mean1;
    ac2 = sig2 - st.mean2;

    % --- 2. Correlation products -------------------------------------------
    st.prod = (1 - a) * st.prod + a * (ac1 * ac2);

    % Derivative of ac1 for the lead/lag decision (fixed sample rate)
    d_ac1    = (ac1 - st.prev_ac1) / st.dt;
    st.cross = (1 - a) * st.cross + a * (d_ac1 * ac2);

    % --- RMS estimates ------------------------------------------------------
    st.sq1 = (1 - a) * st.sq1 + a * (ac1 * ac1);
    st.sq2 = (1 - a) * st.sq2 + a * (ac2 * ac2);
    st.rms1 = sqrt(st.sq1);
    st.rms2 = sqrt(st.sq2);

    % --- 3./4. Phase magnitude and sign ------------------------------------
    phi_deg = 0;
    if st.rms1 > st.rms_min && st.rms2 > st.rms_min
        c = st.prod / (st.rms1 * st.rms2);
        c = max(-1, min(1, c));            % clamp to the valid acos range
        st.cos_phi = c;
        phi = acos(c) * 180 / pi;
        if st.cross > 0
            phi_deg = -phi;                % sig2 leads sig1
        else
            phi_deg = phi;                 % sig2 lags sig1
        end
    end

    st.prev_ac1 = ac1;
end
