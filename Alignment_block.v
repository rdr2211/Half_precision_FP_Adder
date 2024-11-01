module alignment_block (
    input sign_m,
    input sign_n,
    input [4:0] exp_m,              // Exponent of mantissa M
    input [4:0] exp_n,              // Exponent of mantissa N
    input [10:0] mant_m,            // Mantissa of M (10 bits)
    input [10:0] mant_n,            // Mantissa of N (10 bits)
    output reg [13:0] aligned_mantissa, // Aligned mantissa with guard, round, and sticky bits (14 bits)
    output reg [4:0] big_exponent,  // Big exponent
    output reg [10:0] big_mantissa,  // Big mantissa
    output reg final_sign,
    output reg operation_int
);

    wire [5:0] exp_diff;             // Absolute difference
    wire [10:0] man_diff;
    wire bigSel;

    // Calculate exponent difference
    assign exp_diff = {1'b0, exp_m[4:0]} + {1'b1, ~exp_n[4:0]} + 1;
    assign man_diff = {1'b0, mant_m[9:0]} + {1'b1, ~mant_n[9:0]} + 1;

    // Check if exponents or mantissas are zero for comparison
    wire expDiffIsZero;
    assign expDiffIsZero = ~|exp_diff;
    wire manDiffIsZero;
    assign manDiffIsZero = ~|man_diff;

    // Determine the larger value based on exponents and mantissas
    assign bigSel = expDiffIsZero ? man_diff[10] : exp_diff[5];

    wire [3:0] shiftRtAmt = (exp_diff > 11) ? 4'b1011 : exp_diff[3:0];

    // Determine addition or subtraction based on signs
    wire operation = sign_m ^ sign_n;

    // Select the big and little mantissas for alignment
    wire signOut = bigSel ? sign_n : sign_m;
    wire [10:0] bigMan = bigSel ? mant_n : mant_m;
    wire [10:0] lilMan = bigSel ? mant_m : mant_n;

    // Shift the smaller mantissa to align with the larger one
    wire [10:0] shiftedMan = lilMan >> shiftRtAmt;

    // Define guard, round, and sticky bits
    wire guard = ((shiftRtAmt == 0) || (exp_diff > 11)) ? 1'b0 : lilMan[shiftRtAmt - 1];
    wire round = ((shiftRtAmt <= 1) || (exp_diff > 11)) ? 1'b0 : lilMan[shiftRtAmt - 2];

    // Mask to determine sticky bit by tracking bits shifted out
    reg [10:0] mask;
    always @(*) begin
        casez ({shiftRtAmt, (exp_diff > 11)})
            5'b00000: mask = 11'b00000000000;
            5'b00010: mask = 11'b00000000000;
            5'b00100: mask = 11'b00000000001;
            5'b00110: mask = 11'b00000000011;
            5'b01000: mask = 11'b00000000111;
            5'b01010: mask = 11'b00000001111;
            5'b01100: mask = 11'b00000011111;
            5'b01110: mask = 11'b00000111111;
            5'b10000: mask = 11'b00001111111;
            5'b10010: mask = 11'b00011111111;
            5'b10100: mask = 11'b00111111111;
            5'b10110: mask = 11'b01111111111;
            5'b????1: mask = 11'b11111111111;
            default: mask = 11'b00000000000;
        endcase
    end

    wire sticky = |(lilMan & mask);

    // Combine shifted mantissa, guard, round, and sticky bits
    wire [13:0] alignedMan = {shiftedMan, guard, round, sticky};

    assign aligned_mantissa = alignedMan;
    assign big_exponent = exp_m >= exp_n ? exp_m : exp_n;
    assign big_mantissa = bigMan;
    assign final_sign = signOut;
    assign operation_int = operation;
endmodule

