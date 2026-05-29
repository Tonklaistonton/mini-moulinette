#!/bin/bash
# Shell00 ex00: Check file 'z'
# Expected: file z that outputs "Z" followed by newline when cat is used

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file z exists
if [ -f "$STUDENT_DIR/z" ]; then
	check_pass "file 'z' exists"
else
	check_fail "file 'z' not found"
	checker_exit
fi

# Test 2: cat z outputs "Z"
output=$(cat "$STUDENT_DIR/z")
if [ "$output" = "Z" ]; then
	check_pass "'cat z' outputs \"Z\""
else
	check_fail "Expected 'cat z' to output \"Z\", got \"$output\""
fi

# Test 3: file ends with newline
last_byte=$(tail -c 1 "$STUDENT_DIR/z" | xxd -p)
if [ "$last_byte" = "0a" ] || [ -z "$last_byte" ]; then
	check_pass "file ends with a newline"
else
	check_fail "file should end with a newline"
fi

checker_exit
