`timescale 1ns / 1ps

module rom #(
    parameter PROG_FILE = "prog.hex"
) (
    input  [ 5:0] rom_read_addr,
    output [15:0] rom_read_data
);

    reg [15:0] memcells[0:63];
    initial begin
        $readmemh(PROG_FILE, memcells);
    end
    assign rom_read_data = memcells[rom_read_addr];

endmodule
