module rounding_block (
    input [12:0] normalized_mantissa,  // Normalized 13-bit mantissa (including guard, round, sticky bits)
    input [4:0] normalized_exponent,   // Normalized 5-bit exponent
    input sign,                        // Final sign bit
    input infinity_flag,               // Flag indicating if the value is infinity
    input NaN_flag,                    // Flag indicating if the value is NaN
    output reg [15:0] result,          // Final 16-bit floating-point result
    output reg overflow_flag,          // Overflow flag
    output reg underflow_flag          // Underflow flag
);

    reg [4:0] final_exponent;          // Final exponent after rounding
    reg [9:0] final_mantissa;          // Final mantissa after rounding
    reg round_bit, guard_bit, sticky_bit; // Extracted PGRS bits

    always @(*) begin
        // Initialize flags
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;

        // Default values for exponent and mantissa
        final_exponent = normalized_exponent;
        final_mantissa = normalized_mantissa[12:3]; // Extract the top 10 bits

        // Extract PGRS bits
        guard_bit = normalized_mantissa[2];
        round_bit = normalized_mantissa[1];
        sticky_bit = normalized_mantissa[0];

        // Perform rounding based on the PGRS bits
        if (guard_bit && (round_bit || sticky_bit || final_mantissa[0])) begin
            // Round up if guard = 1 and (round = 1, sticky = 1, or mantissa is odd)
            final_mantissa = final_mantissa + 1'b1;
        end

        // Handle mantissa overflow, normalize if necessary
        if (final_mantissa == 10'b1000000000) begin
            final_mantissa = 10'b0000000001;  // Reset mantissa to 1
            final_exponent = final_exponent + 1'b1; // Increment exponent
        end

        // Check for overflow (exponent too large)
        if (final_exponent == 5'b11111) begin
            overflow_flag = 1'b1;
            final_mantissa = 10'b0000000000; // Set mantissa to 0 for infinity
        end

        // Check for underflow (exponent too small)
        if (final_exponent == 5'b00000 && final_mantissa == 10'b0000000000) begin
            underflow_flag = 1'b1;
        end

        // Handle NaN case
        if (NaN_flag) begin
            final_exponent = 5'b11111;   // Set exponent to max (for NaN)
            final_mantissa = 10'b1111111111; // Set mantissa to all 1s for NaN
        end

        // Handle infinity case
        if (infinity_flag) begin
            final_exponent = 5'b11111;   // Set exponent to max (for infinity)
            final_mantissa = 10'b0000000000; // Set mantissa to 0 for infinity
        end

        // Pack the result into a 16-bit floating-point format
        result = {sign, final_exponent, final_mantissa};
    end
endmodule

