module FFT_2_2_top (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         x_valid,
    input  wire         x_start,
    input  wire         x_done,
    input  wire [21:0]  x_in,

    output wire         y_valid,
    output wire         y_start,
    output wire         y_done,
    output wire [27:0]  y_out
);

    // ==============================================================
    // CONTROL
    // ==============================================================

    wire pipe_en;

    control_unit #(
        // Increased LATENCY from 15 to 16 due to the pipeline stage in the multiplier
        .LATENCY(16)
    ) u_ctrl (
        .clk       (clk),
        .rst_n     (rst_n),

        .valid_in  (x_valid),
        .start_in  (x_start),
        .end_in    (x_done),

        .valid_out (y_valid),
        .start_out (y_start),
        .end_out   (y_done),

        .pipe_en   (pipe_en)
    );

    
    // synch_counter
    wire [3:0] cnt;

    sync_counter #(
        .WIDTH(4)
    ) u_sync_counter (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (pipe_en),
        .sync_clr (x_valid & x_start),
        .count    (cnt)
    );

    wire b3 = cnt[3];
    wire b2 = cnt[2];
    wire b1 = cnt[1];
    wire b0 = cnt[0];

    reg b1_d;
    reg b0_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b1_d <= 1'b0;
            b0_d <= 1'b0;
        end else if (pipe_en) begin
            b1_d <= b1;  // Delayed b1 for Stage 3 & Stage 4
            b0_d <= b0;  // Delayed b0 for Stage 4
        end
    end

    
    // STAGE 1
    wire [23:0] sr8_out;
    wire [23:0] sr8_in;
    wire [23:0] bf1_out;

    shift_reg #(
        .WIDTH(24),
        .DEPTH(8)
    ) u_sr8 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (pipe_en),
        .d_in  (sr8_in),
        .d_out (sr8_out)
    );

    BF_1 #(
        .WIDTH_IN(22),
        .FRAC_IN (10),
        .WIDTH   (24),
        .FRAC    (10)
    ) u_bf1 (
        .data_in          (x_in),
        .data_in_from_reg (sr8_out),
        .sel              (b3),
        .data_out_to_reg  (sr8_in),
        .data_out         (bf1_out)
    );

   
    // STAGE 2
    wire [27:0] sr4_out;
    wire [27:0] sr4_in;
    wire [27:0] bf2_out;

    shift_reg #(
        .WIDTH(28),
        .DEPTH(4)
    ) u_sr4 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (pipe_en),
        .d_in  (sr4_in),
        .d_out (sr4_out)
    );

    BF_2 #(
        .WIDTH_IN(24),
        .FRAC_IN (10),
        .WIDTH   (28),
        .FRAC    (11)
    ) u_bf2 (
        .data_in          (bf1_out),
        .data_in_from_reg (sr4_out),
        .sel              (b2),
        .rot_sel          (~b3),
        .data_out_to_reg  (sr4_in),
        .data_out         (bf2_out)
    );

   
    // TWIDDLE GENERATOR
    wire signed [11:0] tw_real;
    wire signed [11:0] tw_imag;

    twiddle_gen u_twiddle (
        .b3      (b3),
        .b2      (b2),
        .b1      (b1),
        .b0      (b0),
        .tw_real (tw_real),
        .tw_imag (tw_imag)
    );

    // COMPLEX MULTIPLIER
    wire [27:0] complex_mult_out;

    cplx_multiplier #(
        .WIDTH_A  (28),
        .WIDTH_B  (24),
        .WIDTH_OUT(28),
        .FRAC_A   (11),
        .FRAC_B   (11),
        .FRAC_OUT (11)
    ) u_mult (
        // NEW: Added pipeline control signals
        .clk (clk),          
        .rst_n (rst_n),      
        .en  (pipe_en),      
        .A   (bf2_out),
        .B   ({tw_real, tw_imag}),
        .out (complex_mult_out)
    );

    
    // STAGE 3
    wire [27:0] sr2_out;
    wire [27:0] sr2_in;
    wire [27:0] bf3_out;

    shift_reg #(
        .WIDTH(28),
        .DEPTH(2)
    ) u_sr2 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (pipe_en),
        .d_in  (sr2_in),
        .d_out (sr2_out)
    );

    BF_1 #(
        .WIDTH_IN(28),
        .FRAC_IN (11),
        .WIDTH   (28),
        .FRAC    (10)
    ) u_bf3 (
        .data_in          (complex_mult_out),
        .data_in_from_reg (sr2_out),
        // NEW: Using delayed control signal b1_d
        .sel              (b1_d),
        .data_out_to_reg  (sr2_in),
        .data_out         (bf3_out)
    );

    // STAGE 4
    wire [27:0] sr1_out;
    wire [27:0] sr1_in;
    wire [27:0] bf4_out;

    shift_reg #(
        .WIDTH(28),
        .DEPTH(1)
    ) u_sr1 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (pipe_en),
        .d_in  (sr1_in),
        .d_out (sr1_out)
    );

    BF_2 #(
        .WIDTH_IN(28),
        .FRAC_IN (10),
        .WIDTH   (28),
        .FRAC    (10)
    ) u_bf4 (
        .data_in          (bf3_out),
        .data_in_from_reg (sr1_out),
        // NEW: Using delayed control signals b0_d and b1_d
        .sel              (b0_d),
        .rot_sel          (~b1_d),
        .data_out_to_reg  (sr1_in),
        .data_out         (bf4_out)
    );


    wire signed [13:0] bf4_re = $signed(bf4_out[27:14]);
    wire signed [13:0] bf4_im = $signed(bf4_out[13:0]);

    assign y_out = {{bf4_re}, {bf4_im}};

endmodule
