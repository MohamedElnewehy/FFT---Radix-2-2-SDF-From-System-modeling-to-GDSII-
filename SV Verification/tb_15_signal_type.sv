`timescale 1ns / 1ps

module tb_fft_5signals;

    reg         clk;
    reg         rst_n;
    reg         x_valid;
    reg         x_start;
    reg         x_done;
    wire [21:0] x_in;   // 22-bit width (11 Real + 11 Imag)

    wire        y_valid;
    wire        y_start;
    wire        y_done;
    wire [27:0] y_out;  // 28-bit width (14 Real + 14 Imag)

    // Instantiate Top FFT Module
    FFT_2_2_top uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .x_valid (x_valid),
        .x_start (x_start),
        .x_done  (x_done),
        .x_in    (x_in),
        .y_valid (y_valid),
        .y_start (y_start),
        .y_done  (y_done),
        .y_out   (y_out)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    // File Handles
    integer f_in, f_out;
    reg signed [10:0] sample_re, sample_im; // 11-bit signed (Q1.10)

    assign x_in = {sample_re, sample_im};   // Packs 22 bits

    // Look-Up Tables for Sine and Cosine (Q1.10 Format)
    reg signed [10:0] sine_wave [0:15];
    reg signed [10:0] cosine_wave[0:15];

    initial begin
        // Sine Wave (1 full period, 16 points) - Q1.10
        sine_wave[0]  =  11'sd0;   sine_wave[1]  =  11'sd196; sine_wave[2]  =  11'sd362; sine_wave[3]  =  11'sd473;
        sine_wave[4]  =  11'sd512; sine_wave[5]  =  11'sd473; sine_wave[6]  =  11'sd362; sine_wave[7]  =  11'sd196;
        sine_wave[8]  =  11'sd0;   sine_wave[9]  = -11'sd196; sine_wave[10] = -11'sd362; sine_wave[11] = -11'sd473;
        sine_wave[12] = -11'sd512; sine_wave[13] = -11'sd473; sine_wave[14] = -11'sd362; sine_wave[15] = -11'sd196;

        // Cosine Wave (1 full period, 16 points) - Q1.10
        cosine_wave[0]  =  11'sd512; cosine_wave[1]  =  11'sd473; cosine_wave[2]  =  11'sd362; cosine_wave[3]  =  11'sd196;
        cosine_wave[4]  =  11'sd0;   cosine_wave[5]  = -11'sd196; cosine_wave[6]  = -11'sd362; cosine_wave[7]  = -11'sd473;
        cosine_wave[8]  = -11'sd512; cosine_wave[9]  = -11'sd473; cosine_wave[10] = -11'sd362; cosine_wave[11] = -11'sd196;
        cosine_wave[12] =  11'sd0;   cosine_wave[13] =  11'sd196; cosine_wave[14] =  11'sd362; cosine_wave[15] =  11'sd473;
    end

    // File handles initialization
    initial begin
        f_out = $fopen("rtl_output.txt", "w");
        if (!f_out) begin
            $display("ERROR: Could not open rtl_output.txt");
            $finish;
        end
    end

    // Extracts 14-bit signed real [27:14] and 14-bit signed imag [13:0]
    always @(posedge clk) begin
        if (y_valid) begin
            $fdisplay(f_out, "%0.6f %0.6f", $signed(y_out[27:14]) / 1024.0, $signed(y_out[13:0]) / 1024.0);
        end
    end

    // Frame transmission task for the 5 signals
    task send_frame;
        input [2:0] frame_type; 
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge clk);
                x_valid = 1'b1;
                x_start = (i == 0);
                x_done  = (i == 15);

                case (frame_type)
                    3'd0: begin sample_re = (i == 0) ? 11'sd512 : 11'sd0; sample_im = 11'sd0; end // 1. Impulse
                    3'd1: begin sample_re = 11'sd512;                      sample_im = 11'sd0; end // 2. DC Constant
                    3'd2: begin sample_re = sine_wave[i];                  sample_im = 11'sd0; end // 3. Sine Wave
                    3'd3: begin sample_re = cosine_wave[i];                sample_im = 11'sd0; end // 4. Cosine Wave
                    3'd4: begin sample_re = (i < 8) ? 11'sd512 : 11'sd0;   sample_im = 11'sd0; end // 5. Rectangular Pulse
                endcase

                $fdisplay(f_in, "%0.6f %0.6f", $signed(sample_re) / 1024.0, $signed(sample_im) / 1024.0);
            end

            // Flush Pipeline Gap
            @(posedge clk);
            x_valid = 1'b0; x_start = 1'b0; x_done = 1'b0;
            #200;
        end
    endtask

    // Simulation Sequence
    initial begin
        clk       = 0;
        rst_n     = 0;
        x_valid   = 0;
        x_start   = 0;
        x_done    = 0;
        sample_re = 0;
        sample_im = 0;

        f_in = $fopen("input_samples.txt", "w");
        if (!f_in) begin
            $display("ERROR: Could not open input_samples.txt");
            $finish;
        end

        #20; rst_n = 1; #20;

        $display("--- Starting 5-Signal Test Suite ---");
        send_frame(3'd0); // Impulse
        send_frame(3'd1); // DC
        send_frame(3'd2); // Sine
        send_frame(3'd3); // Cosine
        send_frame(3'd4); // Rectangular

        #5000;
        $fclose(f_in);
        $fclose(f_out);
        $display("5 Signals Successfully Transmitted!");
        $finish;
    end

endmodule