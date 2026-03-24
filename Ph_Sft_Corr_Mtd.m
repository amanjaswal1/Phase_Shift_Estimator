% Author: Aman Jaswal
% Description: Real-time phase shift estimator using correlation method.
%              Handles PWM signals and DC offsets via low-pass filtering.

function phi_deg = Ph_Sft_Corr_Mtd(sig1, sig2)

% --- Tuning Parameters ---
dt       = 1e-4;   % Sample period (s)
T_filter = 0.1;    % Low-pass filter time constant (s)
alpha    = dt / (T_filter + dt);  % IIR filter coefficient

% --- Persistent State ---
persistent avg_s1 avg_s2
persistent avg_prod avg_cross
persistent avg_sq1 avg_sq2
persistent prev_ac1
persistent initialized

if isempty(initialized)
    avg_s1   = 0.5;
    avg_s2   = 0.5;
    avg_prod = 0.0;
    avg_cross = 0.0;
    avg_sq1  = 0.2;
    avg_sq2  = 0.2;
    prev_ac1 = 0.0;
    initialized = true;
end

% --- DC Removal (low-pass estimate of mean) ---
avg_s1 = (1 - alpha) * avg_s1 + alpha * sig1;
avg_s2 = (1 - alpha) * avg_s2 + alpha * sig2;

ac1 = sig1 - avg_s1;
ac2 = sig2 - avg_s2;

% --- Correlation Products ---
product  = ac1 * ac2;
avg_prod = (1 - alpha) * avg_prod + alpha * product;

% --- Derivative of ac1 (used for lead/lag sign detection) ---
% Note: scaled by sample period, not true dt — valid for fixed sample rate
deriv_ac1 = (ac1 - prev_ac1) / dt;
cross_prod = deriv_ac1 * ac2;
avg_cross  = (1 - alpha) * avg_cross + alpha * cross_prod;

% --- RMS Estimation ---
avg_sq1 = (1 - alpha) * avg_sq1 + alpha * (ac1 * ac1);
avg_sq2 = (1 - alpha) * avg_sq2 + alpha * (ac2 * ac2);

rms1 = sqrt(avg_sq1);
rms2 = sqrt(avg_sq2);

% --- Phase Calculation ---
phi_deg = 0.0;

if (rms1 > 0.001) && (rms2 > 0.001)
    cos_phi = avg_prod / (rms1 * rms2);

    % Clamp to valid acos range
    cos_phi = max(-1, min(1, cos_phi));

    phi_rad = acos(cos_phi);

    % Sign: positive = sig2 lags sig1, negative = sig2 leads sig1
    if avg_cross > 0
        phi_deg = -(phi_rad * (180 / pi));
    else
        phi_deg = (phi_rad * (180 / pi));
    end
end

prev_ac1 = ac1;

end
