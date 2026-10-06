function test_input_checks()
% Bad arguments must raise clear errors; constant inputs must return 0.

    threw = false;
    try, pse_init(-1, 0.1); catch, threw = true; end
    assert(threw, 'negative dt should error');

    threw = false;
    try, pse_run(1:3, 1:4, 1e-4, 0.1); catch, threw = true; end
    assert(threw, 'length mismatch should error');

    est = pse_run(ones(1, 1000), 2*ones(1, 1000), 1e-4, 0.1);
    assert(all(est == 0), 'DC-only inputs should give 0 (rms below threshold)');
end
