clc; clear; close all;

%% 1. Load Data
raw_input  = load('input_random_samples.txt');   
raw_output = load('rtl_random_output.txt');

FRAME_SIZE = 16;
NUM_SEEDS  = size(raw_input, 1) / FRAME_SIZE; 

X_in  = reshape(raw_input(:, 1)  + 1i * raw_input(:, 2),  FRAME_SIZE, NUM_SEEDS);
Y_rtl = reshape(raw_output(:, 1) + 1i * raw_output(:, 2), FRAME_SIZE, NUM_SEEDS);

%% 2. Align Bit-Reversed RTL Output & Compute MATLAB Reference
Y_rtl = Y_rtl(bitrevorder(1:FRAME_SIZE), :);
Y_ref = fft(X_in);

%% 3. Calculate Error & SQNR
abs_error = abs(Y_ref - Y_rtl);
P_signal  = sum(abs(Y_ref).^2, 1);
P_noise   = sum(abs_error.^2, 1);
SQNR_dB   = 10 * log10(P_signal ./ P_noise);
mean_sqnr = mean(SQNR_dB);

%% 4. Print Summary
fprintf('Mean SQNR: %.2f dB\n', mean_sqnr);
fprintf('Max Absolute Error: %.4f\n', max(abs_error(:)));

%% 5. Simple & Clean Plots
% Figure 1: Absolute Error per Bin
figure('Color', 'w');
plot(0:15, abs_error, 'LineWidth', 1.2);
grid on;
title('Absolute Error per Bin', 'FontSize', 12);
xlabel('Bin Index', 'FontSize', 10);
ylabel('Absolute Error', 'FontSize', 10);
xlim([0, 15]);

% Figure 2: SQNR per Seed with Average Displayed
figure('Color', 'w');
plot(1:NUM_SEEDS, SQNR_dB, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
% Add Average SQNR line with text on the plot
yline(mean_sqnr, '--r', sprintf(' Avg SQNR = %.2f dB', mean_sqnr), ...
      'LineWidth', 2, 'FontSize', 11, 'FontWeight', 'bold', 'LabelHorizontalAlignment', 'left');
grid on;
title('SQNR per Seed', 'FontSize', 12);
xlabel('Seed Index', 'FontSize', 10);
ylabel('SQNR (dB)', 'FontSize', 10);
xlim([0.5, NUM_SEEDS + 0.5]);
hold off;

%% 6. Plot First 5 Signals (Exact Image Style Using Stem)
figure('Color', 'w', 'Position', [50, 50, 1200, 900]); 
num_signals_to_plot = min(5, NUM_SEEDS); 

for i = 1:num_signals_to_plot
    % -----------------------------------------------------------
    % Left Column: Input Signal (Time Domain)
    % -----------------------------------------------------------
    subplot(num_signals_to_plot, 2, 2*i - 1);
    
    % Real: Solid blue line, filled blue circles
    stem(0:15, real(X_in(:, i)), '-bo', 'MarkerFaceColor', 'b', 'LineWidth', 1, 'DisplayName', 'Real'); 
    hold on;
    % Imag: Dashed red line, open red circles
    stem(0:15, imag(X_in(:, i)), '--ro', 'MarkerFaceColor', 'none', 'LineWidth', 1, 'DisplayName', 'Imag');
    
    grid on;
    title(sprintf('Signal %d - Input Signal (Time Domain)', i), 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Amplitude', 'FontSize', 9);
    xlabel('Sample Index', 'FontSize', 9);
    xlim([-0.5, 15.5]); % To give margins similar to the image
    legend('Location', 'best');
    hold off;
    
    % -----------------------------------------------------------
    % Right Column: Output Magnitude (Frequency Domain)
    % -----------------------------------------------------------
    subplot(num_signals_to_plot, 2, 2*i);
    
    % Calculate magnitudes
    mag_rtl = abs(Y_rtl(:, i));
    mag_ref = abs(Y_ref(:, i));
    
    % MATLAB Ref: Solid black line, filled black circles
    stem(0:15, mag_ref, '-ko', 'MarkerFaceColor', 'k', 'LineWidth', 1, 'DisplayName', 'MATLAB Ref'); 
    hold on;
    % RTL Output: Solid red line, red 'x' markers
    stem(0:15, mag_rtl, '-rx', 'MarkerSize', 8, 'LineWidth', 1, 'DisplayName', 'RTL Output');
    
    grid on;
    title(sprintf('Signal %d - Output Magnitude (Frequency Domain)', i), 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Magnitude', 'FontSize', 9);
    xlabel('Bin Index', 'FontSize', 9);
    xlim([-0.5, 15.5]);
    legend('Location', 'best');
    hold off;
end