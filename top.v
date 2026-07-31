module top (
    input  wire       clk,
    input  wire       initial_rst,
    input  wire [2:0] sw,
    output wire [7:0] led
);

    control_unit u_cpu (
        .clk        (clk),
        .initial_rst(initial_rst),
        .sw         (sw),
        .led        (led)
    );

endmodule
