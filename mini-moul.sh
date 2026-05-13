#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$SCRIPT_DIR/mini-moul/config.sh"

normalize_project()
{
  local project

  project=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
  if [[ "$project" =~ ^C(0[0-9]|1[0-3])$ ]]; then
    printf '%s' "$project"
    return 0
  fi

  return 1
}

usage()
{
  printf "Usage: %s [-t C00]\n" "$0"
}

project=""

while getopts ":t:h" opt; do
  case "$opt" in
    t)
      project="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      printf "${RED}Option -%s requires an argument.${DEFAULT}\n" "$OPTARG"
      usage
      exit 1
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$project" ] && [ $# -gt 0 ]; then
  project="$1"
fi

student_root=$(pwd -P)

if [ -z "$project" ]; then
  project=$(basename "$student_root")
fi

if ! project=$(normalize_project "$project"); then
  printf "${RED}Invalid argument. Please select between C00 to C13.${DEFAULT}\n"
  exit 1
fi

if [ ! -d "$student_root" ]; then
  printf "${RED}Current directory is not accessible.${DEFAULT}\n"
  exit 1
fi

"$SCRIPT_DIR/mini-moul/test.sh" "$project" "$student_root"
