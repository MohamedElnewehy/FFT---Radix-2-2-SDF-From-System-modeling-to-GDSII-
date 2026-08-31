
module shift_reg #(
    parameter  WIDTH = 16, // Data width (number of bits per register)
    parameter  DEPTH = 8   // Number of shift stages (delay amount)
)(
    input  wire             clk,
    input  wire             rst_n, // Asynchronous Reset (Active-low)
    input  wire             en,    // Shift Enable
    input  wire [WIDTH-1:0] d_in,  // Data Input
    output wire [WIDTH-1:0] d_out  // Data Output (output of the last stage)
);

    reg [WIDTH-1:0] shift_regs [0:DEPTH-1];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i=i+1) begin
                shift_regs[i] <= 0;
            end
        end 
        else if (en) begin
            shift_regs[0] <= d_in;
            for (i = 1; i < DEPTH; i=i+1) begin
                shift_regs[i] <= shift_regs[i-1];
            end
        end
    end

    assign d_out = shift_regs[DEPTH-1];

endmodule
