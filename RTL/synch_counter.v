module sync_counter #(
    parameter WIDTH = 4 // number of bits
)(
    input  wire             clk,
    input  wire             rst_n,    // Asynchronous reset (active-low)
    input  wire             en,       // Count enable
    input  wire             sync_clr, // Synchronous clear (now used as Frame Start)
    output wire [WIDTH-1:0] count     // Counter output
);

    reg [WIDTH-1:0] count_reg;

    // FIX: Instantly force output to 0 when starting a new frame to prevent off-by-one errors
    assign count = sync_clr ? {WIDTH{1'b0}} : count_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= {WIDTH{1'b0}};
        end 
        else if (en) begin
            count_reg <= count + 1'b1;
        end
    end

endmodule