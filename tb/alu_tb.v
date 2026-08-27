`timescale 1ns / 1ps

module alu_tb;

    localparam EXPECTED_CHECKS = 12;

    reg [7:0] A, B;
    reg     [2:0] opcode;
    wire    [7:0] result;
    wire    [3:0] flags;

    integer       errors = 0;
    integer       tests = 0;

    alu uut (
        .A     (A),
        .B     (B),
        .opcode(opcode),
        .result(result),
        .flags (flags)
    );

    // Drive one vector and compare result and flags.
    // flags = {overflow, sign, carry, zero}
    task check;
        input [8*20-1:0] name;
        input [7:0] a_in;
        input [7:0] b_in;
        input [2:0] op_in;
        input [7:0] exp_result;
        input [3:0] exp_flags;
        begin
            A      = a_in;
            B      = b_in;
            opcode = op_in;
            #10;
            tests = tests + 1;
            if (result === exp_result && flags === exp_flags)
                $display("  PASS  %0s  result=%b flags=%b", name, result, flags);
            else begin
                errors = errors + 1;
                $display("  FAIL  %0s", name);
                $display("        result=%b expected=%b", result, exp_result);
                $display("        flags =%b expected=%b", flags, exp_flags);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/alu_test.vcd");
        $dumpvars(0, alu_tb);

        $display("---- alu checks ----");

        // operations
        check("ADD", 8'h0f, 8'hf0, 3'b000, 8'hff, 4'b0100);
        check("SUB", 8'h0f, 8'hf0, 3'b001, 8'h1f, 4'b0000);
        check("AND", 8'h8f, 8'hf0, 3'b010, 8'h80, 4'b0100);
        check("OR", 8'h0f, 8'h70, 3'b011, 8'h7f, 4'b0000);
        check("XOR", 8'h55, 8'hab, 3'b100, 8'hfe, 4'b0100);
        check("NOT", 8'h01, 8'h00, 3'b101, 8'hfe, 4'b0100);
        check("SHL", 8'hff, 8'h00, 3'b110, 8'hfe, 4'b0100);
        check("SHR", 8'hff, 8'h00, 3'b111, 8'h7f, 4'b0000);

        // flag corners
        check("zero flag", 8'hff, 8'hff, 3'b100, 8'h00, 4'b0001);
        check("carry out", 8'hff, 8'hff, 3'b000, 8'hfe, 4'b0110);
        check("sign flag", 8'h0f, 8'h10, 3'b001, 8'hff, 4'b0100);
        check("overflow", 8'h7f, 8'h01, 3'b000, 8'h80, 4'b1100);

        if (errors === 0 && tests == EXPECTED_CHECKS)
            $display("TESTS PASSED SUCCESSFULLY, %0d CHECKS", tests);
        else
            $display(
                "TESTS FAILED: %0d errors, %0d of %0d checks ran", errors, tests, EXPECTED_CHECKS
            );

        $finish;
    end

endmodule
