#!/bin/bash
# Shell00 ex02: Check exo2.tar
# Expected: tar with specific files/dirs matching exact permissions, sizes, types

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: tar file exists
if [ -f "$STUDENT_DIR/exo2.tar" ]; then
	check_pass "file 'exo2.tar' exists"
else
	check_fail "file 'exo2.tar' not found"
	checker_exit
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tar -xf "$STUDENT_DIR/exo2.tar" -C "$tmpdir" 2>/dev/null

check_entry() {
	local name="$1"
	local expected_type="$2"
	local expected_perms="$3"
	local path="$tmpdir/$name"

	if [ ! -e "$path" ] && [ ! -L "$path" ]; then
		check_fail "'$name' not found in archive"
		return
	fi

	if [ "$expected_type" = "l" ]; then
		if [ -L "$path" ]; then
			check_pass "'$name' is a symbolic link"
		else
			check_fail "'$name' should be a symbolic link"
		fi
		return
	fi

	local actual_perms
	actual_perms=$(stat -c '%A' "$path" 2>/dev/null)

	if [ "$expected_type" = "d" ]; then
		if [ -d "$path" ]; then
			if [ "$actual_perms" = "$expected_perms" ]; then
				check_pass "'$name' is directory with permissions $expected_perms"
			else
				check_fail "'$name' expected permissions '$expected_perms', got '$actual_perms'"
			fi
		else
			check_fail "'$name' should be a directory"
		fi
	elif [ "$expected_type" = "f" ]; then
		if [ -f "$path" ]; then
			if [ "$actual_perms" = "$expected_perms" ]; then
				check_pass "'$name' is file with permissions $expected_perms"
			else
				check_fail "'$name' expected permissions '$expected_perms', got '$actual_perms'"
			fi
		else
			check_fail "'$name' should be a regular file"
		fi
	fi
}

# drwx--xr-x 2 XX XX XX Jun 1 20:47 test0
check_entry "test0" "d" "drwx--xr-x"

# -rwx--xr-- 1 XX XX 4 Jun 1 21:46 test1
check_entry "test1" "f" "-rwx--xr--"

# dr-x---r-- 2 XX XX XX Jun 1 22:45 test2
check_entry "test2" "d" "dr-x---r--"

# -r-----r-- 2 XX XX 1 Jun 1 23:44 test3
check_entry "test3" "f" "-r-----r--"

# -rw-r----x 1 XX XX 2 Jun 1 23:43 test4
check_entry "test4" "f" "-rw-r----x"

# -r-----r-- 2 XX XX 1 Jun 1 23:44 test5
check_entry "test5" "f" "-r-----r--"

# lrwxrwxrwx 1 XX XX 5 Jun 1 22:20 test6 -> test0
check_entry "test6" "l" ""

# Check sizes
size=$(stat -c '%s' "$tmpdir/test1" 2>/dev/null)
if [ "$size" = "4" ]; then
	check_pass "'test1' size is 4 bytes"
else
	check_fail "'test1' expected size 4, got $size"
fi

size=$(stat -c '%s' "$tmpdir/test3" 2>/dev/null)
if [ "$size" = "1" ]; then
	check_pass "'test3' size is 1 byte"
else
	check_fail "'test3' expected size 1, got $size"
fi

size=$(stat -c '%s' "$tmpdir/test4" 2>/dev/null)
if [ "$size" = "2" ]; then
	check_pass "'test4' size is 2 bytes"
else
	check_fail "'test4' expected size 2, got $size"
fi

# Check hardlinks: test3 and test5 should have 2 hardlinks and share inode
hardlinks=$(stat -c '%h' "$tmpdir/test3" 2>/dev/null)
if [ "$hardlinks" = "2" ]; then
	check_pass "'test3' has 2 hardlinks"
else
	check_fail "'test3' expected 2 hardlinks, got $hardlinks"
fi

hardlinks=$(stat -c '%h' "$tmpdir/test5" 2>/dev/null)
if [ "$hardlinks" = "2" ]; then
	check_pass "'test5' has 2 hardlinks"
else
	check_fail "'test5' expected 2 hardlinks, got $hardlinks"
fi

inode3=$(stat -c '%i' "$tmpdir/test3" 2>/dev/null)
inode5=$(stat -c '%i' "$tmpdir/test5" 2>/dev/null)
if [ "$inode3" = "$inode5" ]; then
	check_pass "'test3' and 'test5' share same inode (hardlink)"
else
	check_fail "'test3' and 'test5' should share same inode"
fi

# Check test6 symlink target
if [ -L "$tmpdir/test6" ]; then
	target=$(readlink "$tmpdir/test6")
	if [ "$target" = "test0" ]; then
		check_pass "'test6' -> 'test0'"
	else
		check_fail "'test6' should link to 'test0', links to '$target'"
	fi
fi

checker_exit
