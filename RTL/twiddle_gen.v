module twiddle_gen (
    input  wire b3, b2, b1, b0,
    output reg  signed [11:0] tw_real,   // Q1.11
    output reg  signed [11:0] tw_imag    // Q1.11
);

    reg  [1:0] phase_mult;
    wire [1:0] quarter_cnt = {b1, b0};   // local_quarter_cnt = mod(cnt,4)
    wire [1:0] mux_sel     = {b3, b2};   // mux_select_lines = b3*2 + b2
    reg  [3:0] addr;                     // twiddle_rom_addr, range 0..9

    always @(*) begin
        case (mux_sel)
            2'd0: phase_mult = 2'd2;
            2'd1: phase_mult = 2'd1;
            2'd2: phase_mult = 2'd3;
            2'd3: phase_mult = 2'd0;
        endcase
        addr = phase_mult * quarter_cnt;
    end

    // ROM: exp(-j*2*pi*addr/16), pre-quantized to Q1.11, round-to-nearest, saturate
    always @(*) begin
        case (addr)
            4'd0: begin tw_real =  12'sd2047; tw_imag =  12'sd0;    end  // 1.000000 - saturated
            4'd1: begin tw_real =  12'sd1892; tw_imag = -12'sd784;  end  // 0.923880 - j0.382683
            4'd2: begin tw_real =  12'sd1448; tw_imag = -12'sd1448; end  // 0.707107 - j0.707107
            4'd3: begin tw_real =  12'sd784;  tw_imag = -12'sd1892; end  // 0.382683 - j0.923880
            4'd4: begin tw_real =  12'sd0;    tw_imag = -12'sd2048; end  // 0.000000 - j1.000000
            4'd5: begin tw_real = -12'sd784;  tw_imag = -12'sd1892; end  //-0.382683 - j0.923880
            4'd6: begin tw_real = -12'sd1448; tw_imag = -12'sd1448; end  //-0.707107 - j0.707107
            4'd7: begin tw_real = -12'sd1892; tw_imag = -12'sd784;  end  //-0.923880 - j0.382683
            4'd8: begin tw_real = -12'sd2048; tw_imag =  12'sd0;    end  //-1.000000 - j0.000000
            4'd9: begin tw_real = -12'sd1892; tw_imag =  12'sd784;  end  //-0.923880 + j0.382683
            default: begin tw_real = 12'sd0;  tw_imag =  12'sd0;    end  // unreachable (addr 10-15)
        endcase
    end

endmodule