clear; clc; close all;
N = 16;

% Types table
T = FFT_2_2_types('double');

% Example input - defines the data type/size for -args
x_double = randn(1, N) + 1i * randn(1, N);
x = cast(x_double, 'like', T.x);

% Build the instrumented MEX file for FFT_2_2, matching the slide's syntax:
% buildInstrumentedMex function_name -args {functionInputs}
buildInstrumentedMex FFT_2_2 -args {x, T}