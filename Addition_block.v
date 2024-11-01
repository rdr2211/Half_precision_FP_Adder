module addition_block (
    input [13:0] aligned_mantissa,      // Aligned Mantissa (from alignment block, 14 bits)
    input [10:0] big_mantissa,           // Big Mantissa (from alignment block, 11 bits)
    input operation_int,
    input final_operation,                // Final operation (0: add, 1: subtract)
    output reg [14:0] resultant_mantissa // Resultant Mantissa (14 bits)
);

    reg [14:0] SDm_fa; // Sum/Difference for full adder output (14 bits to accommodate overflow)
    reg temp_sign;     // Temporary sign for the result
    reg operation;
    always @(*) begin
        // Initialize outputs
        resultant_mantissa = 0;
        SDm_fa = 0;
	
	operation = final_operation ^ operation_int;	

        // Check the final operation
        if (operation == 1'b0) begin // Addition
            // Add the aligned mantissa and big mantissa
            SDm_fa = {1'b0, aligned_mantissa} + {1'b0, big_mantissa, 3'b0};
        end else begin // Subtraction
            // Subtract the small mantissa from the big mantissa
            SDm_fa = {1'b0, big_mantissa, 3'b0} + {1'b0, ~aligned_mantissa} + 1;
	    SDm_fa[14] = 0;
        end

        // Assign the resultant mantissa directly from the sum/difference
        resultant_mantissa = SDm_fa[14:0]; // Capture the upper 13 bits for the resultant mantissa        
    end
endmodule

