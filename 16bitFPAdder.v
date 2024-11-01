module fp_adder_16_bit (
    input clock,
    input reset,
    input [15:0] operand_a,
    input [15:0] operand_b,
    input final_operation,
    output reg [15:0] result,
    output reg overflow_flag,
    output reg underflow_flag,
    output reg zero_flag,
    output reg infinity_flag,
    output reg NaN_flag
);

    // Internal signals for module connections
    wire [4:0] exp_a, exp_b;
    wire [10:0] mant_a, mant_b;
    wire sign_a, sign_b;
    wire [4:0] big_exponent;
    wire [10:0] big_mantissa_int;
    wire [13:0] aligned_mantissa_int;
    wire [14:0] resultant_mantissa_int;
    wire final_sign;
    wire [12:0] normalized_mantissa;
    wire [4:0] normalized_exponent;
    wire op_int;
    wire zero_flag_int;
    wire infinity_flag_int;
    wire NaN_flag_int;
    wire overflow_flag_int;
    wire underflow_flag_int;
    wire [15:0] result_int;

    // Pipeline registers for each stage
    reg [15:0] reg_operand_a, reg_operand_b;
    reg [4:0] reg_exp_a, reg_exp_b;
    reg [10:0] reg_mant_a, reg_mant_b;
    reg reg_sign_a, reg_sign_b;

    reg [4:0] reg_big_exponent;
    reg [10:0] reg_big_mantissa;
    reg [13:0] reg_aligned_mantissa;
    reg reg_op_int, reg_final_sign;

    reg [14:0] reg_resultant_mantissa;

    reg [12:0] reg_normalized_mantissa;
    reg [4:0] reg_normalized_exponent;

    // Register before extractor block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_operand_a <= 0;
            reg_operand_b <= 0;
        end else begin
            reg_operand_a <= operand_a;
            reg_operand_b <= operand_b;
        end
    end

    // Extraction block
    extractor extract (
        .operand_a(reg_operand_a),
        .operand_b(reg_operand_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .zero_flag(zero_flag_int),
        .infinity_flag(infinity_flag_int),
        .NaN_flag(NaN_flag_int)
    );

    // Register after extraction block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_exp_a <= 0;
            reg_exp_b <= 0;
            reg_mant_a <= 0;
            reg_mant_b <= 0;
            reg_sign_a <= 0;
            reg_sign_b <= 0;
        end else begin
            reg_exp_a <= exp_a;
            reg_exp_b <= exp_b;
            reg_mant_a <= mant_a;
            reg_mant_b <= mant_b;
            reg_sign_a <= sign_a;
            reg_sign_b <= sign_b;
        end
    end

    // Alignment block
    alignment_block align (
        .sign_m(reg_sign_a),
        .sign_n(reg_sign_b),
        .exp_m(reg_exp_a),
        .exp_n(reg_exp_b),
        .mant_m(reg_mant_a),
        .mant_n(reg_mant_b),
        .aligned_mantissa(aligned_mantissa_int),
        .big_exponent(big_exponent),
        .big_mantissa(big_mantissa_int),
        .final_sign(final_sign),
        .operation_int(op_int)
    );

    // Register after alignment block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_big_exponent <= 0;
            reg_big_mantissa <= 0;
            reg_aligned_mantissa <= 0;
            reg_op_int <= 0;
            reg_final_sign <= 0;
        end else begin
            reg_big_exponent <= big_exponent;
            reg_big_mantissa <= big_mantissa_int;
            reg_aligned_mantissa <= aligned_mantissa_int;
            reg_op_int <= op_int;
            reg_final_sign <= final_sign;
        end
    end

    // Addition/subtraction stage
    addition_block add_sub (
        .aligned_mantissa(reg_aligned_mantissa),
        .big_mantissa(reg_big_mantissa),
        .operation_int(reg_op_int),
        .final_operation(final_operation),
        .resultant_mantissa(resultant_mantissa_int)
    );

    // Register after addition block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_resultant_mantissa <= 0;
        end else begin
            reg_resultant_mantissa <= resultant_mantissa_int;
        end
    end

    // Normalization stage
    normalization_block normalize (
        .resultant_mantissa(reg_resultant_mantissa),
        .big_exponent(reg_big_exponent),
        .final_operation(final_operation),
        .zero_flag(zero_flag_int),
        .normalized_mantissa(normalized_mantissa),
        .normalized_exponent(normalized_exponent)
    );

    // Register after normalization block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_normalized_mantissa <= 0;
            reg_normalized_exponent <= 0;
        end else begin
            reg_normalized_mantissa <= normalized_mantissa;
            reg_normalized_exponent <= normalized_exponent;
        end
    end

    // Rounding stage
    rounding_block round (
        .normalized_mantissa(reg_normalized_mantissa),
        .normalized_exponent(reg_normalized_exponent),
        .sign(reg_final_sign),
        .infinity_flag(infinity_flag_int),
        .NaN_flag(NaN_flag_int),
        .result(result_int),
        .overflow_flag(overflow_flag_int),
        .underflow_flag(underflow_flag_int)
    );

    // Register for output after rounding
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            result <= 0;
            overflow_flag <= 0;
            underflow_flag <= 0;
            zero_flag <= 0;
            infinity_flag <= 0;
            NaN_flag <= 0;
        end else begin
            result <= result_int;
            overflow_flag <= overflow_flag_int;
            underflow_flag <= underflow_flag_int;
            zero_flag <= zero_flag_int;
            infinity_flag <= infinity_flag_int;
            NaN_flag <= NaN_flag_int;
        end
    end

endmodule

`include "Extraction_block.v"
`include "Alignment_block.v"
`include "Addition_block.v"
`include "Normalization_block.v"
`include "Rounding_block.v"

