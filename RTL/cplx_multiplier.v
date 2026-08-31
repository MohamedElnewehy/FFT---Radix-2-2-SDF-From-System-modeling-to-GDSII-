module cplx_multiplier #(
    parameter integer WIDTH_A   = 28,  // total width of A = {X,Y}, HA=WIDTH_A/2 bits each
    parameter integer WIDTH_B   = 24,  // total width of B = {C,S}, HB=WIDTH_B/2 bits each
    parameter integer WIDTH_OUT = 28,  // total width of out = {R,I}, HO=WIDTH_OUT/2 bits each
    parameter integer FRAC_A    = 11,  // fractional bits in X,Y  (Q format of A)
    parameter integer FRAC_B    = 11,  // fractional bits in C,S  (Q format of B)
    parameter integer FRAC_OUT  = 11   // fractional bits in R,I  (Q format of out)
)(
    // NEW: Added clock, reset, and enable for pipelining
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 en,    
    
    input  wire [WIDTH_A-1:0]   A,     // {X, Y}
    input  wire [WIDTH_B-1:0]   B,     // {C, S}  (twiddle factor)
    output reg  [WIDTH_OUT-1:0] out    // {R, I}
);

    localparam integer HA = WIDTH_A/2;
    localparam integer HB = WIDTH_B/2;
    localparam integer HO = WIDTH_OUT/2;

    wire signed [HA-1:0] A_real    = A[WIDTH_A-1:HA];    // X
    wire signed [HA-1:0] A_complex = A[HA-1:0];          // Y

    wire signed [HB-1:0] B_real    = B[WIDTH_B-1:HB];    // C
    wire signed [HB-1:0] B_complex = B[HB-1:0];          // S

  
    // done with full internal precision (no truncation)
    reg signed [HA:0]           E;       // X - Y                 (1 extra bit)
    reg signed [HB:0]           CpS;     // C + S                 (1 extra bit)
    reg signed [HB:0]           CmS;     // C - S                 (1 extra bit)
    
    // NEW: PIPELINE REGISTERS for intermediate products
    reg signed [HB+HA:0]        Z_reg;       
    reg signed [HB+HA+1:0]      CmS_Y_reg;   
    reg signed [HB+HA+1:0]      CpS_X_reg;   

    // NEW: Variables moved to Stage 2 (after registers)
    reg signed [HB+HA+2:0]      R_full;  // (C-S)*Y + Z
    reg signed [HB+HA+2:0]      I_full;  // (C+S)*X - Z
    reg signed [HB+HA+2:0]      R_shift, I_shift;
    
    // right-shift amount needed to bring a (FRAC_A+FRAC_B)-fractional-bit
    localparam integer SHIFT = FRAC_A + FRAC_B - FRAC_OUT;

    // --- NEW: STAGE 1 (Combinational Logic before Registers) ---
    always @(*) begin
        // eqn. 6.30 
        E   = A_real - A_complex;              // E = X - Y
        CpS = B_real + B_complex;
        CmS = B_real - B_complex;
    end

    // --- NEW: PIPELINE REGISTERS (The Cut to reduce Critical Path) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Z_reg     <= 0;
            CmS_Y_reg <= 0;
            CpS_X_reg <= 0;
        end else if (en) begin
            Z_reg     <= B_real * E;                      // Z = C * E
            // eqn. 6.31 / 6.32
            CmS_Y_reg <= CmS * A_complex;
            CpS_X_reg <= CpS * A_real;
        end
    end

    // --- NEW: STAGE 2 (Combinational Logic after Registers) ---
    always @(*) begin
        R_full = CmS_Y_reg + Z_reg;                    // R = (C-S)*Y + Z
        // remember: no need to align CmS_Y, Z becouse they are already aligned
        I_full = CpS_X_reg - Z_reg;                    // I = (C+S)*X - Z

        // align fractional bits to the output's Q format 
        R_shift = R_full >>> SHIFT;
        I_shift = I_full >>> SHIFT;

        out = {R_shift[HO-1:0], I_shift[HO-1:0]};
    end

endmodule