module control_unit #(
    parameter integer LATENCY = 16
)(
    input  wire clk,
    input  wire rst_n,

    input  wire valid_in,
    input  wire start_in,
    input  wire end_in,

    output wire valid_out,
    output wire start_out,
    output wire end_out,

    output wire pipe_en
);

    reg [LATENCY-1:0] valid_pipe;
    reg [LATENCY-1:0] start_pipe;
    reg [LATENCY-1:0] end_pipe;

    assign pipe_en = valid_in | (|valid_pipe);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= {LATENCY{1'b0}};
            start_pipe <= {LATENCY{1'b0}};
            end_pipe   <= {LATENCY{1'b0}};
        end
        else if (pipe_en) begin
            valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};
            start_pipe <= {start_pipe[LATENCY-2:0], start_in};
            end_pipe   <= {end_pipe[LATENCY-2:0], end_in};
        end
    end

    assign valid_out = valid_pipe[LATENCY-1];
    assign start_out = start_pipe[LATENCY-1];
    assign end_out   = end_pipe[LATENCY-1];

endmodule