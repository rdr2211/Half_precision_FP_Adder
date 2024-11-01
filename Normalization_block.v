module normalization_block (
    input [14:0] resultant_mantissa,      // 14-bit mantissa from addition block
    input [4:0] big_exponent,              // 5-bit exponent from alignment block
    input final_operation,
    input zero_flag,
    output reg [12:0] normalized_mantissa, // 13-bit normalized mantissa for rounding
    output reg [4:0] normalized_exponent    // 5-bit normalized exponent
);

    wire [3:0] leading_zero_count = 0;         // 4-bit leading zero count from priority encoder
    reg [14:0] shifted_mantissa;           // Mantissa after left shift
    reg AS;
    reg SS;
    wire [3:0] normAmt;
    wire [3:0] rawNormAmt;
    lzd14 lzd(resultant_mantissa[13:0], rawNormAmt, valid);
    assign normAmt = valid ? rawNormAmt : 4'b0;

    always @(*) begin
        // Default values
        normalized_mantissa = resultant_mantissa[12:0];
        normalized_exponent = big_exponent;
	shifted_mantissa = 0;

	if (resultant_mantissa[14] == 1 && final_operation == 0) begin
	    if (zero_flag == 1) begin
            	AS = 1; SS = 0;
            end else begin
                AS = 1; SS = 1;
            end
    	end else begin
            AS = 0; SS = 0;
    	end
        
        shifted_mantissa = SS ? resultant_mantissa >> 1 : resultant_mantissa;
        normalized_exponent = AS ? big_exponent + 1 : big_exponent;

    // Handle the case when there's a carry bit and non-zero mantissa
    if (shifted_mantissa[13] == 1) begin
        normalized_mantissa = shifted_mantissa[12:0];
    end
    // Handle normal leading-zero cases
    else if (shifted_mantissa[13] == 0 && AS == 0 && SS == 0) begin
        // Normalize for leading zeros
        if (normAmt < 13 && |resultant_mantissa == 1) begin
            // Left shift based on leading zero count if resultant_mantissa < 1
            shifted_mantissa = resultant_mantissa << normAmt;
            normalized_mantissa = shifted_mantissa[12:0];
            normalized_exponent = big_exponent + ~normAmt + 1;
        end 
        else if(normAmt == 13) begin
            normalized_exponent = big_exponent + ~normAmt + 1;
            normalized_mantissa = 0;
        end
    end    
    end
endmodule

module lzd14( 
    input [13:0] a,
    output [3:0] position,
    output valid 
);
    wire [2:0] pUpper, pLower;
    wire vUpper, vLower;

    lzd8 lzd8_1( a[13:6], pUpper[2:0], vUpper ); 
    lzd8 lzd8_2( {a[5:0], 2'b0}, pLower[2:0], vLower );  

    assign valid = vUpper | vLower;
    assign position[3] = ~vUpper;
    assign position[2] = vUpper ? pUpper[2] : pLower[2];
    assign position[1] = vUpper ? pUpper[1] : pLower[1];
    assign position[0] = vUpper ? pUpper[0] : pLower[0];
endmodule

 module lzd8( input [7:0] a,
    output [2:0] position,
    output valid );
    wire [1:0] pUpper, pLower;
    wire vUpper, vLower;
    lzd4 lzd4_1( a[7:4], pUpper[1:0], vUpper );
    lzd4 lzd4_2( a[3:0], pLower[1:0], vLower );
    assign valid = vUpper | vLower;
    assign position[2] = ~vUpper;
    assign position[1] = vUpper ? pUpper[1] : pLower[1];
    assign position[0] = vUpper ? pUpper[0] : pLower[0];
 endmodule

 module lzd4( input [3:0] a,
    output [1:0] position,
    output valid );
    wire pUpper, pLower, vUpper, vLower;
    lzd2 lzd2_1( a[3:2], pUpper, vUpper );
    lzd2 lzd2_2( a[1:0], pLower, vLower );
    assign valid = vUpper | vLower;
    assign position[1] = ~vUpper;
    assign position[0] = vUpper ? pUpper : pLower;
 endmodule

 module lzd2( input [1:0] a,
    output position,
    output valid );
    assign valid = a[1] | a[0];
    assign position = ~a[1];
 endmodule
