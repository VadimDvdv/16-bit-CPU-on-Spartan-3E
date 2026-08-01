`timescale 1ns / 1ps

module adder_subtractor (
    input  [7:0] A,
    input  [7:0] B,
    input        ctrl,
    output [7:0] result,
    output       c_out,
    output       V
);
    // Two's complement: invert B and inject carry-in when subtracting
    wire [7:0] B_eff = ctrl ? ~B : B;
    wire       cin = ctrl;

    // Full 8-bit addition, temp[8] is c_out
    wire [8:0] temp = {1'b0, A} + {1'b0, B_eff} + cin;

    // Lower 7 bits only - temp1[7] is C_7 (carry into MSB)
    wire [7:0] temp1 = {1'b0, A[6:0]} + {1'b0, B_eff[6:0]} + cin;

    assign result = temp[7:0];
    assign c_out  = temp[8];
    assign V      = temp[8] ^ temp1[7];

endmodule

module alu (
    input      [7:0] A,
    input      [7:0] B,
    input      [2:0] opcode,
    output reg [7:0] result,
    output reg [3:0] flags
);

    // instantiate the adder-subtractor, OUTSIDE THE PROCEDURAL BLOCK
    wire [7:0] arithmetic_result;
    wire c_out, V;
    adder_subtractor u_add_sub (
        .A     (A),
        .B     (B),
        .ctrl  (opcode[0]),
        .result(arithmetic_result),
        .c_out (c_out),
        .V     (V)
    );

    always @(*) begin

        case (opcode)
            3'b000, 3'b001: result = arithmetic_result;  // same implementation - list with a comma
            3'b010:         result = A & B;
            3'b011:         result = A | B;
            3'b100:         result = A ^ B;
            3'b101:         result = ~A;
            3'b110:         result = A << 1;
            3'b111:         result = A >> 1;
            default: begin
                result = 8'b0;
                flags  = 4'b0;
            end
        endcase

        // flags calculation
        flags[0] = ~|result;  // zero flag, NOR all bits
        flags[1] = ~(opcode[1] | opcode[2]) & c_out;  // c_out flag
        flags[2] = result[7];  // sign flag
        flags[3] = ~(opcode[1] | opcode[2]) & V;
    end

endmodule

// --indentation_spaces=4 --wrap_spaces=4 --column_limit=100 --port_declarations_alignment=align --port_declarations_indentation=indent --named_port_alignment=align --named_parameter_alignment=align --formal_parameters_alignment=align --formal_parameters_indentation=indent --module_net_variable_alignment=preserve --assignment_statement_alignment=preserve --case_items_alignment=align --class_member_variable_alignment=align --distribution_items_alignment=align --enum_assignment_statement_alignment=align --struct_union_members_alignment=align --try_wrap_long_lines=true
