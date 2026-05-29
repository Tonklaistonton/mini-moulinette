#!/bin/bash
# Shell00 ex06: Check git_ignore.sh
# Expected: script that lists all existing files ignored by git

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/git_ignore.sh" ]; then
	check_pass "file 'git_ignore.sh' exists"
else
	check_fail "file 'git_ignore.sh' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Create test git repo with .gitignore
(
	cd "$tmpdir" || exit 1
	git init -q
	git config user.email "test@test.com"
	git config user.name "Test"

	# Create .gitignore
	printf '*.o\n*.log\nbuild/\n' > .gitignore
	git add .gitignore
	git commit -q -m "Initial commit"

	# Create ignored files
	echo "obj" > test.o
	echo "log" > app.log
	mkdir -p build
	echo "bin" > build/output

	# Create tracked/normal files
	echo "normal" > test.txt
	git add test.txt
	git commit -q -m "Add normal file"
) >/dev/null 2>&1

# Get expected ignored files
expected=$(cd "$tmpdir" && git ls-files --others --ignored --exclude-standard | sort)

# Copy student script and run
cp "$STUDENT_DIR/git_ignore.sh" "$tmpdir/"
output=$(cd "$tmpdir" && bash git_ignore.sh 2>/dev/null | sort)

# Test 2: output matches expected ignored files
if [ "$output" = "$expected" ]; then
	check_pass "output matches expected ignored files"
else
	check_fail "output doesn't match expected ignored files"
	printf "      ${GREY}Expected: %s${DEFAULT}\n" "$(echo "$expected" | tr '\n' ', ')"
	printf "      ${GREY}Got:      %s${DEFAULT}\n" "$(echo "$output" | tr '\n' ', ')"
fi

# Test 3: output is not empty
if [ -n "$output" ]; then
	check_pass "output is not empty"
else
	check_fail "output should list ignored files"
fi

checker_exit
