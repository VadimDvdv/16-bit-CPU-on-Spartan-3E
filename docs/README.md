# 16-Bit ISA CPU in Verilog

A from-scratch processor in Verilog HDL - **16-bit instruction word, 8-bit datapath, 8 general-purpose registers** - built as a hands-on companion to ECE 124 (Digital & Computer Systems) at UMass Amherst.

## Architecture

A multi-cycle design built from four core modules:

- **ALU** - 8 operations (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR) with carry, zero, sign, and overflow flags
- **Register File** - 8 × 8-bit, two read ports and one write port
- **Control Unit** - multi-cycle FSM driving the fetch / decode / execute cycle
- **ROM** - instruction memory, Harvard-style (addressed directly by the PC, no address mux)

### Control-unit FSM

Each instruction executes in three cycles:

`FETCH` (latch IR) → `REG-READ` (latch operands A, B) → `EXEC+WB` (ALU computes, result written to `rd`, `PC++`)

Written in two-process style: one clocked block latches the state register and datapath registers; one combinational block decodes control signals. R-type latches two register operands into A/B; ADDI latches rs1 into A and a sign-extended `imm6` into B, then shares the same execute/writeback path. `ALUOut` and ALU input muxes are intentionally deferred - they come in with branches, when a single ALU must serve both a comparison and a target computation.

## ISA

16-bit instruction word, three formats (R / I / J), 9 opcodes. The full encoding lives at the top of `control_unit.v`. **R-type and ADDI are implemented and simulating**; `LDI`, `LD`/`ST`, branches, and `JAL` are next. (Immediate widths for `LDI`/`JAL` still need reconciling against the 8-bit datapath.)

## Status

- [x] ALU + testbench
- [x] Register file + testbench
- [x] Control unit - R-type datapath (multi-cycle FSM)
- [x] R-type simulation & waveform verification - all 8 registers PASS in self-checking testbench
- [x] ADDI - immediate add with sign-extended `imm6`
- [ ] Combinational-block defaults + safe default state transition (an unhandled/unknown opcode currently wedges the FSM in REG-READ)
- [ ] Remaining instructions: LDI, LD, ST, BEQ, BNE, BLT, JAL
- [ ] Data memory for LD/ST; `ALUOut` register + ALU input muxes for branches
- [ ] Assembler; run a stored program from ROM
- [ ] Synthesize and run on the Xilinx Spartan-3E Starter Kit

## Tools

- **Simulation:** Icarus Verilog + GTKWave
- **FPGA target:** Xilinx Spartan-3E Starter Kit (ISE toolchain)

## Running

```bash
# ALU
iverilog -o alu_test alu.v alu_tb.v && vvp alu_test && gtkwave alu_test.vcd

# Register file
iverilog -o rf_test regfile.v regfile_tb.v && vvp rf_test

# Full CPU (R-type + ADDI test program in prog.hex)
iverilog -o r_type_test control_unit.v alu.v regfile.v r_type_tb.v
vvp r_type_test
gtkwave cpu_test.vcd
```