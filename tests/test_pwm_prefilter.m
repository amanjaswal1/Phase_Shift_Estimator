function test_pwm_prefilter()
% Two-level sinusoidal PWM (same 2 kHz carrier for both channels, 50 Hz).
%  - Without a pre-filter the estimate is strongly biased (documents the
%    limitation stated in the README).
%  - With an identical pre-filter at ~2x the fundamental (100 Hz) on both
%    inputs the settled error is small.

    f = 50; fc = 2000; dt = 1e-5; T = 1.0; t = 0:dt:T - dt; w = 2*pi*f;
    carrier = abs(2*mod(t*fc, 1) - 1);             % triangle, 0..1
    m = 0.8; phi_true = 60;
    s1 = double(0.5 + 0.5*m*sin(w*t)                     > carrier);
    s2 = double(0.5 + 0.5*m*sin(w*t - phi_true*pi/180)   > carrier);
    n_avg = round(0.2 / dt);

    raw = pse_batch(s1, s2, dt, 0.1);
    err_raw = mean(raw(end - n_avg + 1:end)) - phi_true;
    assert(abs(err_raw) > 10, sprintf('expected a large raw-PWM bias, got %.2f deg', err_raw));

    filt = pse_run(s1, s2, dt, 0.1, 100);          % loop version, as in real time
    err_f = mean(filt(end - n_avg + 1:end)) - phi_true;
    assert(abs(err_f) < 0.3, sprintf('pre-filtered PWM error %.3f deg', err_f));
end
