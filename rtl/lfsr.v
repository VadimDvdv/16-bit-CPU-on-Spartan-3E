// Idea: random number generator, polynomial is passed as an input, then it is fed into a function. Output - random number
module lfsr (
    input         clk,
    input         rst,
    input         en,
    input  [15:0] seed,
    output        out
);
    reg [15:0] shift_reg;
    wire feedback = (shift_reg[3] & shift_reg[7]) ^ shift_reg[11] ^ (shift_reg[0] | shift_reg[13]);

    always @(posedge clk) begin
        if (rst) shift_reg <= seed;
        else begin
            if (en) begin
                shift_reg <= {shift_reg[14:0], feedback};
            end
        end
    end

    assign out = shift_reg[15];

endmodule
