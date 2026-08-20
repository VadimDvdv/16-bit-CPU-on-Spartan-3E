`timescale 1ns / 1ps

// ============================================================
// Testbench for the R-type CPU (control_unit + alu + regfile + rom)
//
// Program under test lives in prog.hex:
//   ADD R3,R1,R2 / SUB R4,R1,R2 / AND R5,R1,R2 /
//   OR  R6,R1,R2 / XOR R7,R1,R2 / SHR R0,R1
//
// The regfile has no load instruction yet, so operands R1/R2 are
// seeded directly via a hierarchical force AFTER reset deasserts
// (reset clears the regfile, so seeding earlier would be wiped).
//
// Build & run:
//   iverilog -g2012 -o r_type_test control_unit.v alu.v regfile.v r_type_tb.v
//   vvp r_type_test
//   gtkwave cpu_test.vcd
// (prog.hex must be in the working directory)
// ============================================================

module r_type_tb;

    reg clk;
    reg initial_rst;
    reg [2:0] dbg_addr;
    wire [7:0] dbg_data;
    integer i;

    // Device under test - control_unit instantiates alu, regfile, rom
    control_unit #(.PROG_FILE("sim/prog.hex")) uut (
        .clk        (clk),
        .initial_rst(initial_rst),
        .dbg_addr   (dbg_addr),
        .dbg_data   (dbg_data)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // reset, then seed operands
    initial begin
        $dumpfile("sim/r_type_test.vcd");
        $dumpvars(0, r_type_tb);
        for (i = 0; i < 8; i = i + 1)  // dump regfile words for GTKWave
        $dumpvars(0, uut.u_regfile.registers[i]);

        // keep all switches off
        dbg_addr = 3'b0;

        initial_rst = 1;
        @(negedge clk);
        @(negedge clk);  // two posedges elapse with reset high
        initial_rst = 0;

        uut.u_regfile.registers[1] = 8'h0C;    // R1 = 12
        uut.u_regfile.registers[2] = 8'h05;    // R2 = 5
        $display("t=%0t  reset released; seeded R1=0x0C, R2=0x05", $time);
        $display("time  state  PC  IR    aluA aluB aluRes");
    end

    // per-cycle trace (state: 0=FETCH 1=REG-READ 2=EXEC_WB)
    always @(posedge clk)
        if (!initial_rst)
            $display(
                "%4t   %0d    %0d  %h  %h   %h   %h",
                $time,
                uut.state,
                uut.program_counter,
                uut.instruction_reg,
                uut.alu_a,
                uut.alu_b,
                uut.alu_result
            );

    // run long enough for 6 instrs x 3 cycles, then verify
    initial begin
        #250;
        $display("\n---- final register file ----");
        for (i = 0; i < 8; i = i + 1) $display("  R%0d = 0x%02h", i, uut.u_regfile.registers[i]);

        $display("\n---- checks ----");
        check(3'd0, 8'h06);  // SHR R0,R1  -> 0x0C >> 1
        check(3'd1, 8'h0C);  // seeded, untouched
        check(3'd2, 8'h05);  // seeded, untouched
        check(3'd3, 8'h11);  // ADD 12 + 5
        check(3'd4, 8'h07);  // SUB 12 - 5
        check(3'd5, 8'h04);  // AND 0x0C & 0x05
        check(3'd6, 8'h0D);  // OR  0x0C | 0x05
        check(3'd7, 8'h09);  // XOR 0x0C ^ 0x05

        $display("---- done ----");
        $finish;
    end

    task check;
        input [2:0] r;
        input [7:0] expected;
        begin
            if (uut.u_regfile.registers[r] === expected)
                $display("  PASS  R%0d = 0x%02h", r, expected);
            else
                $display(
                    "  FAIL  R%0d = 0x%02h  (expected 0x%02h)",
                    r,
                    uut.u_regfile.registers[r],
                    expected
                );
        end
    endtask

endmodule
