`timescale 1ps / 1ps

module addi_tb;

    reg clk;
    reg initial_rst;
    control_unit uut (
        .clk(clk),
        .initial_rst(initial_rst)
    );

    // 10 ns clk
    initial clk = 0;
    always #5 clk = ~clk;

    function void init();
        initial_rst = 1;
        @(negedge clk);
        @(negedge clk);
        initial_rst = 0;
    endfunction

    task apply_reset;
        begin
            initial_rst = 1;
            repeat (2) @(negedge clk);
            initial_rst = 0;
        end
    endtask

endmodule
