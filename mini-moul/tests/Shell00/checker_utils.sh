#!/bin/bash
# Shared utilities for Shell00 checker scripts

GREEN='\033[38;5;84m'
RED='\033[38;5;197m'
GREY='\033[38;5;8m'
DEFAULT='\033[0m'
CHECKMARK='\xE2\x9C\x93'

_checker_errors=0
_checker_tc=0

check_pass() {
	_checker_tc=$((_checker_tc + 1))
	printf "  ${GREEN}${CHECKMARK}${GREY} [%d] %s${DEFAULT}\n" "$_checker_tc" "$1"
}

check_fail() {
	_checker_tc=$((_checker_tc + 1))
	printf "    ${RED}[%d] %s FAILED${DEFAULT}\n" "$_checker_tc" "$1"
	_checker_errors=$((_checker_errors + 1))
}

checker_exit() {
	exit $((_checker_errors > 0 ? 1 : 0))
}
