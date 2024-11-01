`timescale 1ns / 1ps

module tb_fp_adder_16_bit;

    // Parameters
    reg [15:0] operand_a;      // 16-bit input operand A
    reg [15:0] operand_b;      // 16-bit input operand B
    reg clock;                   // Clock signal
    reg reset;                 // Start signal for the addition
    reg final_operation;
    wire [15:0] result;       // 16-bit output result
    wire overflow_flag;       // Overflow flag
    wire underflow_flag;      // Underflow flag
    wire zero_flag;
    wire infinity_flag;       // Infinity flag
    wire NaN_flag;            // NaN flag

    // Instantiate the fp_adder_16_bit module
    fp_adder_16_bit uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .clock(clock),
        .reset(reset),
	.final_operation(final_operation),
        .result(result),
        .overflow_flag(overflow_flag),
        .underflow_flag(underflow_flag),
	.zero_flag(zero_flag),
        .infinity_flag(infinity_flag),
        .NaN_flag(NaN_flag)
    );

    // Clock Generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 10 time units clock period
    end

    // Test Cases
    initial begin
        // Initialize signals
        reset = 1;
        operand_a = 16'b0;
        operand_b = 16'b0;

        // Wait for the clock to stabilize
        @(posedge clock);
	reset = 0;

        // Test Case 1: Simple Addition
        operand_a = 16'b1011111011100001; 
        operand_b = 16'b0010101001111011; 
        final_operation = 0; 
        @(posedge clock);
        #10; // Wait for operation to complete
        $display("Test Case 1 executed: A = %b, B = %b", operand_a, operand_b);
        display_result(operand_a, operand_b, result, overflow_flag, underflow_flag, infinity_flag, NaN_flag);

        // Test Case 2: Addition Resulting 
        operand_a = 16'b0000000000000000; 
        operand_b = 16'b0000000000000000; 
        final_operation = 0;
        @(posedge clock);
        #10;
        display_result(operand_a, operand_b, result, overflow_flag, underflow_flag, infinity_flag, NaN_flag);

        // Test Case 3: Addition Resulting in Underflow
        operand_a = 16'b0000000000000001; // Small positive number
        operand_b = 16'b0000000000000001; // Small positive number
        final_operation = 0;
        @(posedge clock);
        #10;
        display_result(operand_a, operand_b, result, overflow_flag, underflow_flag, infinity_flag, NaN_flag);

        // Test Case 4: Addition of NaN
        operand_a = 16'b0111111111111111; // NaN
        operand_b = 16'b0100000000000000; // 2.0
        final_operation = 0; 
        @(posedge clock);
        #10;
        display_result(operand_a, operand_b, result, overflow_flag, underflow_flag, infinity_flag, NaN_flag);

        // Test Case 5: Addition Resulting in Infinity
        operand_a = 16'b0111111111111110; // Infinity
        operand_b = 16'b0111111111111110; // Infinity
        final_operation = 0; 
        @(posedge clock);
        #10;
        display_result(operand_a, operand_b, result, overflow_flag, underflow_flag, infinity_flag, NaN_flag);

        // End simulation
        $finish;
    end

    // Display the result
    task display_result(
        input [15:0] a,
        input [15:0] b,
        input [15:0] res,
        input ovf,
        input uf,
        input inf,
        input NaN
    );
        begin
            $display("A: %b (%0d), B: %b (%0d) => Result: %b (%0d), Overflow: %b, Underflow: %b, Infinity: %b, NaN: %b",
                a, a, b, b, res, res, ovf, uf, inf, NaN);
        end
    endtask

endmodule
