# 16-Bit ISA CPU in Verilog

A from-scratch processor in Verilog HDL — **16-bit instruction word, 8-bit datapath, 8 general-purpose registers** — built as a hands-on companion to ECE 124 (Digital & Computer Systems) at UMass Amherst. Currently being brought up on a Xilinx Spartan-3E FPGA.

## Architecture

A multi-cycle design built from four core modules:

- **ALU** — 8 operations (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR) with carry, zero, sign, and overflow flags
- **Register File** — 8 × 8-bit, two read ports and one write port, plus a third read-only debug port for hardware observation
- **Control Unit** — multi-cycle FSM driving the fetch / decode / execute cycle
- **ROM** — instruction memory, Harvard-style (addressed directly by the PC, no address mux)

### Control-unit FSM

Each instruction executes in three cycles (CPI = 3):

`FETCH` (latch IR) → `REG-READ` (latch operands A, B) → `EXEC+WB` (ALU computes, result written to `rd`, `PC++`)

Written in two-process style: one clocked block latches the state register and datapath registers; one combinational block decodes control signals. R-type latches two register operands into A/B; ADDI latches rs1 into A and a sign-extended `imm6` into B, then shares the same execute/writeback path. `ALUOut` and ALU input muxes are intentionally deferred — they come in with branches, when a single ALU must serve both a comparison and a target computation.

## ISA

16-bit instruction word, three formats (R / I / J), 9 opcodes. The full encoding lives at the top of `rtl/control_unit.v`. **R-type and ADDI are implemented and simulating**; `LDI`, `LD`/`ST`, branches, and `JAL` are next. (Immediate widths for `LDI`/`JAL` still need reconciling against the 8-bit datapath.)

## FPGA bring-up

The design is being ported to a **Spartan-3E Starter Kit (XC3S500E, FG320, -4)** using Xilinx ISE 14.7.

Moving from simulation to silicon required design changes, not just a toolchain change:

- **Observability.** The simulation testbench reads internal state through hierarchical references (`uut.u_regfile.registers[i]`), which do not exist in synthesis. A third read port was added to the register file and routed up through the control unit so register contents can reach physical pins. Board slide switches select which register to display; the value appears on the 8 LEDs.
- **Trimming.** The original top-level module had no output ports, so synthesis would have removed the entire design as unobservable. The debug output anchors the full logic cone: LEDs ← regfile ← ALU ← IR ← ROM ← PC ← FSM.
- **Language strictness.** Icarus Verilog in SystemVerilog mode accepted constructs that XST (Verilog-2001) rejects — variable declarations in unnamed blocks, and comments in `$readmemh` data files. Source is now Verilog-2001 clean.

### Status

- [x] Synthesizes cleanly under XST for XC3S500E
- [ ] Pin constraints (UCF)
- [ ] Clock enable divider — the program completes in 360 ns at 50 MHz, far too fast to observe
- [ ] Bitstream generation and board programming
- [ ] Single-step mode (debounced pushbutton drives the clock enable)

## Status

- [x] ALU + testbench
- [x] Register file + testbench
- [x] Control unit — R-type datapath (multi-cycle FSM)
- [x] R-type simulation & waveform verification
- [x] ADDI — immediate add with sign-extended `imm6`
- [x] Debug read port for FPGA observability
- [x] XST synthesis clean
- [ ] Self-checking testbenches (current benches drive stimulus and log; automatic pass/fail comparison is next)
- [ ] Combinational-block defaults + safe default state transition (an unhandled opcode currently wedges the FSM in REG-READ)
- [ ] Remaining instructions: LDI, LD, ST, BEQ, BNE, BLT, JAL
- [ ] Data memory for LD/ST; `ALUOut` register + ALU input muxes for branches
- [ ] Halt state — the PC currently runs off the end of the program and executes empty ROM
- [ ] Assembler

## Repository layout