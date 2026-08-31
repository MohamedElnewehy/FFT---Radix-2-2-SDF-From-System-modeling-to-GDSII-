clc; clear; close all;

%% 1. Load Data Safely (Handling incomplete/mismatched frames)
raw_input  = load('input_samples.txt');   
raw_output = load('rtl_output.txt');
FRAME_SIZE = 16;

% حساب أقل عدد سطور مشترك وضمان أخذ الفريمات الكاملة فقط (Integers)
min_length    = min(size(raw_input, 1), size(raw_output, 1));
NUM_SEEDS     = floor(min_length / FRAME_SIZE); 
valid_samples = NUM_SEEDS * FRAME_SIZE;

% قص الزيادات أو العينات الناقصة لتطابق الفريمات الكاملة
raw_input  = raw_input(1:valid_samples, :);
raw_output = raw_output(1:valid_samples, :);

X_in  = reshape(raw_input(:, 1)  + 1i * raw_input(:, 2),  FRAME_SIZE, NUM_SEEDS);
Y_rtl = reshape(raw_output(:, 1) + 1i * raw_output(:, 2), FRAME_SIZE, NUM_SEEDS);

%% 2. Align Bit-Reversed RTL Output & Compute Built-in Reference
Y_rtl = Y_rtl(bitrevorder(1:FRAME_SIZE), :);
Y_ref = fft(X_in);

%% 3. Calculate Error & SQNR
abs_error = abs(Y_ref - Y_rtl);
P_signal  = sum(abs(Y_ref).^2, 1);
P_noise   = sum(abs_error.^2, 1);

% Avoid division by zero in case of perfect match (0 error)
P_noise(P_noise == 0) = eps; 

SQNR_dB   = 10 * log10(P_signal ./ P_noise);
mean_sqnr = mean(SQNR_dB);

%% 4. Print Summary
fprintf('--- Error Summary ---\n');
fprintf('Processed Complete Frames (Seeds): %d\n', NUM_SEEDS);
fprintf('Mean SQNR: %.2f dB\n', mean_sqnr);
fprintf('Max Absolute Error: %.4f\n', max(abs_error(:)));

%% 5. Signal Labels
% Updated to match the signals from the Verilog testbench
signal_labels = {'Impulse', 'DC Constant', 'Sine Wave', 'Cosine Wave', 'Rectangular Pulse'};

% Ensure we don't exceed the number of available labels
num_labels = min(NUM_SEEDS, length(signal_labels));
active_labels = signal_labels(1:num_labels);

% If there are more seeds than labels, auto-generate remaining labels
if NUM_SEEDS > length(signal_labels)
    for i = length(signal_labels)+1 : NUM_SEEDS
        active_labels{i} = sprintf('Signal %d', i);
    end
end

%% 6. Plot: Error and SQNR
% Figure 1: Absolute Error per Bin
figure('Color', 'w', 'Name', 'Absolute Error per Bin', 'Position', [100, 100, 800, 400]);
plot(0:15, abs_error, 'LineWidth', 1.2);
grid on;
title('Absolute Error per Bin', 'FontSize', 12);
xlabel('Bin Index', 'FontSize', 10);
ylabel('Absolute Error', 'FontSize', 10);
xlim([0, 15]);

% Figure 2: SQNR per Signal
figure('Color', 'w', 'Name', 'SQNR Overview', 'Position', [150, 150, 900, 500]);
plot(1:NUM_SEEDS, SQNR_dB, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;

% Add Average SQNR line with text
yline(mean_sqnr, '--r', sprintf(' Avg SQNR = %.2f dB', mean_sqnr), ...
      'LineWidth', 2, 'FontSize', 11, 'FontWeight', 'bold', 'LabelHorizontalAlignment', 'left');
grid on;
title('SQNR per Signal Type', 'FontSize', 12);
xlabel('Signal Type', 'FontSize', 10);
ylabel('SQNR (dB)', 'FontSize', 10);

% Dynamically apply the specific signal names to the X-axis
xlim([0.5, NUM_SEEDS + 0.5]);
xticks(1:NUM_SEEDS);
xticklabels(active_labels); 
xtickangle(30); 
hold off;

%% 7. Plot Input and Output for ALL Signals
plots_per_fig = 5; 
for i = 1:NUM_SEEDS
    % Create a new figure every 'plots_per_fig' signals
    if mod(i-1, plots_per_fig) == 0
        fig_num = floor((i-1)/plots_per_fig) + 1;
        plots_in_this_fig = min(plots_per_fig, NUM_SEEDS - (i-1));
        
        figure('Color', 'w', 'Name', sprintf('Time vs Frequency Domain (Part %d)', fig_num), ...
               'Position', [200 + fig_num*30, 100, 1000, 200 * plots_in_this_fig]);
    end
    
    row_idx = mod(i-1, plots_per_fig) + 1;
    
    % --- Left Column: Time-Domain Input Signal ---
    subplot(plots_in_this_fig, 2, 2*row_idx - 1);
    stem(0:15, real(X_in(:, i)), 'b', 'filled', 'LineWidth', 1.2); 
    hold on;
    stem(0:15, imag(X_in(:, i)), 'r--', 'LineWidth', 1.2); 
    hold off;
    
    grid on;
    title(sprintf('%s - Input Signal (Time Domain)', active_labels{i}), 'FontSize', 11);
    xlabel('Sample Index', 'FontSize', 10);
    ylabel('Amplitude', 'FontSize', 10);
    legend('Real', 'Imag', 'Location', 'best');
    xlim([0, 15]);
    
    % --- Right Column: Frequency-Domain Output Magnitude ---
    subplot(plots_in_this_fig, 2, 2*row_idx);
    stem(0:15, abs(Y_ref(:, i)), 'k', 'filled', 'LineWidth', 1.5); 
    hold on;
    stem(0:15, abs(Y_rtl(:, i)), 'rx', 'LineWidth', 1.5, 'MarkerSize', 8); 
    hold off;
    
    grid on;
    title(sprintf('%s - Output Magnitude (Frequency Domain)', active_labels{i}), 'FontSize', 11);
    xlabel('Bin Index', 'FontSize', 10);
    ylabel('Magnitude', 'FontSize', 10);
    
    if row_idx == 1
        legend('MATLAB Ref', 'RTL Output', 'Location', 'best');
    end
    xlim([0, 15]);
end