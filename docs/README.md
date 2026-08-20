# 16-Bit ISA CPU in Verilog

A from-scratch processor: 16-bit instruction word, 8-bit datapath, 8 general-purpose
registers. Built alongside ECE 124 at UMass Amherst. Runs on a Xilinx Spartan-3E
Starter Kit, verified on the board by reading the register file back through a debug
port to the LEDs.

## Architecture

Multi-cycle, Harvard. Five modules:

| Module | Function |
|---|---|
| `top.v` | Board wrapper: clock, reset, slide switches, LEDs |
| `control_unit.v` | FSM, PC, instruction register, decode |
| `alu.v` | 8 ops (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR), carry/zero/sign/overflow flags |
| `regfile.v` | 8 x 8-bit, 2 read ports + 1 write port + 1 debug read port |
| `rom.v` | Instruction memory, addressed directly by PC, initialized from a hex file |

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

An opcode the FSM does not recognize leaves `state` unassigned in REG-READ, so the
machine stops there. Programs end with a pad of `FFFF` words and rely on this. It
works, but it is a consequence of an incomplete `case` rather than a design decision;
an explicit HALT state is on the list below.

## ISA

16-bit instruction word, 8-bit datapath, 8 registers R0-R7. R0 is a normal
general-purpose register, not hardwired to zero.

### Formats

```
R  [15:12]=0000  [11:9]=rd  [8:6]=rs1  [5:3]=rs2  [2:0]=func
I  [15:12]=op    [11:9]=rd  [8:6]=rs1  [5:0]=imm6 (signed)
J  [15:12]=op    [11:9]=rd  [8:0]=imm9 (signed)
```

### Opcodes

| Opcode | Mnemonic | Operation | Status |
|---|---|---|---|
| `0000` | R-type | ALU op selected by `func` | done |
| `0001` | ADDI | `rd = rs1 + sext(imm6)` | done |
| `0010` | LDI | `rd = sext(imm9)` | todo |
| `0011` | LD | `rd = MEM[rs1 + imm6]` | todo |
| `0100` | ST | `MEM[rs1 + imm6] = rd` | todo |
| `0101` | BEQ | `if rs1 == rs2: PC += imm6` | todo |
| `0110` | BNE | `if rs1 != rs2: PC += imm6` | todo |
| `0111` | BLT | `if rs1 < rs2: PC += imm6` | todo |
| `1000` | JAL | `rd = PC + 1; PC += imm9` | todo |

Opcodes `1001`-`1111` are unassigned. `1111` is used as the program pad.

The immediate widths for LDI and JAL still need reconciling against the 8-bit
datapath: `imm9` does not fit in a register.

### R-type func field

`func[2:0]` is fed straight to the ALU opcode, so the two encodings are the same.

| func | Op | Operation |
|---|---|---|
| `000` | ADD | `rs1 + rs2` |
| `001` | SUB | `rs1 - rs2` |
| `010` | AND | `rs1 & rs2` |
| `011` | OR | `rs1 \| rs2` |
| `100` | XOR | `rs1 ^ rs2` |
| `101` | NOT | `~rs1` (rs2 ignored) |
| `110` | SHL | `rs1 << 1` (rs2 ignored, logical) |
| `111` | SHR | `rs1 >> 1` (rs2 ignored, logical) |

Flags are `{overflow, sign, carry, zero}`. Carry and overflow are meaningful only for
ADD and SUB and are forced to 0 for the logical and shift ops.

## Programs

A program is 64 hex words, one per ROM cell, written with `//` comments in
`programs/`. `run.sh` strips the comments into `sim/prog.hex` before compiling,
because XST does not accept comments inside a `$readmemh` data file even though
Icarus does. Edit the annotated file in `programs/`, never the generated one.

| Program | Purpose |
|---|---|
| `programs/r_type.hex` | All 8 ALU ops through the datapath. Needs R1 and R2 seeded, so it is simulation-only |
| `programs/addi.hex` | Self-seeding via `ADDI R0, R0, #15`, then negative immediates, `rd == rs1`, signed max, and the `0x7F + 1` wrap boundary. Runs on the board |

Both pad to 64 words with `FFFF`.

The ROM filename is a parameter, defaulted to `prog.hex` and forwarded down through
`top` and `control_unit`:

```verilog
control_unit #(.PROG_FILE("sim/prog.hex")) uut (...);
```

Testbenches override it with a repo-relative path. Synthesis takes the default, which
is why the default has no directory component: XST resolves the parameter to a
constant string and opens the file relative to the ISE project directory.

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

### Results

Place and route completed with all signals routed and all timing constraints met.

| | Used | Available | % |
|---|---|---|---|
| Slice flip-flops | 88 | 9,312 | 1% |
| 4-input LUTs | 213 | 9,312 | 2% |
| Occupied slices | 140 | 4,656 | 3% |
| Block RAM (RAMB16) | 1 | 20 | 5% |
| Bonded IOBs | 13 | 232 | 5% |
| BUFGMUX | 1 | 24 | 4% |

The 88 flip-flops account for exactly the register file (64), the two ALU input
registers (16), the PC (6), and the state register (2). The 16-bit instruction
register costs nothing: XST absorbed it into the block RAM output register, which is
why the critical path starts at the RAMB16 output.

Timing, post-place-and-route, `-4` speed grade at the 85 C / 1.14 V corner:

```
constraint         20.000 ns  (50 MHz board oscillator)
worst setup slack   5.926 ns
worst hold slack    1.219 ns
minimum period     14.074 ns  ->  71.053 MHz
paths analyzed      8,649        0 failing endpoints
```

The critical path is decode-to-register-read: RAMB16 output (the IR) -> opcode
decode -> `reg_read2_addr` -> register file read mux -> `alu_b` input register. Four
levels of logic, 6.119 ns of logic against 7.955 ns of routing, so it is 56% wire.
The two dominant segments are 4.117 ns on `reg_read2_addr<2>` and 2.223 ns on
`reg_read2_data<4>`.

### On the board

`programs/addi.hex` loads, runs, and stops on the `FFFF` pad. The program finishes in
under a microsecond at 50 MHz, so there is nothing to watch while it runs; the result
is read afterwards by selecting a register on the slide switches and reading the
8 LEDs.

Pin assignments are in `top.ucf`, taken from UG230: `clk` on the 50 MHz oscillator
(C9), reset on SW3 (N17), register select on SW0-SW2, and the 8 LEDs.

## Verification

`./run.sh <bench>` regenerates the program, compiles, and simulates.

| Bench | Level |
|---|---|
| `r_type_tb` | Self-checking. Runs all 8 ALU ops and compares the full register file against expected values |
| `alu_tb` | Directed stimulus with logged output, 12 vectors, no automatic comparison |
| `regfile_tb` | Directed stimulus with logged output, no automatic comparison |
| `addi_tb` | In progress. Golden model derived from the ISA spec rather than from the RTL |

`r_type_tb` still seeds R1 and R2 through a hierarchical reference and reads results
through the register file array rather than through the debug port. Both should move
to the port level, so that a passing simulation is evidence about the same read path
the board uses.

## Status

- [x] ALU, register file, control unit (R-type datapath)
- [x] ADDI
- [x] Debug read port
- [x] Synthesizes clean under XST for XC3S500E
- [x] Pin constraints (`top.ucf`)
- [x] Bitstream and board programming
- [x] Running on hardware, verified by register readback on the LEDs
- [x] Self-checking testbench for the R-type program
- [ ] Self-checking testbench for ADDI
- [ ] Port-level checking in `r_type_tb`; drop the hierarchical seed and peek
- [ ] Explicit HALT state instead of relying on an unassigned `state` in REG-READ
- [ ] Clock enable divider and single-step mode (debounced button drives the enable)
- [ ] LDI, LD, ST, BEQ, BNE, BLT, JAL
- [ ] Data memory; `ALUOut` register and ALU input muxes for branches
- [ ] Assembler

## Layout

```
rtl/                 synthesizable design
  top.v              board wrapper: pins
  control_unit.v     FSM, PC, IR, decode
  rom.v              instruction memory
  alu.v
  regfile.v
tb/                  testbenches, simulation only
programs/            program sources with encoding comments
  r_type.hex
  addi.hex
sim/                 build output and generated prog.hex, gitignored
top.ucf              pin constraints
run.sh               regenerate the program, compile, simulate
```

## Building

```bash
./run.sh r_type      # or alu, regfile, addi
```

Needs Icarus Verilog. The bench name selects the program: `run.sh addi` uses
`programs/addi.hex`. Benches that do not instantiate the CPU get a ROM filled with
`FFFF` rather than an empty file, because a partially initialized memory is what made
XST discard the ROM and trim the whole design once already.

FPGA flow: ISE 14.7, XC3S500E-FG320-4. The repo and the ISE project directory are
separate copies; only the RTL, `top.ucf`, and a generated `prog.hex` are needed on the
ISE side.