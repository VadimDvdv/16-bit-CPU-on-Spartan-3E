module top #(
    parameter PROG_FILE = "prog.hex"
) (
    input  wire       clk,
    input  wire       initial_rst,
    input  wire [2:0] sw,
    output wire [7:0] led
);

    control_unit #(
        .PROG_FILE(PROG_FILE)
    ) u_cpu (
        .clk        (clk),
        .initial_rst(initial_rst),
        .dbg_addr   (sw),
        .dbg_data   (led)
    );

endmodule
