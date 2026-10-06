#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

ick_object=${1:-"$repo_root/build/ick/armeabi-v7a/tetris_core.o"}
output=${2:-"$repo_root/build/android/armeabi-v7a/libmocktheta.so"}

abi=${ANDROID_ABI:-armeabi-v7a}
api=${ANDROID_API:-21}

[[ "$abi" == armeabi-v7a ]] || {
    echo 'first ICK APK lane is armeabi-v7a only' >&2
    exit 1
}

[[ -f "$ick_object" ]] || {
    printf 'missing ICK object: %s\n' "$ick_object" >&2
    exit 1
}

ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}

if [[ -z "$ndk" ]]; then
    android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}

    [[ -n "$android_home" ]] || {
        echo 'ANDROID_NDK_HOME or ANDROID_HOME is required' >&2
        exit 1
    }

    ndk=$(
        find "$android_home/ndk" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            | sort -V \
            | tail -n 1
    )
fi

toolchain=$(
    find "$ndk/toolchains/llvm/prebuilt" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | head -n 1
)

clang="$toolchain/bin/armv7a-linux-androideabi${api}-clang"
readelf="$toolchain/bin/llvm-readelf"
nm="$toolchain/bin/llvm-nm"

glue_dir="$ndk/sources/android/native_app_glue"
glue_source="$glue_dir/android_native_app_glue.c"

for required in \
    "$clang" \
    "$readelf" \
    "$nm" \
    "$glue_source"
do
    [[ -e "$required" ]] || {
        printf 'missing Android build input: %s\n' "$required" >&2
        exit 1
    }
done

work="$repo_root/build/android/object"
rm -rf "$work"
mkdir -p "$work" "$(dirname -- "$output")"

"$clang" \
    -std=c11 \
    -O2 \
    -fPIC \
    -Wall \
    -Wextra \
    -Werror \
    -I "$glue_dir" \
    -I "$repo_root/icky" \
    -c "$repo_root/android/native/native_activity.c" \
    -o "$work/native_activity.o"

"$clang" \
    -std=c11 \
    -O2 \
    -fPIC \
    -Wall \
    -Wextra \
    -Werror \
    -Wno-unused-parameter \
    -I "$glue_dir" \
    -c "$glue_source" \
    -o "$work/native_app_glue.o"

"$clang" \
    -shared \
    -Wl,-z,defs \
    -Wl,-z,text \
    -Wl,--fatal-warnings \
    -Wl,-soname,libmocktheta.so \
    "$ick_object" \
    "$work/native_activity.o" \
    "$work/native_app_glue.o" \
    -landroid \
    -llog \
    -o "$output"

"$readelf" -h "$output" \
    | tee "${output%.so}.elf.txt"

grep -q 'Class:.*ELF32' "${output%.so}.elf.txt"
grep -q 'Machine:.*ARM' "${output%.so}.elf.txt"

"$nm" -D --defined-only "$output" \
    | tee "${output%.so}.exports.txt"

grep -Fq 'ANativeActivity_onCreate' \
    "${output%.so}.exports.txt"

printf 'ANDROID_LIBRARY\tPASS\n'
printf 'LIBRARY\t%s\n' "$output"
