#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/config.sh"

#utils
index=0
index2=0
assignment_data=NULL
test_data=NULL
test_error=NULL
test_name=NULL

#variables
checks=0
passed=0
marks=0
questions=0
norminette_passed=0
norminette_failed=0
norminette_skipped=0
dirname_found=0
break_score=0
score_false=0
available_assignments=""
result=""
dirname_found=0
student_root=""
workspace_root=""
tests_root=""
test_timeout=5

get_compilation_flags() {
  case "$1" in
  C06 | C07 | C08)
    echo "-Wall -Wextra -Werror -std=c99"
    ;;
  *)
    echo "-Wall -Wextra -Werror"
    ;;
  esac
}

get_version_label() {
  local repo_root
  local commit

  repo_root=$(cd -- "$SCRIPT_DIR/.." 2>/dev/null && pwd)
  commit=$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null)

  if [ -n "$commit" ]; then
    printf '%s' "$commit"
  else
    printf 'unknown'
  fi
}

run_norminette() {
  local root="$1"
  local file
  local output
  local relative_path
  local found=0

  if ! command -v norminette >/dev/null 2>&1; then
    printf "${GREY}norminette not found, skipping norminette checks.${DEFAULT}\n"
    norminette_skipped=1
    space
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    found=1
    relative_path="${file#"$root"/}"
    output=$(norminette "$file" 2>&1)
    if [ $? -eq 0 ]; then
      norminette_passed=$((norminette_passed + 1))
      printf "${GREEN}NORMINETTE PASS${DEFAULT} ${PURPLE}%s${DEFAULT}\n" "$relative_path"
    else
      norminette_failed=$((norminette_failed + 1))
      printf "${RED}NORMINETTE FAIL${DEFAULT} ${PURPLE}%s${DEFAULT}\n" "$relative_path"
      if [ -n "$output" ]; then
        printf "%s\n" "$output" | sed 's/^/    /'
      fi
    fi
  done < <(find "$root" -type f \( -name '*.c' -o -name '*.h' \))

  if [ $found -eq 0 ]; then
    printf "${GREY}No source files found for norminette.${DEFAULT}\n"
  fi
  space
}

prepare_workspace() {
  local source_root="$1"
  local target_root="$2"
  local entry

  mkdir -p "$target_root"
  cp -R "$SCRIPT_DIR" "$target_root/mini-moul"

  for entry in "$source_root"/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ]; then
      case "$(basename "$entry")" in
      ex[0-9][0-9])
        ln -s "$entry" "$target_root/$(basename "$entry")"
        ;;
      esac
    fi
  done
}

cleanup_workspace() {
  [ -n "$workspace_root" ] && rm -rf "$workspace_root"
}

run_test_binary() {
  local timeout_marker
  local watchdog_pid
  local pid
  local status

  timeout_marker=$(mktemp "/tmp/mini-moul.timeout.XXXXXX") || return 1
  rm -f "$timeout_marker"

  "$@" &
  pid=$!
  (
    sleep "$test_timeout"
    if kill -0 "$pid" 2>/dev/null; then
      : >"$timeout_marker"
      kill -TERM "$pid" 2>/dev/null
      sleep 1
      kill -KILL "$pid" 2>/dev/null
    fi
  ) &
  watchdog_pid=$!

  wait "$pid"
  status=$?
  kill "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null

  if [ -e "$timeout_marker" ]; then
    rm -f "$timeout_marker"
    return 124
  fi

  rm -f "$timeout_marker"
  return "$status"
}

main() {
  project_name="$1"
  student_root="$2"
  start_time=$(date +%s)
  read -r -a compile_flags <<<"$(get_compilation_flags "$project_name")"
  print_header
  run_norminette "$student_root"

  workspace_root=$(mktemp -d "/tmp/mini-moul.XXXXXX")
  prepare_workspace "$student_root" "$workspace_root"
  tests_root="$workspace_root/mini-moul/tests"
  trap cleanup_workspace EXIT INT TERM

  for dir in "$tests_root"/*; do
    dirname="$(basename "$dir")"
    available_assignments+="$dirname "

    if [ -d "$dir" ] && [ "$dirname" == "$project_name" ]; then
      dirname_found=1
      printf "${GREEN} Generating test for ${project_name}...\n${DEFAULT}"
      space
      dirname_found=1
      index=0

      for assignment in "$dir"/*; do
        questions=$((questions + 1))
        score_false=0
        assignment_name="$(basename "$assignment")"
        test_source=$(find "$assignment" -maxdepth 1 -type f -name '*.c' | sort | head -n 1)

        if [ -z "$test_source" ]; then
          break_score=1
          checks=$((checks + 1))
          printf "${RED}    $assignment_name does not contain a test file.${DEFAULT}\n"
          space
          if [ $index -gt 0 ]; then
            result+=", "
          fi
          result+="${RED}$assignment_name: KO${DEFAULT}"
          ((index++))
          continue
        fi

        test_name="$(basename "$test_source")"
        student_file="$workspace_root/$assignment_name/$test_name"

        if [ ! -f "$student_file" ]; then
          break_score=1
          checks=$((checks + 1))
          printf "${GREY}    $assignment_name/$test_name not turned in.${DEFAULT}\n"
          printf "${GREY}${BOLD} not turned in ${DEFAULT}${PURPLE} $assignment_name/${DEFAULT}$test_name\n"
          space

          if [ $index -gt 0 ]; then
            result+=", "
          fi
          result+="${GREY}$assignment_name: not turned in${DEFAULT}"
        elif cc "${compile_flags[@]}" -o test1 "$test_source"; then
          rm test1
          checks=$((checks + 1))
          passed=$((passed + 1))

          if [ -d "$assignment" ]; then
            index2=0

            for test in "$assignment"/*.c; do
              ((index2++))
              checks=$((checks + 1))

              test_bin="${test%.c}"
              if cc "${compile_flags[@]}" -o "$test_bin" "$test" 2>/dev/null; then

                if run_test_binary "$test_bin"; then
                  passed=$((passed + 1))
                else
                  status=$?
                  break_score=1
                  score_false=1
                  case "$status" in
                  124) test_error="timed out" ;;
                  139) test_error="segmentation fault" ;;
                  134) test_error="aborted" ;;
                  *) test_error="exited with status $status" ;;
                  esac
                  printf "    ""${GREY}[$(($index2 + 1))] $test_error ${RED}FAILED${DEFAULT}\n"
                fi
                rm -f "$test_bin"
              else
                printf "    ""${GREY}[$(($index2 + 1))] $test_error ${RED}FAILED${DEFAULT}\n"
              fi
            done
            print_test_result
            space
          else
            printf "${RED}    $assignment_name does not exist.${DEFAULT}\n"
          fi
        else
          break_score=1
          checks=$((checks + 1))
          printf "${RED}    $test_name cannot compile.${DEFAULT}\n"
          printf "${BG_RED}${BOLD} FAIL ${DEFAULT}${PURPLE} $assignment_name/${DEFAULT}$test_name\n"
          space

          if [ $index -gt 0 ]; then
            result+=", "
          fi
          result+="${RED}$assignment_name: KO${DEFAULT}"
        fi
        ((index++))
      done
      break
    fi
  done

  if [ $dirname_found = 0 ]; then
    printf "${RED}Sorry. Tests for $1 isn't available yet. Consider contributing at Github.${DEFAULT}\n"
    printf "Available assignment tests: ${PURPLE}$available_assignments${DEFAULT}\n"
    exit 1
  fi
  print_footer
}

print_header() {
  space
  printf "\033[38;5;39m%s${DEFAULT}\n" " ███▄ ▄███▓ ██▓ ███▄    █  ██▓"
  printf "\033[38;5;45m%s${DEFAULT}\n" "▓██▒▀█▀ ██▒▓██▒ ██ ▀█   █ ▓██▒"
  printf "\033[38;5;51m%s${DEFAULT}\n" "▓██    ▓██░▒██▒▓██  ▀█ ██▒▒██▒"
  printf "\033[38;5;87m%s${DEFAULT}\n" "▒██    ▒██ ░██░▓██▒  ▐▌██▒░██░"
  printf "\033[38;5;123m%s${DEFAULT}\n" "▒██▒   ░██▒░██░▒██░   ▓██░░██░"
  printf "\033[38;5;159m%s${DEFAULT}\n" "░ ▒░   ░  ░░▓  ░ ▒░   ▒ ▒ ░▓  "
  printf "\033[38;5;195m%s${DEFAULT}\n" "░  ░      ░ ▒ ░░ ░░   ░ ▒░ ▒ ░"
  printf "\033[38;5;219m%s${DEFAULT}\n" "░      ░    ▒ ░   ░   ░ ░  ▒ ░"
  printf "\033[38;5;213m%s${DEFAULT}\n" "       ░    ░           ░  ░  "
  printf "${BLUE}Mini moulinette (Forked by koharu-u) ${DEFAULT}commit %s\n" "$(get_version_label)"
  space
}

print_collected_files() {
  printf "Collected files:\n"
  ls ../* | grep -v "../41test:*" | grep -v "../41test" | column
}

space() {
  printf "\n"
}

print_test_result() {
  if [ $index -gt 0 ]; then
    result+=", "
  fi
  if [ $score_false = 0 ]; then
    result+="${GREEN}$assignment_name: OK${DEFAULT}"
    printf "${BG_GREEN}${BLACK}${BOLD} PASS ${DEFAULT}${PURPLE} $assignment_name/${DEFAULT}$test_name\n"
  else
    result+="${RED}$assignment_name: KO${DEFAULT}"
    printf "${BG_RED}${BOLD} FAIL ${DEFAULT}${PURPLE} $assignment_name/${DEFAULT}$test_name\n"
  fi
  if [ $break_score = 0 ]; then
    marks=$((marks + 1))
  fi
}

print_footer() {
  printf "${PURPLE}-----------------------------------${DEFAULT}\n"
  space
  PERCENT=$((100 * marks / questions))
  #printf "Total checks:  ""${GREEN}${passed} passed  ${DEFAULT} ""${checks} total"
  if [ $norminette_skipped -eq 1 ]; then
    printf "Norminette:   ${GREY}skipped${DEFAULT}\n"
  else
    printf "Norminette:   ${GREEN}%s passed${DEFAULT}, ${RED}%s failed${DEFAULT}\n" "$norminette_passed" "$norminette_failed"
  fi
  printf "Result:        ${result}\n"
  if [ $PERCENT -ge 50 ]; then
    printf "Final score:   ""${GREEN}$(echo $PERCENT | bc)/100${DEFAULT}\n"
    printf "Status:        ""${GREEN}passed${DEFAULT}\n"
  else
    printf "Final score:   ""${RED}$(echo $PERCENT | bc)/100${DEFAULT}\n"
    printf "Status:        ""${RED}FAILED${DEFAULT}\n"
  fi
  end_time=$(date +%s)
  elapsed_time=$(expr $end_time - $start_time)
  printf "${GREY}Test completed. ${PINK}Total elapsed time: ${elapsed_time}s${DEFAULT}.\n"
  printf "${BLUE}Mini moulinette is updated daily. Please remember to git pull today!\n${DEFAULT}"
  space
}

check_dependency() {
  if ! command -v jq &>/dev/null; then
    printf "jq is not installed. To install:\n"
    printf "  Ubuntu/Debian:\n"
    printf "    sudo apt-get update\n"
    printf "    sudo apt-get install jq\n"
    printf "  macOS/Homebrew:\n"
    printf "    brew install jq\n"
  fi
}

#check_dependency
if [ "${1}" = "" ]; then
  printf "Please select an assignment. e.g. './test.sh C01'\n"
  exit 1
fi
assignment="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"

if [[ "$assignment" =~ ^C(0[0-9]|1[0-3])$ ]]; then
  if [ -z "${2}" ]; then
    main "$assignment" "$PWD"
  else
    main "$assignment" "$2"
  fi
  printf "$DEFAULT"
  exit
else
  printf "${RED}Invalid argument. Please select between C00 to C13${DEFAULT}\n"
fi
