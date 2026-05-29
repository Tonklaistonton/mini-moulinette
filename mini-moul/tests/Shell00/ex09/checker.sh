#!/bin/bash
# Shell00 ex09: Check ft_magic
# Expected: magic file that detects files with "42" at the 42nd byte as "42 file"

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/ft_magic" ]; then
	check_pass "file 'ft_magic' exists"
else
	check_fail "file 'ft_magic' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Create test file WITH "42" at byte 42 (offset 41, 0-indexed)
# 41 'A' bytes + "42" + 17 'B' bytes = 60 bytes total
dd if=/dev/zero bs=1 count=41 2>/dev/null | tr '\0' 'A' > "$tmpdir/testfile_42"
printf '42' >> "$tmpdir/testfile_42"
dd if=/dev/zero bs=1 count=17 2>/dev/null | tr '\0' 'B' >> "$tmpdir/testfile_42"

# Create test file WITHOUT "42" at byte 42
dd if=/dev/zero bs=1 count=60 2>/dev/null | tr '\0' 'A' > "$tmpdir/testfile_no42"

# Test 2: detects "42 file" when "42" is at byte 42
output=$(file -m "$STUDENT_DIR/ft_magic" "$tmpdir/testfile_42" 2>/dev/null)
if echo "$output" | grep -qi "42 file"; then
	check_pass "detects '42 file' when '42' is at byte 42"
else
	check_fail "should detect '42 file' when '42' is at byte 42"
	printf "      ${GREY}Got: %s${DEFAULT}\n" "$output"
fi

# Test 3: does NOT detect "42 file" for normal file
output2=$(file -m "$STUDENT_DIR/ft_magic" "$tmpdir/testfile_no42" 2>/dev/null)
if echo "$output2" | grep -qi "42 file"; then
	check_fail "should not detect '42 file' when '42' is not at byte 42"
else
	check_pass "correctly rejects file without '42' at byte 42"
fi

checker_exit
