function test_sine_accuracy()
% Pure sinusoids with different amplitudes and DC offsets: the settled
% estimate must be within 0.1 deg of the true phase shift.

    f = 50; dt = 1e-4; T = 1.5; t = 0:dt:T - dt; w = 2*pi*f;
    n_avg = round(0.2 / dt);                       % average the last 0.2 s
    for phi_true = [-150 -90 -45 -10 10 45 90 150]
        ph = phi_true * pi / 180;
        s1 =  2.0 + 1.0 * sin(w*t);
        s2 = -1.0 + 0.5 * sin(w*t - ph);
        est = pse_run(s1, s2, dt, 0.1);
        err = mean(est(end - n_avg + 1:end)) - phi_true;
        assert(abs(err) < 0.1, sprintf('phi=%g: error %.3f deg', phi_true, err));
    end
end
