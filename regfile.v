`timescale 1ns / 1ps

module regfile (
    input        clk,
    input        rst,         // initial reset, active-high
    input        write_en,
    input  [2:0] read1_addr,  // 1 mem cell to read from
    input  [2:0] read2_addr,  // 2 mem cell to read from
    input  [2:0] read3_addr,  // 3 mem cell to read from, for LEDs
    input  [2:0] write_addr,  // write address
    input  [7:0] write_data,  // data input for write
    output [7:0] read1_data,  // output from cell 1
    output [7:0] read2_data   // output from cell 2
    output [7:0] read3_data   // output from mem cell 3, for LEDs
);

    reg [7:0] registers[0:7];  // initialize registers

    always @(posedge clk) begin
        integer i;  // for loop counter
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'b0;
            end
        end else if (write_en) begin
            registers[write_addr] <= write_data;
        end
    end

    assign read1_data = registers[read1_addr];
    assign read2_data = registers[read2_addr];
    assign read3_data = registers[read3_addr]; // for LEDs

endmodule
