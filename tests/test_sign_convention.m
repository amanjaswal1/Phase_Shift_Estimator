function test_sign_convention()
% sig2 lagging sig1 must give a positive angle; leading must give negative.

    f = 60; dt = 1e-4; t = 0:dt:1 - dt; w = 2*pi*f;
    lag  = pse_run(sin(w*t), sin(w*t - pi/6), dt, 0.1);
    lead = pse_run(sin(w*t), sin(w*t + pi/6), dt, 0.1);
    assert(lag(end)  > 0, 'lagging signal should give phi > 0');
    assert(lead(end) < 0, 'leading signal should give phi < 0');
end
