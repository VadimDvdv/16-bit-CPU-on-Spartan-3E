#!/bin/bash
set -e
mkdir -p sim
grep -v '^//' prog_annotated.hex | grep -v '^$' > prog.hex
iverilog -o sim/$1_test rtl/*.v tb/$1_tb.v
vvp sim/$1_test