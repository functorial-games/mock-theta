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

`tests/tetris_core_test.c` pins the supplied five-panel arithmetic before the
cross-compiler is built.

`build-armv7.sh` compiles the core as an ARMv7 Thumb-2, NEON-capable,
softfp-compatible PIC object with ICK. The NDK consumes that object only at the
Android boundary.
