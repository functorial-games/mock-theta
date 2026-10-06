#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

output="$repo_root/build/host/tetris_core_test"
mkdir -p "$(dirname -- "$output")"

cc \
    -std=c11 \
    -O2 \
    -Wall \
    -Wextra \
    -Werror \
    -pedantic \
    -I "$repo_root/icky" \
    "$repo_root/icky/tetris_core.c" \
    "$repo_root/icky/tests/tetris_core_test.c" \
    -o "$output"

"$output"

printf 'HOST_TETRIS_CORE\tPASS\n'
