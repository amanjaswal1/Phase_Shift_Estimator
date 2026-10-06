% MAKE_FIGURES  Regenerate every figure and number quoted in README.md.
%
%   Run from anywhere:   run('examples/make_figures.m')
%   Output:              results/figures/*.png  +  numbers printed below
%
%   Works in MATLAB (R2019b+) and GNU Octave (8+); no toolboxes needed.
%   Uses PSE_BATCH (vectorised); tests/test_batch_matches_loop.m checks that
%   it gives the same output as the real-time loop PSE_STEP.

clear; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
out_dir = fullfile(here, '..', 'results', 'figures');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
rng(42);

f = 50; w = 2*pi*f;
pwm = @(ref, t) double(ref > abs(2*mod(t*2000, 1) - 1));   % 2 kHz carrier

%% Figure 1 - tracking a phase step in noisy, offset signals ---------------
dt = 1e-4; T = 3; t = 0:dt:T - dt;
phi_true = 30 * ones(size(t));
phi_true(t >= 1.5) = -60;                         % step: lag 30 -> lead 60 deg
c1 = 1.0 + 1.0 * sin(w*t);
c2 = 0.3 + 0.6 * sin(w*t - phi_true*pi/180);
s1 = c1 + 0.05 * randn(size(t));
s2 = c2 + 0.05 * randn(size(t));

T_list = [0.02, 0.1];
est = zeros(numel(T_list), numel(t));
for i = 1:numel(T_list)
    est(i, :) = pse_batch(s1, s2, dt, T_list(i));
end

fig = figure('Visible', 'off', 'Color', 'w');
subplot(2, 1, 1);
idx = t >= 1.46 & t <= 1.54;
plot(t(idx), s1(idx), 'Color', palette('blue'), 'LineWidth', 1.2); hold on;
plot(t(idx), s2(idx), 'Color', palette('orange'), 'LineWidth', 1.2);
plot([1.5 1.5], [-1 2.5], '--', 'Color', palette('grey'));
grid on; xlim([1.46 1.54]); ylim([-1 2.5]);
ylabel('signal');
legend({'sig1 (offset 1.0, amp 1.0)', 'sig2 (offset 0.3, amp 0.6)'}, 'Location', 'northwest');
title('(a) Inputs around the phase step at t = 1.5 s (white noise, \sigma = 0.05)');

subplot(2, 1, 2);
plot(t, phi_true, 'k--', 'LineWidth', 1.5); hold on;
plot(t, est(1, :), 'Color', palette('orange'), 'LineWidth', 1.0);
plot(t, est(2, :), 'Color', palette('blue'), 'LineWidth', 1.6);
grid on; ylim([-90 60]);
xlabel('time [s]'); ylabel('\phi [deg]  (+ = sig2 lags)');
legend({'true phase', sprintf('estimate, T_{filter} = %.2f s', T_list(1)), ...
        sprintf('estimate, T_{filter} = %.2f s', T_list(2))}, 'Location', 'southwest');
title('(b) Estimate vs truth: a shorter filter is faster but noisier');
save_png(fig, fullfile(out_dir, 'fig1_tracking.png'), 1000, 750);

fprintf('\nFigure 1 numbers (phase step 30 -> -60 deg at t = 1.5 s):\n');
for i = 1:numel(T_list)
    clean = pse_batch(c1, c2, dt, T_list(i));     % same signals without noise
    n_cyc = round(1 / (f * dt));                   % average over one cycle
    clean = filter(ones(1, n_cyc) / n_cyc, 1, clean);
    last_out = find(t >= 1.5 & abs(clean - phi_true) > 1, 1, 'last');
    win = t >= 2.5;                                % steady window
    fprintf('  T_filter = %.2f s : cycle-average within 1 deg %.3f s after the step (noise-free); ', ...
            T_list(i), t(last_out) - 1.5 + dt);
    fprintf('steady std with noise = %.2f deg\n', std(est(i, win)));
end

%% Figure 2 - accuracy vs true phase for different waveforms ----------------
phis = -165:15:165;
err = zeros(4, numel(phis));
for i = 1:numel(phis)
    ph = phis(i) * pi / 180;

    % (1) sinusoids with different offsets/amplitudes
    dt = 1e-4; t = 0:dt:1.5 - dt; n = round(0.3 / dt);
    e = pse_batch(2 + sin(w*t), -1 + 0.5*sin(w*t - ph), dt, 0.1);
    err(1, i) = mean(e(end - n + 1:end)) - phis(i);

    % (2) 50 % duty square waves (0/1)
    e = pse_batch(double(sin(w*t) >= 0), double(sin(w*t - ph) >= 0), dt, 0.1);
    err(2, i) = mean(e(end - n + 1:end)) - phis(i);

    % (3)/(4) two-level sinusoidal PWM, 2 kHz carrier, m = 0.8
    dt = 1e-5; t = 0:dt:1.5 - dt; n = round(0.3 / dt);
    p1 = pwm(0.5 + 0.4*sin(w*t), t);
    p2 = pwm(0.5 + 0.4*sin(w*t - ph), t);
    e = pse_batch(p1, p2, dt, 0.1);
    err(3, i) = mean(e(end - n + 1:end)) - phis(i);
    e = pse_batch(p1, p2, dt, 0.1, 100);
    err(4, i) = mean(e(end - n + 1:end)) - phis(i);
end
wrap = @(x) mod(x + 180, 360) - 180;               % express errors in [-180, 180)

% Theory for square waves: correlation coefficient is 1 - 2|phi|/pi
phi_fine = linspace(-179, 179, 721);
sq_theory = sign(phi_fine) .* acos(1 - 2*abs(phi_fine)/180) * 180/pi - phi_fine;

fig = figure('Visible', 'off', 'Color', 'w');
subplot(2, 1, 1);
plot(phi_fine, sq_theory, '-', 'Color', [0.78 0.78 0.78], 'LineWidth', 5); hold on;
plot(phis, err(2, :), 's', 'Color', palette('purple'), 'MarkerSize', 7, 'LineWidth', 1.4);
plot(phis, wrap(err(3, :)), 'o-', 'Color', palette('red'), 'LineWidth', 1.4, 'MarkerSize', 6);
plot(phis, err(1, :), 'o-', 'Color', palette('blue'), 'LineWidth', 1.6, 'MarkerSize', 5, ...
     'MarkerFaceColor', palette('blue'));
grid on; xlim([-180 180]); ylim([-180 180]);
set(gca, 'XTick', -180:30:180, 'YTick', -180:60:180);
xlabel('true phase shift [deg]'); ylabel('estimate - truth [deg]');
legend({'square wave: theory', 'square wave: simulated', 'sinusoidal PWM, raw', ...
        'sinusoids'}, 'Location', 'southoutside', 'NumColumns', 2);
title('(a) Raw inputs: exact for sinusoids, biased for harmonic-rich signals');

subplot(2, 1, 2);
plot(phis, err(1, :), 'o-', 'Color', palette('blue'), 'LineWidth', 1.6, 'MarkerSize', 5, ...
     'MarkerFaceColor', palette('blue')); hold on;
plot(phis, err(4, :), 'd-', 'Color', palette('green'), 'LineWidth', 1.6, 'MarkerSize', 6, ...
     'MarkerFaceColor', palette('green'));
grid on; xlim([-180 180]); ylim([-0.5 0.5]);
set(gca, 'XTick', -180:30:180);
xlabel('true phase shift [deg]'); ylabel('estimate - truth [deg]');
legend({'sinusoids', 'sinusoidal PWM + identical 100 Hz pre-filter'}, 'Location', 'southoutside', 'NumColumns', 2);
title('(b) Zoom: pre-filtered PWM is within 0.15 deg');
save_png(fig, fullfile(out_dir, 'fig2_accuracy_vs_phase.png'), 1000, 900);

labels = {'sinusoids', 'square waves', 'sinusoidal PWM (raw)', 'sinusoidal PWM + 100 Hz pre-filter'};
fprintf('\nFigure 2 numbers (max |error| over -165..165 deg, settled):\n');
for k = 1:4
    fprintf('  %-36s %7.2f deg\n', labels{k}, max(abs(wrap(err(k, :)))));
end
fprintf('  raw PWM reads a true +60 deg as %+.1f deg and +90 deg as %+.1f deg\n', ...
        60 + err(3, phis == 60), 90 + err(3, phis == 90));
fprintf('  square wave at 45 deg reads %.1f deg (theory %.1f deg)\n', ...
        45 + err(2, phis == 45), acos(0.5)*180/pi);

%% Figure 3 - start-up transient: warm start vs v1-style cold start ---------
dt = 1e-5; t = 0:dt:0.8 - dt;
p1 = pwm(0.5 + 0.4*sin(w*t), t);
p2 = pwm(0.5 + 0.4*sin(w*t - pi/2), t);            % true phase = +90 deg
warm = pse_batch(p1, p2, dt, 0.1, 100, true);
cold = pse_batch(p1, p2, dt, 0.1, 100, false);

fig = figure('Visible', 'off', 'Color', 'w');
plot(t, 90 * ones(size(t)), 'k--', 'LineWidth', 1.5); hold on;
plot(t, cold, 'Color', palette('orange'), 'LineWidth', 1.4);
plot(t, warm, 'Color', palette('blue'), 'LineWidth', 1.6);
grid on; ylim([0 120]); xlim([0 0.8]);
xlabel('time [s]'); ylabel('\phi [deg]');
legend({'true phase (90 deg)', 'cold start (filters seeded with first sample, as in v1)', ...
        'warm start (cumulative mean for the first T_{filter}, then EWMA)'}, ...
       'Location', 'southeast');
title('Start-up from PWM inputs (T_{filter} = 0.1 s, 100 Hz pre-filter)');
save_png(fig, fullfile(out_dir, 'fig3_warm_start.png'), 1000, 520);

fprintf('\nFigure 3 numbers (|error| averaged over the cycle ending at t):\n');
n = round(0.02 / dt);
for tt = [0.2 0.3 0.5]
    k = round(tt / dt);
    fprintf('  t = %.1f s : warm %.2f deg, cold %.2f deg\n', tt, ...
            abs(mean(warm(k - n + 1:k)) - 90), abs(mean(cold(k - n + 1:k)) - 90));
end
fprintf('\n');

%% Pre-filter cut-off sweep (numbers quoted in the Limitations section) -----
fprintf('Pre-filter cut-off sweep (50 Hz PWM, settled max |error| over -165..165 deg):\n');
dt = 1e-5; t = 0:dt:1.5 - dt; n = round(0.3 / dt);
fp_list = [100 150 250 500];
for m = [0.8 0.4]
    fprintf('  m = %.1f :', m);
    for fp = fp_list
        mx = 0;
        for ph = (-165:15:165) * pi / 180
            e = pse_batch(pwm(0.5 + 0.5*m*sin(w*t), t), pwm(0.5 + 0.5*m*sin(w*t - ph), t), dt, 0.1, fp);
            mx = max(mx, abs(mean(e(end - n + 1:end)) - ph*180/pi));
        end
        fprintf('  %d Hz -> %.2f deg', fp, mx);
    end
    fprintf('\n');
end
fprintf('\n');
