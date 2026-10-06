function test_batch_matches_loop()
% The vectorised PSE_BATCH must match the sample-by-sample PSE_RUN, with and
% without the pre-filter and warm start, including the lead/lag sign at
% every sample.

    dt = 1e-4; t = 0:dt:0.6 - dt; w = 2*pi*50;
    s1 = 1.0 + sin(w*t) + 0.05*sin(5*w*t);
    s2 = 0.2 + 0.7*sin(w*t + 0.9);

    for warm = [true, false]
        for pre = [0, 300]
            d = pse_batch(s1, s2, dt, 0.05, pre, warm) - pse_run(s1, s2, dt, 0.05, pre, warm);
            assert(max(abs(d)) < 1e-6, sprintf('warm=%d prefilter=%g: max diff %.3g deg', ...
                   warm, pre, max(abs(d))));
        end
    end
end
