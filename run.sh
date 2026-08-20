#!/bin/bash
set -e
BENCH=$1
mkdir -p sim
if [ -f "programs/${BENCH}.hex" ]; then
    sed 's|//.*||' "programs/${BENCH}.hex" | grep -v '^[[:space:]]*$' > sim/prog.hex
else
    printf 'FFFF\n%.0s' {1..64} > sim/prog.hex   # alu_tb, regfile_tb: CPU unused
fi
iverilog -o sim/${BENCH}_test rtl/*.v tb/${BENCH}_tb.v
vvp sim/${BENCH}_test