#!/bin/bash
# Shell00 ex03: Check id_rsa_pub
# Expected: valid SSH public key file

STUDENT_DIR="$1"
CHECKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CHECKER_DIR/../checker_utils.sh"

# Test 1: file exists
if [ -f "$STUDENT_DIR/id_rsa_pub" ]; then
	check_pass "file 'id_rsa_pub' exists"
else
	check_fail "file 'id_rsa_pub' not found"
	checker_exit
fi

# Test 2: valid SSH public key format
first_word=$(head -1 "$STUDENT_DIR/id_rsa_pub" | awk '{print $1}')
case "$first_word" in
	ssh-rsa|ssh-ed25519|ssh-dss|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)
		check_pass "valid SSH public key format ($first_word)"
		;;
	*)
		check_fail "invalid SSH public key format (starts with '$first_word')"
		;;
esac

# Test 3: key data is present
key_data=$(head -1 "$STUDENT_DIR/id_rsa_pub" | awk '{print $2}')
if [ -n "$key_data" ] && [ ${#key_data} -gt 10 ]; then
	check_pass "key data present"
else
	check_fail "key data appears empty or too short"
fi

checker_exit
