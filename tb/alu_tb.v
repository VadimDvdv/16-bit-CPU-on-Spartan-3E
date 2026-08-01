`timescale 1ns / 1ps

module alu_tb;

    // Define I/O
    reg [7:0] A, B;  // reg because we set up this value
    reg  [2:0] opcode;
    wire [7:0] result;  // wire because it's driven by the instantiated module
    wire [3:0] flags;

    // instantiate alu
    alu uut (
        .A     (A),
        .B     (B),
        .opcode(opcode),
        .result(result),
        .flags (flags)
    );

    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, alu_tb);

        $display("Time |   A   |   B   | op | result | flags | expected");
        $display("-----------------------------------------------------");

        // operation tests
        // add
        A      = 8'b00001111;
        B      = 8'b11110000;
        opcode = 3'b000;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111111");

        // sub
        A      = 8'b00001111;
        B      = 8'b11110000;
        opcode = 3'b001;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=00011111");

        // and
        A      = 8'b10001111;
        B      = 8'b11110000;
        opcode = 3'b010;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=10000000");

        // or
        A      = 8'b00001111;
        B      = 8'b01110000;
        opcode = 3'b011;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=01111111");

        // xor
        A      = 8'b01010101;
        B      = 8'b10101011;
        opcode = 3'b100;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111110");

        // not A
        A      = 8'b00000001;
        B      = 8'b00000000;
        opcode = 3'b101;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111110");

        // shift left
        A      = 8'b11111111;
        B      = 8'b00000000;
        opcode = 3'b110;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111110");

        // shift right
        A      = 8'b11111111;
        B      = 8'b00000000;
        opcode = 3'b111;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=01111111");

        // flag tests
        // zero flag (should be 1)
        A      = 8'b11111111;
        B      = 8'b11111111;
        opcode = 3'b100;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=00000000, zero=1");

        // carry-out flag (should be 1)
        A      = 8'b11111111;
        B      = 8'b11111111;
        opcode = 3'b000;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111110, carry=1");

        // sign flag (should be 1)
        A      = 8'b00001111;
        B      = 8'b00010000;
        opcode = 3'b001;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=11111111, sign=1");

        // overflow flag (should be 1)
        A      = 8'b01111111;
        B      = 8'b00000001;
        opcode = 3'b000;
        #10;
        $display("%4t | %b | %b | %b | %b | %b | %s", $time, A, B, opcode, result, flags,
                 "result=10000000, overflow=1");

        $finish;
    end


endmodule
