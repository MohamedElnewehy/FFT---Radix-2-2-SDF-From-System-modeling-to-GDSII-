function T = FFT_2_2_types(dt)

switch dt
    case 'double'
        T.x             = fi([],1,1+63,63);
        T.b0            = double([]);
        T.b1            = double([]);
        T.b2            = double([]);
        T.b3            = double([]);
        T.sr8_out       = double([]);
        T.sr4_out       = double([]);
        T.sr2_out       = double([]);
        T.sr1_out       = double([]);
        T.sr8_in        = double([]);
        T.sr4_in        = double([]);
        T.sr2_in        = double([]);
        T.sr1_in        = double([]);
        T.bf1_out       = double([]);
        T.bf2_out       = double([]);
        T.bf3_out       = double([]);
        T.bf4_out       = double([]);
        T.twiddle_factor    = double([]);
        T.complex_mult_out  = double([]);
        T.y             = double([]);

    case 'single'
        T.x             = fi([],1,1+31,31);
        T.b0            = single([]);
        T.b1            = single([]);
        T.b2            = single([]);
        T.b3            = single([]);
        T.sr8_out       = single([]);
        T.sr4_out       = single([]);
        T.sr2_out       = single([]);
        T.sr1_out       = single([]);
        T.sr8_in        = single([]);
        T.sr4_in        = single([]);
        T.sr2_in        = single([]);
        T.sr1_in        = single([]);
        T.bf1_out       = single([]);
        T.bf2_out       = single([]);
        T.bf3_out       = single([]);
        T.bf4_out       = single([]);
        T.twiddle_factor    = single([]);
        T.complex_mult_out  = single([]);
        T.y             = single([]);

    case 'Test_1'
        T.x             = fi([],1,1+15,15);
        T.b0            = double([]);   % 1-bit unsigned control bit
        T.b1            = double([]);
        T.b2            = double([]);
        T.b3            = double([]);
        T.sr8_out       = fi([],1,2+14,14);
        T.sr4_out       = fi([],1,3+13,13);
        T.sr2_out       = fi([],1,4+12,12);
        T.sr1_out       = fi([],1,4+12,12);
        T.sr8_in        = fi([],1,2+14,14);
        T.sr4_in        = fi([],1,3+13,13);
        T.sr2_in        = fi([],1,4+12,12);
        T.sr1_in        = fi([],1,4+12,12);
        T.bf1_out       = fi([],1,2+14,14);
        T.bf2_out       = fi([],1,3+13,13);
        T.bf3_out       = fi([],1,4+12,12);
        T.bf4_out       = fi([],1,4+12,12);
        T.twiddle_factor    = fi([],1,1+15,15);
        T.complex_mult_out  = fi([],1,3+13,13);
        T.y             = fi([],1,4+12,12);

    case 'Test_2'
        T.x             = fi([],1,1+13,13);
        T.b0            = double([]);   % 1-bit unsigned control bit
        T.b1            = double([]);
        T.b2            = double([]);
        T.b3            = double([]);
        T.sr8_out       = fi([],1,2+12,12);
        T.sr4_out       = fi([],1,3+11,11);
        T.sr2_out       = fi([],1,4+10,10);
        T.sr1_out       = fi([],1,4+10,10);
        T.sr8_in        = fi([],1,2+12,12);
        T.sr4_in        = fi([],1,3+11,11);
        T.sr2_in        = fi([],1,4+10,10);
        T.sr1_in        = fi([],1,4+10,10);
        T.bf1_out       = fi([],1,2+12,12);
        T.bf2_out       = fi([],1,3+11,11);
        T.bf3_out       = fi([],1,4+10,10);
        T.bf4_out       = fi([],1,4+10,10);
        T.twiddle_factor    = fi([],1,1+13,13);
        T.complex_mult_out  = fi([],1,3+11,11);
        T.y             = fi([],1,4+12,12);

    case 'Test_3'
        T.x             = fi([],1,1+11,11);
        T.b0            = double([]);   % 1-bit unsigned control bit
        T.b1            = double([]);
        T.b2            = double([]);
        T.b3            = double([]);
        T.sr8_out       = fi([],1,2+10,10);
        T.sr4_out       = fi([],1,3+9,9);
        T.sr2_out       = fi([],1,4+8,8);
        T.sr1_out       = fi([],1,4+8,8);
        T.sr8_in        = fi([],1,2+10,10);
        T.sr4_in        = fi([],1,3+9,9);
        T.sr2_in        = fi([],1,4+8,8);
        T.sr1_in        = fi([],1,4+8,8);
        T.bf1_out       = fi([],1,2+10,10);
        T.bf2_out       = fi([],1,3+9,9);
        T.bf3_out       = fi([],1,4+8,8);
        T.bf4_out       = fi([],1,4+8,8);
        T.twiddle_factor    = fi([],1,1+11,11);
        T.complex_mult_out  = fi([],1,3+9,9);
        T.y             = fi([],1,4+12,12);

    case 'Test_4'
        T.x             = fi([],1,1+10,10);
        T.b0            = double([]);   % 1-bit unsigned control bit
        T.b1            = double([]);
        T.b2            = double([]);
        T.b3            = double([]);
        T.sr8_out       = fi([],1,2+10,10);
        T.sr4_out       = fi([],1,3+11,11);
        T.sr2_out       = fi([],1,4+10,10);
        T.sr1_out       = fi([],1,4+10,10);
        T.sr8_in        = fi([],1,2+10,10);
        T.sr4_in        = fi([],1,3+11,11);
        T.sr2_in        = fi([],1,4+10,10);
        T.sr1_in        = fi([],1,4+10,10);
        T.bf1_out       = fi([],1,2+10,10);
        T.bf2_out       = fi([],1,3+11,11);
        T.bf3_out       = fi([],1,4+10,10);
        T.bf4_out       = fi([],1,4+10,10);
        T.twiddle_factor    = fi([],1,1+11,11);
        T.complex_mult_out  = fi([],1,3+11,11);
        T.y             = fi([],1,4+10,10);
end

end