#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=${1:-"$repo_root/build/android/libmocktheta.so"}

abi=${ANDROID_ABI:-armeabi-v7a}
api=${ANDROID_API:-21}

case "$abi" in
    armeabi-v7a) target=armv7a-linux-androideabi ;;
    arm64-v8a) target=aarch64-linux-android ;;
    x86) target=i686-linux-android ;;
    x86_64) target=x86_64-linux-android ;;
    *)
        printf 'unsupported Android ABI: %s\n' "$abi" >&2
        exit 1
        ;;
esac

ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
if [[ -z "$ndk" ]]; then
    android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
    [[ -n "$android_home" ]] || {
        echo 'ANDROID_NDK_HOME or ANDROID_HOME is required' >&2
        exit 1
    }
    ndk=$(find "$android_home/ndk" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n 1)
fi

[[ -d "$ndk" ]] || {
    printf 'Android NDK not found: %s\n' "$ndk" >&2
    exit 1
}

toolchain=$(find "$ndk/toolchains/llvm/prebuilt" -mindepth 1 -maxdepth 1 -type d | head -n 1)
[[ -n "$toolchain" ]] || {
    echo 'Android NDK LLVM toolchain not found' >&2
    exit 1
}

clang="$toolchain/bin/${target}${api}-clang"
readelf="$toolchain/bin/llvm-readelf"
glue_dir="$ndk/sources/android/native_app_glue"
glue_source="$glue_dir/android_native_app_glue.c"

for required in "$clang" "$readelf" "$glue_source"; do
    [[ -e "$required" ]] || {
        printf 'missing Android build input: %s\n' "$required" >&2
        exit 1
    }
done

mkdir -p "$(dirname -- "$output")"

compiler_args=(
    -std=c11
    -O2
    -fPIC
    -shared
    -Wall
    -Wextra
    -Werror
    -Wno-unused-parameter
    -I "$glue_dir"
)

link_args=(
    -Wl,--no-undefined
    -Wl,-soname,libmocktheta.so
    -landroid
    -llog
)

case "$abi" in
    arm64-v8a|x86_64)
        link_args+=(
            -Wl,-z,max-page-size=16384
            -Wl,-z,common-page-size=16384
        )
        ;;
esac

"$clang" "${compiler_args[@]}" \
    "$repo_root/android/native/mock_theta_tetris.c" \
    "$glue_source" \
    "${link_args[@]}" \
    -o "$output"

symbols=$("$readelf" -Ws "$output")
grep -Fq 'ANativeActivity_onCreate' <<<"$symbols"
grep -Fq 'android_main' <<<"$symbols"

printf 'native ABI\t%s\n' "$abi"
printf 'native API floor\t%s\n' "$api"
printf 'native library\t%s\n' "$output"
