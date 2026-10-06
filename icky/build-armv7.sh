#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

output=${1:-"$repo_root/build/ick/armeabi-v7a/tetris_core.o"}

: "${ICK_CC:?ICK_CC is required}"

ick_readelf=${ICK_READELF:-arm-linux-gnueabi-readelf}
ick_nm=${ICK_NM:-arm-linux-gnueabi-nm}

command -v "$ick_readelf" >/dev/null 2>&1
command -v "$ick_nm" >/dev/null 2>&1

mkdir -p "$(dirname -- "$output")"

"$ICK_CC" \
    -march=armv7-a \
    -mthumb \
    -mfpu=neon \
    -mfloat-abi=softfp \
    -std=c11 \
    -O2 \
    -fPIC \
    -ffreestanding \
    -nostdinc \
    -fvisibility=hidden \
    -Wall \
    -Wextra \
    -Werror \
    -I "$repo_root/icky" \
    -c "$repo_root/icky/tetris_core.c" \
    -o "$output"

"$ick_readelf" -h "$output" \
    | tee "${output%.o}.elf.txt"

"$ick_readelf" -A "$output" \
    | tee "${output%.o}.attributes.txt"

grep -q 'Class:.*ELF32' "${output%.o}.elf.txt"
grep -q 'Machine:.*ARM' "${output%.o}.elf.txt"
grep -q 'Tag_CPU_arch: v7' "${output%.o}.attributes.txt"
grep -q 'Tag_THUMB_ISA_use: Thumb-2' "${output%.o}.attributes.txt"

if grep -q 'Tag_ABI_VFP_args: VFP registers' \
    "${output%.o}.attributes.txt"; then
    echo 'ICK object escaped Android softfp ABI' >&2
    exit 1
fi

"$ick_nm" -u "$output" \
    | tee "${output%.o}.undefined.txt"

printf 'ICK_OBJECT\tPASS\n'
printf 'OBJECT\t%s\n' "$output"
