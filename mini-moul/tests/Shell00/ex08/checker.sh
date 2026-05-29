#!/bin/bash
# Shell00 ex08: Check file 'clean'
# Expected: single command that finds and deletes files ending with ~
#           or starting and ending with #, in current dir and subdirs

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/clean" ]; then
	check_pass "file 'clean' exists"
else
	check_fail "file 'clean' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Create test files
echo "temp" > "$tmpdir/file1~"
echo "temp" > "$tmpdir/backup~"
echo "temp" > "$tmpdir/#file1#"
echo "temp" > "$tmpdir/#backup#"
echo "normal" > "$tmpdir/normal.txt"
echo "code" > "$tmpdir/main.c"
mkdir -p "$tmpdir/subdir"
echo "temp" > "$tmpdir/subdir/nested~"
echo "temp" > "$tmpdir/subdir/#nested#"
echo "keep" > "$tmpdir/subdir/keep.txt"

# Run the clean command in temp directory
(cd "$tmpdir" && bash "$STUDENT_DIR/clean" >/dev/null 2>&1)

# Test 2: tilde files deleted in current directory
if [ ! -f "$tmpdir/file1~" ] && [ ! -f "$tmpdir/backup~" ]; then
	check_pass "tilde files (~) deleted in current directory"
else
	check_fail "tilde files (~) should be deleted"
fi

# Test 3: hash files deleted in current directory
if [ ! -f "$tmpdir/#file1#" ] && [ ! -f "$tmpdir/#backup#" ]; then
	check_pass "hash files (#...#) deleted in current directory"
else
	check_fail "hash files (#...#) should be deleted"
fi

# Test 4: normal files preserved
if [ -f "$tmpdir/normal.txt" ] && [ -f "$tmpdir/main.c" ]; then
	check_pass "normal files preserved"
else
	check_fail "normal files should not be deleted"
fi

# Test 5: tilde/hash files deleted in subdirectories (recursive)
if [ ! -f "$tmpdir/subdir/nested~" ] && [ ! -f "$tmpdir/subdir/#nested#" ]; then
	check_pass "tilde/hash files deleted in subdirectories"
else
	check_fail "tilde/hash files should be deleted in subdirectories too"
fi

# Test 6: normal files in subdirectories preserved
if [ -f "$tmpdir/subdir/keep.txt" ]; then
	check_pass "normal files in subdirectories preserved"
else
	check_fail "normal files in subdirectories should not be deleted"
fi

# Test 7: check it's a single command (no ; or && chaining)
content=$(cat "$STUDENT_DIR/clean")
if echo "$content" | grep -qE '[;&]{1,2}'; then
	check_fail "should be a single command (no ';' or '&&')"
else
	check_pass "single command (no chaining)"
fi

checker_exit
