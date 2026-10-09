#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

output="$repo_root/build/host/tetris_core_test"
mkdir -p "$(dirname -- "$output")"

make -f "$repo_root/icky/Makefile" host-test-binary HOST_TEST_OUTPUT="$output"

"$output"

printf 'HOST_TETRIS_CORE\tPASS\n'
