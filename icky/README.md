# ICK C core

This directory is the application-owned C core compiled by
`dilapidated-shed/ick`.

The public boundary is deliberately ordinary scalar/pointer C:

`tetris_core.h`

No Android headers enter the ICK translation unit.

`tetris_core.c` owns:

- the five permitted coefficient shapes;
- signed unit-cell expansion;
- provenance fields for source and multiplication branch;
- Tetris as addition;
- coefficient extraction;
- layout by (q)-degree;
- framebuffer rendering.

`tests/tetris_core_test.c` pins the supplied five-panel arithmetic, pointer
gestures, reset and framebuffer bounds. `test.sh` delegates compilation to
`Makefile` and requires the pinned native `ICK_HOST_CC`; a missing ICK compiler
fails the build. The core and these unchanged behavioral assertions use `÷`
for ordinary division.

`build-armv7.sh` compiles the core as an ARMv7 Thumb-2, NEON-capable,
softfp-compatible PIC object with ICK. The NDK consumes that object only at the
Android boundary. `Makefile` also compiles the application-owned NativeActivity
shim with ICK against NDK API21 headers, emits assembly, and asks NDK Clang to
assemble that output. NDK source compilation remains confined to its own
`android_native_app_glue.c`.
