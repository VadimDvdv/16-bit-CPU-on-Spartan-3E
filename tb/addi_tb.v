`timescale 1ns / 1ps

module addi_tb;

    // initialize uut
    reg        clk;
    reg        initial_rst;
    reg  [2:0] dbg_addr;
    wire [7:0] dbg_data;
    control_unit #(
        .PROG_FILE("sim/prog.hex")
    ) uut (
        .clk        (clk),
        .initial_rst(initial_rst),
        .dbg_addr   (dbg_addr),
        .dbg_data   (dbg_data)
    );

    // 10 ns clk
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;  // for loop counter

    // golden model function
    function signed [7:0] golden_addi;
        input signed [7:0] rs1;
        input signed [5:0] imm6;
        begin
            golden_addi = rs1 + imm6;
        end
    endfunction

    function signed [7:0] golden_sub;
        input signed [7:0] rs1;
        input signed [7:0] rs2;
        begin
            golden_sub = rs1 - rs2;
        end
    endfunction

    task apply_reset;
        begin
            initial_rst = 1;
            repeat (2) @(negedge clk);
            initial_rst = 0;
        end
    endtask

    // for knowing we're at the right point to run check_reg task, negedge after exec state
    task apply_instr;
        begin
            while (uut.state !== 2'b10) @(negedge clk);
            @(negedge clk);
        end
    endtask

    localparam EXPECTED_CHECKS = 12;
    integer errors = 0;  // errors counter
    integer tests = 0;  // checks how many tests actually ran, so timeout doesn't say success

    task check_reg;
        input [8*16:1] label;
        input [2:0] r;
        input [7:0] expected;
        reg [7:0] actual;
        begin
            dbg_addr = r;
            #1;  // let read3_data settle
            actual = dbg_data;
            tests  = tests + 1;
            if (actual === expected) begin
                $display("  PASS  %0s = 0x%02h", label, actual);
            end else begin
                errors = errors + 1;
                $display("  FAIL  %0s = 0x%02h  (expected 0x%02h)", label, actual, expected);
            end
        end
    endtask

    task summary;
        begin
            $display("CURRENT REG CONTENTS");
            for (i = 0; i < 8; i = i + 1)
            $display(
                "REG[%1d]: %8b (%02h)", i, uut.u_regfile.registers[i], uut.u_regfile.registers[i]
            );
            if (errors === 0 && tests == EXPECTED_CHECKS) begin
                $display("TESTS PASSED SUCCESSFULLY, 0 ERRORS");
            end else begin
                $display("TESTS FAILED, %0d ERRORS, %0d of %0d checks ran", errors, tests,
                         EXPECTED_CHECKS);
            end
        end
    endtask

    // infinite loop watchdog
    initial begin
        #1000;  // timeout time
        $display("ERROR: timeout");
        summary();
        $finish;
    end

    integer          a;  // for bystander loop counter, avoiding overlaps with i
    reg     [8*16:1] lbl;  // label for bystander registers
    initial begin
        $dumpfile("sim/addi_test.vcd");
        $dumpvars(0, addi_tb);
        for (i = 0; i < 8; i = i + 1) $dumpvars(0, uut.u_regfile.registers[i]);

        // starting by resetting & keeping switches off
        dbg_addr = 3'b0;
        apply_reset();

        apply_instr();  // 100F
        check_reg("R0 = 0+15", 3'd0, golden_addi(8'sd0, 6'sd15));

        apply_instr();  // 1221
        check_reg("R1 = 15-31", 3'd1, golden_addi(8'sd15, -6'sd31));

        apply_instr();  // 0441
        check_reg("R2 = -16-15", 3'd2, golden_sub(-8'sd16, 8'sd15));

        apply_instr();  // 161F
        check_reg("R3 = 15+31", 3'd3, golden_addi(8'sd15, 6'sd31));

        apply_instr();  // 16DF
        check_reg("R3 = 46+31", 3'd3, golden_addi(8'sd46, 6'sd31));

        apply_instr();  // 16DF
        check_reg("R3 = 77+31", 3'd3, golden_addi(8'sd77, 6'sd31));

        apply_instr();  // 16D3
        check_reg("R3 = 108+19", 3'd3, golden_addi(8'sd108, 6'sd19));

        apply_instr();  // 16D1
        check_reg("R3 = 127+1", 3'd3, golden_addi(8'sd127, 6'sd1));

        // bystanders — never written, must stay 0
        for (a = 4; a < 8; a = a + 1) begin
            $sformat(lbl, "bystander R%0d", a);
            check_reg(lbl, a[2:0], 8'h00);
        end

        summary();
        $finish;
    end

endmodule
