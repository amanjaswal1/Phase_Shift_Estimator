% DEMO_BASIC  Minimal real-time style usage of the phase-shift estimator.
%
%   Two 60 Hz signals, sig2 lagging sig1 by 35 degrees, processed one sample
%   at a time exactly as inside a control loop or a Simulink MATLAB Function
%   block. Prints the settled estimate.

clear;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

dt = 1e-4;                      % loop sample period [s]
T_filter = 0.1;                 % averaging time constant [s]
t = 0:dt:1;
sig1 = 0.5 + 0.4 * sin(2*pi*60*t);
sig2 = 0.5 + 0.2 * sin(2*pi*60*t - 35*pi/180);

est = pse_init(dt, T_filter);   % one independent estimator
phi = zeros(size(t));
for k = 1:numel(t)
    [phi(k), est] = pse_step(est, sig1(k), sig2(k));
end

n_cycle = round(1 / (60 * dt));             % average the last cycle (ripple)
fprintf('true phase = 35.00 deg, estimate after 1 s = %.2f deg\n', mean(phi(end - n_cycle + 1:end)));
