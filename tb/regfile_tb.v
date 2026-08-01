`timescale 1ns / 1ps

module regfile_tb ();

    // I/O
    reg clk, rst, write_en;
    reg [2:0] read1_addr, read2_addr, write_addr;
    reg [7:0] write_data;
    wire [7:0] read1_data, read2_data;

    // initialize tested regfile
    regfile uut (
        .clk       (clk),
        .rst       (rst),
        .write_en  (write_en),
        .read1_addr(read1_addr),
        .read2_addr(read2_addr),
        .write_addr(write_addr),
        .write_data(write_data),
        .read1_data(read1_data),
        .read2_data(read2_data)
    );

    // test

    // initialize clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("dumps/regfile_test.vcd");
        $dumpvars(0, regfile_tb);

        // write test
        $display("Write Test:");
        $display(" Time  |  000  |  001  |  010  |  expected");
        $display("------------------------------------------");

        // reset registers, hold for 2 cycles
        str = 0;
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        $display("%4t | %b | %b | %b | %s", $time, uut.registers[0], uut.registers[1],
                 uut.registers[2], "00000000 each");

        // write in reg 0 and 2
        @(negedge clk);
        write_en   = 1;
        write_addr = 3'd0;
        write_data = 8'b01010101;
        read1_addr = 3'b0;
        read2_addr = 3'b0;
        @(negedge clk);
        $display("%4t | %b | %b | %b | %s", $time, uut.registers[0], uut.registers[1],
                 uut.registers[2], "01010101, rest - 0's");

        @(negedge clk);
        write_addr = 3'd2;
        write_data = 8'b11111111;
        @(negedge clk);
        $display("%4t | %b | %b | %b | %s", $time, uut.registers[0], uut.registers[1],
                 uut.registers[2], "01010101 00000000 11111111");

        // read test
        $display("------------------------------------------");
        $display("");
        $display("Read Test: read from reg 0 and 1");
        @(negedge clk);
        write_en   = 0;
        read1_addr = 3'b0;
        read2_addr = 3'b001;
        @(posedge clk);
        $display("%b | %b | %s ", read1_data, read2_data, "Expected - 01010101 00000000");

        $finish;
    end


endmodule
