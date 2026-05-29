#!/bin/bash
# Shell00 ex07: Check file 'b'
# Expected: file b such that diff a b matches sw.diff

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file b exists
if [ -f "$STUDENT_DIR/b" ]; then
	check_pass "file 'b' exists"
else
	check_fail "file 'b' not found"
	checker_exit
fi

# Reference files
ref_a="$CHECKER_DIR/a"
ref_diff="$CHECKER_DIR/sw.diff"

if [ ! -f "$ref_a" ]; then
	check_fail "reference file 'a' not found in test directory"
	checker_exit
fi

if [ ! -f "$ref_diff" ]; then
	check_fail "reference file 'sw.diff' not found in test directory"
	checker_exit
fi

# Test 2: diff a b matches expected sw.diff
actual_diff=$(diff "$ref_a" "$STUDENT_DIR/b" 2>/dev/null)
expected_diff=$(cat "$ref_diff" 2>/dev/null)

if [ "$actual_diff" = "$expected_diff" ]; then
	check_pass "'diff a b' matches expected sw.diff"
else
	check_fail "'diff a b' doesn't match expected sw.diff"
	# Show first few lines of diff for debugging
	printf "      ${GREY}Expected first line: %s${DEFAULT}\n" "$(echo "$expected_diff" | head -1)"
	printf "      ${GREY}Got first line:      %s${DEFAULT}\n" "$(echo "$actual_diff" | head -1)"
fi

# Test 3: applying patch to a produces b
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cp "$ref_a" "$tmpdir/a"
cp "$STUDENT_DIR/b" "$tmpdir/b"

# Generate patch and apply
(cd "$tmpdir" && diff a b > test.diff 2>/dev/null)
cp "$ref_a" "$tmpdir/a_patched"
patch -s "$tmpdir/a_patched" "$tmpdir/test.diff" 2>/dev/null

if diff -q "$tmpdir/a_patched" "$tmpdir/b" >/dev/null 2>&1; then
	check_pass "patch from diff can be applied correctly"
else
	check_fail "patch from diff cannot reproduce file 'b'"
fi

checker_exit
