`timescale 1ns / 1ps

// ============================================================
// ISA — 16-bit instruction word, 8-bit datapath, 8 registers R0–R7
// ============================================================
// FORMATS
//   R  [15:12]=0000  [11:9]=rd  [8:6]=rs1  [5:3]=rs2  [2:0]=func
//   I  [15:12]=op    [11:9]=rd  [8:6]=rs1  [5:0]=imm6 (signed)
//   J  [15:12]=op    [11:9]=rd  [8:0]=imm9 (signed)
//
// OPCODES                                    status
//   0000 R-type ALU (func below)             done
//   0001 ADDI  rd = rs1 + sext(imm6)         done, tb in progress
//   0010 LDI   rd = sext(imm9)               todo
//   0011 LD    rd = MEM[rs1 + imm6]          todo
//   0100 ST    MEM[rs1 + imm6] = rd          todo
//   0101 BEQ   if rs1==rs2  PC += imm6       todo
//   0110 BNE   if rs1!=rs2  PC += imm6       todo
//   0111 BLT   if rs1< rs2  PC += imm6       todo
//   1000 JAL   rd = PC+1;   PC += imm9       todo
//
// R-TYPE FUNC [2:0]  (fed straight to ALU opcode)
//   000 ADD  rs1+rs2     100 XOR  rs1^rs2
//   001 SUB  rs1-rs2     101 NOT  ~rs1        (rs2 ignored)
//   010 AND  rs1&rs2     110 SHL  rs1<<1      (rs2 ignored)
//   011 OR   rs1|rs2     111 SHR  rs1>>1      (rs2 ignored)
//
// MICROARCH: multi-cycle, 3 states / R-type instruction
//   FETCH -> REG-READ (latch A,B) -> EXEC+WB (ALU, write rd, PC++)
// Harvard: instruction ROM addressed by PC; data memory separate (todo).
// ============================================================

module control_unit (
    input        clk,
    input        initial_rst,
    input  [2:0] dbg_addr,
    output [7:0] dbg_data
);

    // setup PC and IR
    reg [5:0] program_counter;   // 6-bit PC allows 64 words in ROM
    reg [15:0] instruction_reg;  // 16-bit IR for 16-bit word length
    wire [3:0] opcode = instruction_reg[15:12];
    reg [1:0] state; // state register

    // initialize ALU and regfile
    reg [7:0] alu_a, alu_b;
    reg [2:0] alu_opcode;
    wire [7:0] alu_result;
    wire [3:0] alu_flags;

    alu u_alu (
        .A     (alu_a),
        .B     (alu_b),
        .opcode(alu_opcode),
        .result(alu_result),
        .flags (alu_flags)
    );

    reg reg_write_en;
    reg [2:0] reg_read1_addr, reg_read2_addr, reg_write_addr;
    reg [7:0] reg_write_data;
    wire [7:0] reg_read1_data, reg_read2_data;

    regfile u_regfile (
        .clk       (clk),
        .rst       (initial_rst),
        .write_en  (reg_write_en),
        .read1_addr(reg_read1_addr),
        .read2_addr(reg_read2_addr),
        .read3_addr(dbg_addr),
        .write_addr(reg_write_addr),
        .write_data(reg_write_data),
        .read1_data(reg_read1_data),
        .read2_data(reg_read2_data),
        .read3_data(dbg_data)
    );

    // instantiate ROM module, input is hard-wired to PC
    wire [15:0] u_rom_read_data;

    rom u_rom (
        .rom_read_addr(program_counter),
        .rom_read_data(u_rom_read_data)
    );

    // Combinational logic selecting modules' inputs
    always @(*) begin
        case (opcode)
            // ADD DEFAULTS
            // R-type
            4'b0: begin
                reg_read1_addr = instruction_reg[8:6];
                reg_read2_addr = instruction_reg[5:3];
                alu_opcode = instruction_reg[2:0];
                if (state == 2'b10) reg_write_en = 1;
                else reg_write_en = 0;
                reg_write_addr = instruction_reg[11:9];
                reg_write_data = alu_result;
            end
            4'b0001: begin
                reg_read1_addr = instruction_reg[8:6];
                alu_opcode = 3'b0;
                if (state == 2'b10) reg_write_en = 1;
                else reg_write_en = 0;
                reg_write_addr = instruction_reg[11:9];
                reg_write_data = alu_result;
            end
        endcase
    end

    // Sequential Logic updating registers and FFs
    always @(posedge clk) begin

        if (initial_rst) begin
            instruction_reg <= 0;
            program_counter <= 0;
            state <= 0;
        end else begin
            case (state)
                // FETCH Phase
                2'b0: begin
                    instruction_reg <= u_rom_read_data;
                    state <= 2'b01; // go to decode phase
                end

                // DECODE Phase (reading registers, )
                2'b01: begin
                    case (opcode)
                        // R-type
                        4'b0: begin
                            alu_a <= reg_read1_data;
                            alu_b <= reg_read2_data;
                            state <= 2'b10;
                        end
                        4'b0001: begin
                            alu_a <= reg_read1_data;
                            alu_b <= {{2{instruction_reg[5]}}, {instruction_reg[5:0]}};  // imm6 padded to 8 bit
                            state <= 2'b10;
                        end
                    endcase
                end

                // EXECUTE_WB Phase
                2'b10: begin
                    case (opcode)
                        4'b0, 4'b0001: begin
                            state <= 2'b0;
                            program_counter <= program_counter + 1;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule



module rom (
    input  [ 5:0] rom_read_addr,
    output [15:0] rom_read_data
);

    // IMPORTANT: Finish actual memory contents later!

    reg [15:0] memcells[0:31];
    initial begin
        $readmemh("prog.hex", memcells);
    end


    assign rom_read_data = memcells[rom_read_addr];

endmodule
