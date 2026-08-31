`timescale 1ns / 1ps

module tb_fft_random_signals;

    reg         clk;
    reg         rst_n;
    reg         x_valid;
    reg         x_start;
    reg         x_done;
    wire [21:0] x_in;
    wire        y_valid;
    wire        y_start;
    wire        y_done;
    wire [27:0] y_out;

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

    always #5 clk = ~clk;

    integer f_in, f_out, k;
    reg signed [10:0] sample_re, sample_im;
    assign x_in = {sample_re, sample_im};

    // ---- sample counters: drive the flush by real data, not a guessed clock count ----
    integer in_count, out_count;

    always @(posedge clk) begin
        if (x_valid) in_count = in_count + 1;
    end

    initial begin
        f_out = $fopen("rtl_random_output.txt", "w");
        if (!f_out) begin
            $display("ERROR: Could not open rtl_output.txt");
            $finish;
        end
    end

    always @(posedge clk) begin
        if (y_valid) begin
            out_count = out_count + 1;
            $fdisplay(f_out, "%0.6f %0.6f", $signed(y_out[27:14]) / 1024.0, $signed(y_out[13:0]) / 1024.0);
        end
    end

    // ---- stimulus task ----
    // Values are computed with a BLOCKING assign into local vars (no shared-signal
    // race, they're private locals), then driven onto the actual DUT-facing regs
    // with NONBLOCKING assignment at the posedge. Nonblocking is the standard
    // race-free way to drive synchronous stimulus: RHS of every nonblocking
    // assignment (ours AND the DUT's internal capture flops) is evaluated using
    // pre-edge values, then all updates apply together -- no dependency on
    // always-block execution order, and no extra clock-cycle shift like a
    // manual "#1 after posedge" trick introduces.
    task send_random_frame;
        integer i;
        reg signed [10:0] re_val, im_val;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                re_val = $random % 512;
                im_val = $random % 512;
                @(posedge clk);
                x_valid   <= 1'b1;
                x_start   <= (i == 0);
                x_done    <= (i == 15);
                sample_re <= re_val;
                sample_im <= im_val;
                $fdisplay(f_in, "%0.6f %0.6f", $signed(re_val) / 1024.0, $signed(im_val) / 1024.0);
            end
        end
    endtask

    initial begin
        clk       = 0;
        rst_n     = 0;
        x_valid   = 0;
        x_start   = 0;
        x_done    = 0;
        sample_re = 0;
        sample_im = 0;
        in_count  = 0;
        out_count = 0;

        f_in = $fopen("input_random_samples.txt", "w");
        if (!f_in) begin
            $display("ERROR: Could not open input_samples.txt");
            $finish;
        end

        #20; rst_n = 1; #20;

        for (int i = 0; i < 1; i = i + 1) begin
            for (k = 0; k < 1000; k = k + 1) begin
                send_random_frame();
            end

            // The last iteration's @(posedge clk) drove sample_re/im/x_done for the
            // LAST real sample via <=, so that data only becomes visible to the DUT
            // AFTER this edge and gets captured on the NEXT edge. So we must let one
            // more posedge pass (with x_valid still effectively 1 going into it)
            // before deasserting -- otherwise that last real sample is never latched.
            @(posedge clk);
            x_valid <= 1'b0;
            x_start <= 1'b0;
            x_done  <= 1'b0;

            // Flush: wait until every sample that actually went IN has actually
            // come OUT. No magic clock-count guess, so it's immune to whatever
            // the real pipeline latency happens to be.
            while (out_count < in_count) @(posedge clk);

            // small guard margin in case y_valid pulses need one extra settle cycle
            repeat (2) @(posedge clk);

            rst_n <= 0;
            #20;
            rst_n <= 1;
        end

        #5000;

        if (in_count !== out_count)
            $display("MISMATCH: in_count=%0d out_count=%0d", in_count, out_count);
        else
            $display("OK: in_count == out_count == %0d", in_count);

        $fclose(f_in);
        $fclose(f_out);
        $finish;
    end

endmodule