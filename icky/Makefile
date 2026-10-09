# Make's fixed command interface binds both maintained C producers to ICK.
# NDK Clang consumes assembly for the owned Android shim and C for NDK glue.
MOCK_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
ICK_HOST_CC ?= $(ICK_CC)
ICK_ARM_CC ?= $(ICK_CC)
ICK_HOST_FLAGS ?=
ICK_ARM_FLAGS ?=
ICK_LINK_FLAGS ?= -fno-link-libatomic
ANDROID_NDK_HOME ?= $(ANDROID_NDK_ROOT)
ANDROID_API ?= 21
NDK_BIN = $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/bin
NDK_SYSROOT = $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot
NDK_GLUE = $(ANDROID_NDK_HOME)/sources/android/native_app_glue
NDK_ASSEMBLER = $(NDK_BIN)/armv7a-linux-androideabi$(ANDROID_API)-clang
HOST_TEST_OUTPUT ?= $(MOCK_ROOT)/build/host/tetris_core_test
NATIVE_ACTIVITY_OBJECT ?= $(MOCK_ROOT)/build/android/object/native_activity.o
ARM_PROFILE = -march=armv7-a -mthumb -mfpu=neon -mfloat-abi=softfp

.PHONY: host-test-binary native-activity-object
host-test-binary:
	test -n "$(ICK_HOST_CC)"
	test -x "$(ICK_HOST_CC)"
	mkdir -p "$(dir $(HOST_TEST_OUTPUT))"
	"$(ICK_HOST_CC)" $(ICK_HOST_FLAGS) $(ICK_LINK_FLAGS) -std=c11 -O2 -Wall -Wextra -Werror -pedantic -I "$(MOCK_ROOT)/icky" "$(MOCK_ROOT)/icky/tetris_core.c" "$(MOCK_ROOT)/icky/tests/tetris_core_test.c" -o "$(HOST_TEST_OUTPUT)"

native-activity-object:
	test -n "$(ICK_ARM_CC)"
	test -x "$(ICK_ARM_CC)"
	test -x "$(NDK_ASSEMBLER)"
	test "$$("$(ICK_ARM_CC)" $(ICK_ARM_FLAGS) -dumpmachine)" = arm-linux-gnueabi
	mkdir -p "$(dir $(NATIVE_ACTIVITY_OBJECT))"
	"$(ICK_ARM_CC)" $(ICK_ARM_FLAGS) -S --sysroot="$(NDK_SYSROOT)" -isystem "$(NDK_SYSROOT)/usr/include" -isystem "$(NDK_SYSROOT)/usr/include/arm-linux-androideabi" -isystem "$(NDK_GLUE)" -D__ANDROID__ -D__ANDROID_API__=$(ANDROID_API) -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD -std=c11 -O2 -fPIC -Wall -Wextra -Werror $(ARM_PROFILE) -I "$(MOCK_ROOT)/icky" "$(MOCK_ROOT)/android/native/native_activity.c" -o "$(NATIVE_ACTIVITY_OBJECT).s"
	"$(NDK_ASSEMBLER)" $(ARM_PROFILE) -c "$(NATIVE_ACTIVITY_OBJECT).s" -o "$(NATIVE_ACTIVITY_OBJECT)"
	"$(NDK_BIN)/llvm-readelf" -h -A "$(NATIVE_ACTIVITY_OBJECT)" > "$(NATIVE_ACTIVITY_OBJECT).abi.txt"
	printf 'source_compiler\tICK\nsource_stage\tC-to-assembly\nassembler\tNDK Clang\napi\t%s\n' "$(ANDROID_API)" > "$(NATIVE_ACTIVITY_OBJECT).compiler.tsv"
