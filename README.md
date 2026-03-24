# Phase Shift Estimator for MATLAB

A real time, sample-by-sample phase shift estimator for two signals using the **correlation method**.
Designed to work reliably with:
- PWM (non-sinusoidal) signals
- Signals with DC offsets
- Embedded / fixed sample-rate environments
---
## How It Works
The function estimates the phase difference between `sig1` and `sig2` using three steps:
1. **DC Removal** - A first-order IIR low-pass filter estimates and subtracts the mean of each signal, leaving behind the AC component.
2. **Normalized Correlation** - The dot product of the AC components, divided by the product of their rms values, gives `cos(φ)`. Taking `acos` yields the phase magnitude.
3. **Sign Detection** - The sign of the cross-correlation between the derivative of `sig1` and `sig2` determines whether `sig2` leads or lags `sig1`.
---

## Usage

```matlab
% Call once per sample in a control loop or simulation
phi_deg = Ph_Sft_Corr_Mtd(sig1_sample, sig2_sample);
```

| Parameter | Description |
|-----------|-------------|
| `sig1`    | Current sample of signal 1 (reference) |
| `sig2`    | Current sample of signal 2 |
| `phi_deg` | Estimated phase shift in degrees (+ve = lag, −ve = lead) |

---

## Tuning

Inside the function, two parameters control filter behaviour:

| Parameter  | Default | Effect |
|------------|---------|--------|
| `dt`       | `1e-4` s | Sample period — must match your loop rate |
| `T_filter` | `0.1` s  | Low-pass time constant — increase to smooth more, decrease to respond faster |

---

## Limitations

- Assumes a **fixed sample rate** equal to `1/dt`
- Sign detection via derivative is most reliable when signal frequency is well above DC (i.e., `f >> 1/T_filter`)
- Not suitable for multi-frequency or noisy signals without additional pre-filtering

---

## Author

Aman Jaswal
