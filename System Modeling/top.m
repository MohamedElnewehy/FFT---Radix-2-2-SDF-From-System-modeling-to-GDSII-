clear; clc; close all;

N = 16;
nSeeds = 100;
T = FFT_2_2_types('Test_4');   % start in double precision

SQNR_dB = zeros(1, nSeeds);
max_error_ratio = zeros(1, nSeeds);
worst_bin_idx = zeros(1, nSeeds);
all_error_ratio = zeros(nSeeds, N);

fprintf('... Starting Simulation ...\n');

for seed = 1 : nSeeds
    rng(seed);
    x_double = randn(1,N) + 1j*randn(1,N);
    x_double = x_double / max(abs(x_double));
    x = cast(x_double, 'like', T.x);
    
    if seed == 1
        buildInstrumentedMex FFT_2_2 -args {x, T}
    end
    
    % FFT ALGORITHM
    y = FFT_2_2_mex(x, T);
    
    % VERIFY RESULTS
    builtin_fft = fft(x_double);
    error_magnitude = abs(double(y) - builtin_fft);
    error_ratio_pct = 100 * error_magnitude ./ abs(builtin_fft);
    all_error_ratio(seed, :) = error_ratio_pct;
    
    [worst_err_val, worst_bin] = max(error_ratio_pct);
    max_error_ratio(seed) = worst_err_val;
    worst_bin_idx(seed) = worst_bin - 1;
    
    signal_power = sum(abs(builtin_fft).^2);
    noise_power  = sum(error_magnitude.^2);
    SQNR_dB(seed) = 10 * log10(signal_power / noise_power);
end

% --- Compute Metrics ---
mean_sqnr = mean(SQNR_dB);

% --- Print Summary to Command Window ---
fprintf('Max Error Ratio (worst seed) : %.6f %%\n', max(max_error_ratio));
fprintf('Min SQNR (worst seed)       : %.2f dB\n', min(SQNR_dB));
fprintf('Mean SQNR (across seeds)    : %.2f dB\n', mean_sqnr);

% --- Figure 1: Error Ratio ---
figure('Name', 'Error Ratio across Bins', 'Color', 'w');
h1 = plot(0:N-1, all_error_ratio', ...
    'Color', [0.6 0.8 1], ...
    'LineWidth', 1);
hold on;
h2 = plot(0:N-1, mean(all_error_ratio,1), ...
    'Color', [0.85 0.33 0.10], ...
    'LineWidth', 2.5);
hold off;
title('Error Ratio across Frequency Bins', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Bin Index', 'FontSize', 11);
ylabel('Error Ratio (%)', 'FontSize', 11);
grid on;
legend([h1(1), h2], ...
       {'Individual seeds','Mean across seeds'}, ...
       'Location','northwest');

% --- Figure 2: SQNR with Mean Display ---
figure('Name', 'SQNR across Test Seeds', 'Color', 'w');
h_sqnr = plot(1:nSeeds, SQNR_dB, 'LineWidth', 2, 'Color', '#0072BD');
hold on;
grid on;

% Dashed Mean SQNR Line
h_mean = yline(mean_sqnr, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 2.5);

% Text Annotation
text(nSeeds * 0.05, mean_sqnr + 0.8, sprintf('Mean SQNR = %.2f dB', mean_sqnr), ...
     'Color', [0.85 0.33 0.10], 'FontSize', 11, 'FontWeight', 'bold');

hold off;
title('SQNR across Test Seeds', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Seed', 'FontSize', 11);
ylabel('SQNR (dB)', 'FontSize', 11);
legend([h_sqnr, h_mean], ...
       {'SQNR per Seed', sprintf('Mean SQNR (%.2f dB)', mean_sqnr)}, ...
       'Location', 'best');

% Show Instrumentation Profile
showInstrumentationResults FFT_2_2_mex