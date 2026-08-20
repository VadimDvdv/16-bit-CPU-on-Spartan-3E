#!/bin/bash
# Usage:  ./run.sh <bench>   e.g. ./run.sh addi
#         ./run.sh all       run every bench, fail if any fails
set -eu

BENCHES="alu regfile r_type addi"

run_one () {
    BENCH=$1
    mkdir -p sim

    # The program of the same name, comments stripped. Benches that do not
    # instantiate the CPU still need a fully initialized ROM: a short or missing
    # file leaves memcells at X, which is the condition that made XST discard the
    # ROM and trim the design.
    if [ -f "programs/${BENCH}.hex" ]; then
        sed 's|//.*||' "programs/${BENCH}.hex" | grep -v '^[[:space:]]*$' > sim/prog.hex
    else
        printf 'FFFF\n%.0s' {1..64} > sim/prog.hex
    fi

    if ! iverilog -s "${BENCH}_tb" -o "sim/${BENCH}_test" rtl/*.v "tb/${BENCH}_tb.v"; then
        echo "== ${BENCH}: BUILD FAILED"
        return 1
    fi

    set +e
    vvp "sim/${BENCH}_test" | tee "sim/${BENCH}.log"
    vvp_status=${PIPESTATUS[0]}
    set -e

    if [ "$vvp_status" -ne 0 ]; then
        echo "== ${BENCH}: simulator exited ${vvp_status}"
        return 1
    fi
    if grep -qE '^(TESTS FAILED|ERROR:)' "sim/${BENCH}.log"; then
        echo "== ${BENCH}: FAILED"
        return 1
    fi
    if ! grep -q 'TESTS PASSED' "sim/${BENCH}.log"; then
        echo "== ${BENCH}: NO VERDICT (bench prints no pass/fail line)"
        return 1
    fi
    echo "== ${BENCH}: PASSED"
    return 0
}

if [ "${1:-}" = "" ]; then
    echo "usage: $0 <bench|all>   (benches: ${BENCHES})" >&2
    exit 2
fi

if [ "$1" = "all" ]; then
    rc=0
    for b in $BENCHES; do
        run_one "$b" || rc=1
        echo
    done
    [ "$rc" -eq 0 ] && echo "REGRESSION PASSED" || echo "REGRESSION FAILED"
    exit "$rc"
fi

run_one "$1"