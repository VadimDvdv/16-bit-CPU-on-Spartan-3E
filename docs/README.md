# 16-Bit ISA CPU in Verilog

A from-scratch processor: 16-bit instruction word, 8-bit datapath, 8 general-purpose
registers. Built alongside ECE 124 at UMass Amherst. Currently being brought up on a
Xilinx Spartan-3E FPGA.

## Architecture

Multi-cycle, Harvard. Four modules:

| Module | Function |
|---|---|
| `alu.v` | 8 ops (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR), carry/zero/sign/overflow flags |
| `regfile.v` | 8 x 8-bit, 2 read ports + 1 write port + 1 debug read port |
| `control_unit.v` | FSM, PC, instruction register |
| `rom` (in `control_unit.v`) | Instruction memory, addressed directly by PC |

### FSM

Three cycles per instruction (CPI = 3):

```
FETCH  ->  REG-READ  ->  EXEC+WB
latch IR   latch A, B    ALU computes, write rd, PC++
```

Two-process style: one clocked block for state and datapath registers, one
combinational block for control decode. R-type latches two register operands.
ADDI latches rs1 and a sign-extended imm6, then shares the same execute path.

`ALUOut` and the ALU input muxes are deferred until branches, where one ALU has to
serve both a comparison and a target computation.

## ISA

Three formats (R / I / J), 9 opcodes. Full encoding at the top of `rtl/control_unit.v`.
R-type and ADDI are implemented. LDI, LD/ST, branches, and JAL are next; the immediate
widths for LDI and JAL still need reconciling against the 8-bit datapath.

## FPGA bring-up

Target: Spartan-3E Starter Kit (XC3S500E, FG320, -4) under Xilinx ISE 14.7.

Three things had to change going from simulation to synthesis.

**Observability.** The testbench reads internal state through hierarchical references
(`uut.u_regfile.registers[i]`), which don't exist in synthesis. A third read port on the
register file routes up through the control unit to physical pins. Slide switches select
the register; the value shows on the 8 LEDs.

**Trimming.** The original top-level had no output ports, so synthesis would have deleted
the whole design as unobservable. The debug output anchors the full logic cone:
LEDs <- regfile <- ALU <- IR <- ROM <- PC <- FSM.

**Language strictness.** Icarus in SystemVerilog mode accepted things XST rejects:
variable declarations in unnamed blocks, and comments inside `$readmemh` data files.
Source is now Verilog-2001 clean.

## Status

- [x] ALU, register file, control unit (R-type datapath)
- [x] R-type verified in simulation
- [x] ADDI
- [x] Debug read port
- [x] Synthesizes clean under XST for XC3S500E
- [ ] Pin constraints (UCF)
- [ ] Clock enable divider. The program finishes in 360 ns at 50 MHz, too fast to watch
- [ ] Bitstream and board programming
- [ ] Single-step mode (debounced button drives the clock enable)
- [ ] Self-checking testbenches. Current benches drive stimulus and log; automatic
      pass/fail comparison is next
- [ ] Combinational defaults and a safe default state. An unhandled opcode currently
      wedges the FSM in REG-READ
- [ ] LDI, LD, ST, BEQ, BNE, BLT, JAL
- [ ] Data memory; `ALUOut` register and ALU input muxes for branches
- [ ] Halt state. The PC runs off the end of the program and executes empty ROM
- [ ] Assembler

## Layout

```
rtl/                 synthesizable design
  top.v              board wrapper: pins, clock divider
  control_unit.v     FSM and ROM
  alu.v
  regfile.v
tb/                  testbenches, simulation only
sim/                 build output, gitignored
constraints/         top.ucf
prog_annotated.hex   program source with encoding comments
prog.hex             generated, comment-free, gitignored
run.sh               regenerate prog.hex, compile, simulate
```

## Building

```bash
./run.sh r_type      # or alu, regfile, addi
```

Needs Icarus Verilog. `prog.hex` is regenerated from `prog_annotated.hex` on every run,
so edit the annotated file and never the generated one.

FPGA flow: ISE 14.7, XC3S500E-FG320-4.