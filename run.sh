#!/bin/bash
set -e
mkdir -p sim
iverilog -g2012 -o sim/$1_test rtl/*.v tb/$1_tb.v
vvp sim/$1_test