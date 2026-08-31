module BF_2 #(
    parameter integer WIDTH_IN = 24,
    parameter integer FRAC_IN  = 10,
    parameter integer WIDTH    = 28,
    parameter integer FRAC     = 11
)(
    input  wire [WIDTH_IN-1:0] data_in,
    input  wire [WIDTH-1:0]    data_in_from_reg,
    input  wire                sel,
    input  wire                rot_sel,
    output reg  [WIDTH-1:0]    data_out_to_reg,
    output reg  [WIDTH-1:0]    data_out
);

    localparam integer HW_IN = WIDTH_IN / 2;
    localparam integer HW    = WIDTH / 2;
    localparam integer SHIFT = FRAC_IN - FRAC;

    wire signed [HW_IN-1:0] din_real = data_in[WIDTH_IN-1:HW_IN];
    wire signed [HW_IN-1:0] din_imag = data_in[HW_IN-1:0];

    wire signed [HW-1:0] data_in_real_q;
    wire signed [HW-1:0] data_in_imag_q;

    generate
        if (SHIFT > 0) begin : g_shrink
            wire signed [HW_IN:0] din_real_ext = {din_real[HW_IN-1], din_real};
            wire signed [HW_IN:0] din_imag_ext = {din_imag[HW_IN-1], din_imag};
            wire signed [HW_IN:0] round_bias   = $signed(1'b1 << (SHIFT - 1));

            wire signed [HW_IN:0] rounded_real = din_real_ext + round_bias;
            wire signed [HW_IN:0] rounded_imag = din_imag_ext + round_bias;

            assign data_in_real_q = rounded_real[SHIFT + HW - 1 : SHIFT];
            assign data_in_imag_q = rounded_imag[SHIFT + HW - 1 : SHIFT];
        end else if (SHIFT < 0) begin : g_grow
            assign data_in_real_q = din_real <<< (-SHIFT);
            assign data_in_imag_q = din_imag <<< (-SHIFT);
        end else begin : g_same
            assign data_in_real_q = din_real;
            assign data_in_imag_q = din_imag;
        end
    endgenerate

    // -j rotation formula: (X + jY) * (-j) = Y - jX
    wire signed [HW-1:0] rotated_real =  data_in_imag_q;
    wire signed [HW-1:0] rotated_imag = -data_in_real_q;

    // rot_sel = 1 selects rotated data; rot_sel = 0 passes unrotated data
    wire signed [HW-1:0] operand_real = rot_sel ? rotated_real : data_in_real_q;
    wire signed [HW-1:0] operand_imag = rot_sel ? rotated_imag : data_in_imag_q;

    wire signed [HW-1:0] data_in_from_reg_real    = data_in_from_reg[WIDTH-1:HW];
    wire signed [HW-1:0] data_in_from_reg_complex = data_in_from_reg[HW-1:0];

    wire signed [HW:0] ext_reg_real    = {data_in_from_reg_real[HW-1], data_in_from_reg_real};
    wire signed [HW:0] ext_reg_complex = {data_in_from_reg_complex[HW-1], data_in_from_reg_complex};
    wire signed [HW:0] ext_op_real     = {operand_real[HW-1], operand_real};
    wire signed [HW:0] ext_op_complex  = {operand_imag[HW-1], operand_imag};

    wire signed [HW-1:0] plus_real     = (ext_reg_real + ext_op_real) ;
    wire signed [HW-1:0] plus_complex  = (ext_reg_complex + ext_op_complex) ;
    wire signed [HW-1:0] minus_real    = (ext_reg_real - ext_op_real) ;
    wire signed [HW-1:0] minus_complex = (ext_reg_complex - ext_op_complex) ;
    
    always @(*) begin
        case (sel)
            1'b0: begin
                data_out_to_reg = {data_in_real_q, data_in_imag_q};
                data_out        = data_in_from_reg;
            end
            1'b1: begin
                data_out_to_reg = {minus_real, minus_complex};
                data_out        = {plus_real,  plus_complex};
            end
            default: begin
                data_out_to_reg = {data_in_real_q, data_in_imag_q};
                data_out        = data_in_from_reg;
            end
        endcase
    end

endmodule