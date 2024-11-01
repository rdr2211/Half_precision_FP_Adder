module extractor (
    input [15:0] operand_a,  // 16-bit input operand A
    input [15:0] operand_b,  // 16-bit input operand B
    output reg [4:0] exp_a,   // 5-bit exponent of A
    output reg [4:0] exp_b,   // 5-bit exponent of B
    output reg [10:0] mant_a,  // 11-bit mantissa of A (including hidden bit)
    output reg [10:0] mant_b,  // 11-bit mantissa of B (including hidden bit)
    output reg sign_a,        // Sign of A
    output reg sign_b,        // Sign of B
    output reg zero_flag,     // Zero flag
    output reg infinity_flag, // Infinity flag
    output reg NaN_flag       // NaN flag
);

    always @(*) begin
        // Initialize outputs
        zero_flag = 1'b0;
        infinity_flag = 1'b0;
        NaN_flag = 1'b0;

        // Extract sign and exponent
        sign_a = operand_a[15]; // Sign bit of A
        sign_b = operand_b[15]; // Sign bit of B

        exp_a = operand_a[14:10]; // Exponent bits of A
        exp_b = operand_b[14:10]; // Exponent bits of B

        // Check for zero, infinity, and NaN for operand A
        if (operand_a == 16'b0) begin
            zero_flag = 1'b1;
            mant_a = 11'b0; // Set mantissa to 0 for zero
        end else begin
            if (|operand_a[9:0] == 1'b1) begin
                mant_a = {1'b1, operand_a[9:0]}; // Implicit leading 1 for hidden bit
            end else begin
                mant_a = {1'b0, operand_a[9:0]}; // Implicit leading 0 for zero mantissa
            end
        end

        // Check for zero, infinity, and NaN for operand B
        if (operand_b == 16'b0) begin
            zero_flag = 1'b1;
            mant_b = 11'b0; // Set mantissa to 0 for zero
        end else begin
            if (|operand_b[9:0] == 1'b1) begin
                mant_b = {1'b1, operand_b[9:0]}; // Implicit leading 1 for hidden bit
            end else begin
                mant_b = {1'b0, operand_b[9:0]}; // Implicit leading 0 for zero mantissa
            end
        end

	zero_flag = ~mant_a[10] & ~mant_b[10];

        // Check for infinity and NaN for A
        if (exp_a == 5'b11111 && operand_a[9:0] == 10'b0) begin
            infinity_flag = 1'b1; // Check if A is infinity
        end else if (exp_a == 5'b11111 && operand_a[9:0] != 10'b0) begin
            NaN_flag = 1'b1; // Check if A is NaN
        end

        // Check for infinity and NaN for B
        if (exp_b == 5'b11111 && operand_b[9:0] == 10'b0) begin
            infinity_flag = 1'b1; // Check if B is infinity
        end else if (exp_b == 5'b11111 && operand_b[9:0] != 10'b0) begin
            NaN_flag = 1'b1; // Check if B is NaN
        end
    end

endmodule

