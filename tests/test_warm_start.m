function test_warm_start()
% Warm start (cumulative mean for the first ~T_filter) must remove most of
% the start-up transient: compare the estimate at t = 0.3 s (3 T_filter) for
% pre-filtered PWM, which starts far from its mean (first sample = 0 or 1).

    f = 50; fc = 2000; dt = 1e-5; t = 0:dt:0.3 - dt; w = 2*pi*f;
    carrier = abs(2*mod(t*fc, 1) - 1);
    phi_true = 90;
    s1 = double(0.5 + 0.4*sin(w*t)                   > carrier);
    s2 = double(0.5 + 0.4*sin(w*t - phi_true*pi/180) > carrier);
    n = round(0.02 / dt);                          % last cycle

    warm = pse_batch(s1, s2, dt, 0.1, 100, true);
    cold = pse_batch(s1, s2, dt, 0.1, 100, false);
    e_warm = abs(mean(warm(end - n + 1:end)) - phi_true);
    e_cold = abs(mean(cold(end - n + 1:end)) - phi_true);
    assert(e_warm < 1, sprintf('warm-start error at 0.3 s = %.2f deg', e_warm));
    assert(e_cold > 5 * e_warm, sprintf('expected cold start to be much worse (%.2f vs %.2f)', e_cold, e_warm));
end
