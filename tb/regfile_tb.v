`timescale 1ns / 1ps

module regfile_tb ();

    localparam EXPECTED_CHECKS = 14;

    reg clk, rst, write_en;
    reg [2:0] read1_addr, read2_addr, read3_addr, write_addr;
    reg [7:0] write_data;
    wire [7:0] read1_data, read2_data, read3_data;

    integer errors = 0;
    integer tests = 0;
    integer i;

    regfile uut (
        .clk       (clk),
        .rst       (rst),
        .write_en  (write_en),
        .read1_addr(read1_addr),
        .read2_addr(read2_addr),
        .read3_addr(read3_addr),
        .write_addr(write_addr),
        .write_data(write_data),
        .read1_data(read1_data),
        .read2_data(read2_data),
        .read3_data(read3_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Read a register through read port 1 and compare.
    task check_p1;
        input [8*24-1:0] name;
        input [2:0] r;
        input [7:0] expected;
        begin
            read1_addr = r;
            #1;
            tests = tests + 1;
            if (read1_data === expected) $display("  PASS  %0s  R%0d = 0x%02h", name, r, read1_data);
            else begin
                errors = errors + 1;
                $display("  FAIL  %0s  R%0d = 0x%02h (expected 0x%02h)", name, r, read1_data, expected);
            end
        end
    endtask

    // Compare a value that is already on a port.
    task check_val;
        input [8*24-1:0] name;
        input [7:0] actual;
        input [7:0] expected;
        begin
            tests = tests + 1;
            if (actual === expected) $display("  PASS  %0s  = 0x%02h", name, actual);
            else begin
                errors = errors + 1;
                $display("  FAIL  %0s  = 0x%02h (expected 0x%02h)", name, actual, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/regfile_test.vcd");
        $dumpvars(0, regfile_tb);

        $display("---- regfile checks ----");

        // synchronous reset clears all 8 registers
        write_en = 0;
        rst = 1;
        read1_addr = 0;
        read2_addr = 0;
        read3_addr = 0;
        write_addr = 0;
        write_data = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        rst = 0;
        for (i = 0; i < 8; i = i + 1) check_p1("reset clears", i[2:0], 8'h00);

        // write R0
        @(negedge clk);
        write_en   = 1;
        write_addr = 3'd0;
        write_data = 8'h55;
        @(negedge clk);
        check_p1("write R0", 3'd0, 8'h55);

        // write R2
        write_addr = 3'd2;
        write_data = 8'hff;
        @(negedge clk);
        check_p1("write R2", 3'd2, 8'hff);

        // untouched register stays cleared
        check_p1("R1 untouched", 3'd1, 8'h00);

        // write_en low must block the write
        @(negedge clk);
        write_en   = 0;
        write_addr = 3'd1;
        write_data = 8'hAA;
        @(negedge clk);
        check_p1("write_en low blocks", 3'd1, 8'h00);

        // all three read ports are independent and asynchronous
        read1_addr = 3'd0;
        read2_addr = 3'd1;
        read3_addr = 3'd2;
        #1;
        check_val("port2 reads R1", read2_data, 8'h00);
        check_val("port3 reads R2", read3_data, 8'hff);

        if (errors === 0 && tests == EXPECTED_CHECKS)
            $display("TESTS PASSED SUCCESSFULLY, %0d CHECKS", tests);
        else
            $display("TESTS FAILED: %0d errors, %0d of %0d checks ran",
                     errors, tests, EXPECTED_CHECKS);

        $finish;
    end

endmodule