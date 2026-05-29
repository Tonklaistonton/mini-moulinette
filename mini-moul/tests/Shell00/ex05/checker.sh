#!/bin/bash
# Shell00 ex05: Check git_commit.sh
# Expected: script that displays the ids of the last 5 commits

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/git_commit.sh" ]; then
	check_pass "file 'git_commit.sh' exists"
else
	check_fail "file 'git_commit.sh' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Create test git repo with 7 commits
(
	cd "$tmpdir" || exit 1
	git init -q
	git config user.email "test@test.com"
	git config user.name "Test"
	for i in 1 2 3 4 5 6 7; do
		echo "commit $i" > file.txt
		git add file.txt
		git commit -q -m "Commit $i"
	done
) >/dev/null 2>&1

# Get expected output (last 5 commit hashes)
expected=$(cd "$tmpdir" && git log --format='%H' -5)

# Copy student script to repo and run
cp "$STUDENT_DIR/git_commit.sh" "$tmpdir/"
output=$(cd "$tmpdir" && bash git_commit.sh 2>/dev/null)

# Test 2: output matches expected commit hashes
if [ "$output" = "$expected" ]; then
	check_pass "output matches expected commit hashes"
else
	check_fail "output doesn't match expected commit hashes"
	exp_first=$(echo "$expected" | head -1)
	got_first=$(echo "$output" | head -1)
	printf "      ${GREY}Expected first: %s${DEFAULT}\n" "$exp_first"
	printf "      ${GREY}Got first:      %s${DEFAULT}\n" "$got_first"
fi

# Test 3: exactly 5 lines
line_count=$(echo "$output" | wc -l)
if [ "$line_count" -eq 5 ]; then
	check_pass "output has exactly 5 commit hashes"
else
	check_fail "expected 5 lines, got $line_count"
fi

# Test 4: each line is a valid SHA1 hash (40 hex chars)
all_valid=1
while IFS= read -r line; do
	if ! echo "$line" | grep -qE '^[0-9a-f]{40}$'; then
		all_valid=0
		break
	fi
done <<< "$output"
if [ $all_valid -eq 1 ]; then
	check_pass "all lines are valid SHA1 hashes"
else
	check_fail "some lines are not valid SHA1 hashes"
fi

checker_exit
