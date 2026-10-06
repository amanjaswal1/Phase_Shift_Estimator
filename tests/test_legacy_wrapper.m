function test_legacy_wrapper()
% The kept v1 function Ph_Sft_Corr_Mtd must reproduce the published v1
% algorithm sample for sample (refactor safety check).

    dt = 1e-4; t = 0:dt:0.5 - dt; w = 2*pi*50;
    s1 = 0.5 + 0.4*sin(w*t);
    s2 = 0.5 + 0.3*sin(w*t - 0.7) + 0.01*cos(7*w*t);

    clear legacy_v1_reference
    Ph_Sft_Corr_Mtd([], [], 'reset');
    d = zeros(size(t));
    for k = 1:numel(t)
        d(k) = Ph_Sft_Corr_Mtd(s1(k), s2(k)) - legacy_v1_reference(s1(k), s2(k));
    end
    assert(max(abs(d)) < 1e-12, sprintf('max difference %.3g deg', max(abs(d))));
end
