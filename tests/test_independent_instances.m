function test_independent_instances()
% Two estimators updated in the same loop must not interfere
% (the v1 persistent-variable version could only run one at a time).

    f = 50; dt = 1e-4; t = 0:dt:1 - dt; w = 2*pi*f;
    a1 = sin(w*t);  a2 = sin(w*t - 20*pi/180);
    b1 = cos(w*t);  b2 = cos(w*t + 70*pi/180);

    sa = pse_init(dt, 0.1);  sb = pse_init(dt, 0.1);
    pa = zeros(size(t));     pb = zeros(size(t));
    for k = 1:numel(t)
        [pa(k), sa] = pse_step(sa, a1(k), a2(k));
        [pb(k), sb] = pse_step(sb, b1(k), b2(k));
    end
    assert(max(abs(pa - pse_run(a1, a2, dt, 0.1))) == 0, 'instance A changed');
    assert(max(abs(pb - pse_run(b1, b2, dt, 0.1))) == 0, 'instance B changed');
    n_avg = round(0.2 / dt);                       % ripple: average last 0.2 s
    assert(abs(mean(pa(end - n_avg + 1:end)) - 20) < 0.1, 'instance A settled value');
    assert(abs(mean(pb(end - n_avg + 1:end)) + 70) < 0.1, 'instance B settled value');
end
