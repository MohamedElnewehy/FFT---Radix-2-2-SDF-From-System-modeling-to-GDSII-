function y = FFT_2_2(x, T) %#codegen
% x : Input signal vector, 16 complex samples
% T : Types table struct (from FFT_2_2_types)
% y : Output signal vector, 16 complex samples (bit-reversed FFT, reordered)

N = 16;

% shift registers - cast to type-table format, complex
SR8 = cast(complex(zeros(1, 8)), 'like', T.sr8_out);
SR4 = cast(complex(zeros(1, 4)), 'like', T.sr4_out);
SR2 = cast(complex(zeros(1, 2)), 'like', T.sr2_out);
SR1 = cast(complex(zeros(1, 1)), 'like', T.sr1_out);

out_fft_raw = cast(complex(zeros(1, N)), 'like', T.y);
out_idx = 1;

for clk = 0 : 31

    if clk < N
        xin_serial = x(clk + 1);
    else
        xin_serial = cast(complex(0), 'like', T.x);
    end

    cnt = mod(clk, 16);

    b3 = cast(bitget(cnt, 4), 'like', T.b3);
    b2 = cast(bitget(cnt, 3), 'like', T.b2);
    b1 = cast(bitget(cnt, 2), 'like', T.b1);
    b0 = cast(bitget(cnt, 1), 'like', T.b0);

    sr8_out = SR8(end);
    sr4_out = SR4(end);
    sr2_out = SR2(end);
    sr1_out = SR1(end);

    % STAGE 1

    % BFI
    if b3 == 0
        bf1_out = cast(sr8_out, 'like', T.bf1_out);
        sr8_in  = cast(xin_serial, 'like', T.sr8_in);
    else
        bf1_out = cast(sr8_out + xin_serial, 'like', T.bf1_out);
        sr8_in  = cast(sr8_out - xin_serial, 'like', T.sr8_in);
    end

    % BFII
    if b2 == 0
        bf2_out = cast(sr4_out, 'like', T.bf2_out);
        sr4_in  = cast(bf1_out, 'like', T.sr4_in);
    else
        if b3 == 0
            bf2_out = cast(sr4_out - 1i * bf1_out, 'like', T.bf2_out);
            sr4_in  = cast(sr4_out + 1i * bf1_out, 'like', T.sr4_in);
        else
            bf2_out = cast(sr4_out + bf1_out, 'like', T.bf2_out);
            sr4_in  = cast(sr4_out - bf1_out, 'like', T.sr4_in);
        end
    end

    % Twiddle Factor Address Generator & Complex Multiplier
    phase_multiplier_lut = [2, 1, 3, 0];
    mux_select_lines = (b3 * 2) + b2;
    current_phase_mult = phase_multiplier_lut(mux_select_lines + 1);

    local_quarter_cnt = mod(cnt, 4);
    twiddle_rom_addr = current_phase_mult * local_quarter_cnt;

    % ROM read: compute in double, then cast to table type (models pre-quantized ROM)
    twiddle_factor_double = exp(-1j * 2 * pi * twiddle_rom_addr / 16);
    twiddle_factor = cast(twiddle_factor_double, 'like', T.twiddle_factor);

    complex_mult_out = cast(bf2_out * twiddle_factor, 'like', T.complex_mult_out);

    % STAGE 2

    % BFI_2
    if b1 == 0
        bf3_out = cast(sr2_out, 'like', T.bf3_out);
        sr2_in  = cast(complex_mult_out, 'like', T.sr2_in);
    else
        bf3_out = cast(sr2_out + complex_mult_out, 'like', T.bf3_out);
        sr2_in  = cast(sr2_out - complex_mult_out, 'like', T.sr2_in);
    end

    % BFII_2
    if b0 == 0
        bf4_out = cast(sr1_out, 'like', T.bf4_out);
        sr1_in  = cast(bf3_out, 'like', T.sr1_in);
    else
        if b1 == 0
            bf4_out = cast(sr1_out - 1i * bf3_out, 'like', T.bf4_out);
            sr1_in  = cast(sr1_out + 1i * bf3_out, 'like', T.sr1_in);
        else
            bf4_out = cast(sr1_out + bf3_out, 'like', T.bf4_out);
            sr1_in  = cast(sr1_out - bf3_out, 'like', T.sr1_in);
        end
    end

    if clk >= 15 && out_idx <= 16
        out_fft_raw(out_idx) = bf4_out;
        out_idx = out_idx + 1;
    end

    SR8 = [sr8_in, SR8(1:end-1)];
    SR4 = [sr4_in, SR4(1:end-1)];
    SR2 = [sr2_in, SR2(1:end-1)];
    SR1 = [sr1_in, SR1(1:end-1)];

end

% Reorder the output (bit-reversal)
bit_rev_indices = bin2dec(fliplr(dec2bin(0:15, 4))) + 1;
y = cast(complex(zeros(1, N)), 'like', T.y);
y(bit_rev_indices) = out_fft_raw;

end