`timescale 1ns / 1ps

module addi_tb;

    // initialize uut
    reg clk;
    reg initial_rst;
    reg [3:0] dbg_addr;
    wire [7:0] dbg_data;
    control_unit uut (
        .clk        (clk),
        .initial_rst(initial_rst),
        .dbg_addr(dbg_addr),
        .dbg_data(dbg_data)
    );

    // 10 ns clk
    initial clk = 0;
    always #5 clk = ~clk;

    integer errors = 0; // error counter

    // golden model function
    function signed [7:0] golden_addi;
        input signed [7:0] rs1;
        input signed [5:0] imm6;
        begin
           golden_addi = rs1 + imm6;
        end
    endfunction

    task apply_reset;
        begin
            initial_rst = 1;
            repeat (2) @(negedge clk);
            initial_rst = 0;
        end
    endtask

    // for knowing we're at the right point to run check task, negedge after exec state
    task apply_instr;
        begin
            while (uut.state !== 2'b10) @(negedge clk)
            @(negedge clk)
        end
    endtask

    integer i; // for loop counter
    initial begin
        $dumpfile("sim/addi_test.vcd");
        $dumpvars(0, addi_tb);
        for (i = 0; i < 8; i = i + 1)
        $dumpvars(0, uut.u_regfile.registers[i]);

        // starting by resetting & keeping switches off
        dbg_addr = 3'b0; 
        apply_reset();


    end
