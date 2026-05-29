#!/bin/bash
# Shell00 ex04: Check midLS
# Expected: command that lists files/dirs, comma-separated, sorted by mtime,
#           dirs end with /, no hidden files

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/midLS" ]; then
	check_pass "file 'midLS' exists"
else
	check_fail "file 'midLS' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Create test environment with controlled modification times
mkdir "$tmpdir/dir_a"
echo "x" > "$tmpdir/file_b"
mkdir "$tmpdir/dir_c"
echo "y" > "$tmpdir/file_d"
echo "hidden" > "$tmpdir/.hidden_file"

# Set modification times (newest to oldest)
touch -t 202301050000 "$tmpdir/file_d"
touch -t 202301040000 "$tmpdir/dir_c"
touch -t 202301030000 "$tmpdir/file_b"
touch -t 202301020000 "$tmpdir/dir_a"
touch -t 202301010000 "$tmpdir/.hidden_file"

# Test 2: command runs successfully
output=$(cd "$tmpdir" && bash "$STUDENT_DIR/midLS" 2>/dev/null)
exit_code=$?
if [ $exit_code -eq 0 ] && [ -n "$output" ]; then
	check_pass "command runs successfully"
else
	check_fail "command failed to run (exit code: $exit_code)"
	checker_exit
fi

# Test 3: hidden files not shown
if echo "$output" | grep -q '\.hidden_file'; then
	check_fail "hidden files should not be displayed"
else
	check_pass "hidden files are excluded"
fi

# Test 4: directories end with /
if echo "$output" | grep -q 'dir_a/' && echo "$output" | grep -q 'dir_c/'; then
	check_pass "directories end with '/'"
else
	check_fail "directories should end with '/'"
fi

# Test 5: output is comma-separated
if echo "$output" | grep -q ', '; then
	check_pass "entries are separated by ', '"
else
	check_fail "entries should be separated by ', '"
fi

# Test 6: sorted by modification time (newest first)
# Normalize: remove newlines, split on comma, trim whitespace
normalized=$(echo "$output" | tr '\n' ' ' | sed 's/,  */\n/g' | sed 's/^ *//;s/ *$//')
first_entry=$(echo "$normalized" | head -1)
if [ "$first_entry" = "file_d" ]; then
	check_pass "sorted by modification time (newest first)"
else
	check_fail "expected 'file_d' first (newest), got '$first_entry'"
fi

# Test 7: all expected entries present
for entry in "file_d" "dir_c/" "file_b" "dir_a/"; do
	if echo "$output" | grep -q "$entry"; then
		:
	else
		check_fail "expected entry '$entry' not found in output"
	fi
done
check_pass "all expected entries present"

checker_exit
