#!/bin/bash
# Shell00 ex01: Check testShell00.tar
# Expected: tar containing testShell00 with permissions -r--r-xr-x and size 40

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: tar file exists
if [ -f "$STUDENT_DIR/testShell00.tar" ]; then
	check_pass "file 'testShell00.tar' exists"
else
	check_fail "file 'testShell00.tar' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tar -xf "$STUDENT_DIR/testShell00.tar" -C "$tmpdir" 2>/dev/null

# Test 2: testShell00 exists in archive
if [ -f "$tmpdir/testShell00" ]; then
	check_pass "'testShell00' found in archive"
else
	check_fail "'testShell00' not found in archive"
	checker_exit
fi

# Test 3: permissions are -r--r-xr-x
perms=$(stat -c '%A' "$tmpdir/testShell00" 2>/dev/null)
expected_perms="-r--r-xr-x"
if [ "$perms" = "$expected_perms" ]; then
	check_pass "permissions are $expected_perms"
else
	check_fail "Expected permissions '$expected_perms', got '$perms'"
fi

# Test 4: size is 40 bytes
size=$(stat -c '%s' "$tmpdir/testShell00" 2>/dev/null)
if [ "$size" = "40" ]; then
	check_pass "file size is 40 bytes"
else
	check_fail "Expected size 40 bytes, got $size bytes"
fi

checker_exit
