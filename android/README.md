# Android APK

This APK implements the coefficient-diagram construction from the blog post.

**Tetris means addition.** It does not mean a falling-block ruleset.

The visible primitive is a signed unit coefficient cell. For the panel indexed
by (n), the ICK C core constructs

[
B_n(q)=1+sum_{j=1}^{n-1}(1-q^j)
]

and then

[
A_n(q)=(1-q^n)B_n(q)=B_n(q)-q^nB_n(q).
]

The five supplied blog panels are added in the order

[
A_5 	o A_4 	o A_3 	o A_2 	o A_1.
]

The final coefficient row is checked as

[
15-5q-5q^2-4q^3-4q^4-3q^5+2q^6+2q^7+q^8+q^9.
]

## Interaction

One complete coloured panel is shown above the accumulated coefficient stack.

- Drag the whole panel downward.
- Release it in the lower half → add the entire panel.
- The next panel appears.
- After all five have been added, tap to reset.

Individual coefficient cells cannot rotate, fall independently, collide, or
move between degree columns. Their horizontal position is derived from degree.

## Compiler boundary

The mathematical/rendering core in `icky/tetris_core.c` and the owned
NativeActivity shim are compiled by ICK for ARMv7:

[
	ext{typed model}
	o
	ext{ICK C core}
	o
	ext{thin NDK NativeActivity shim}
	o
	ext{APK}.
]

ICK owns shape expansion, signed-cell provenance, Tetris/addition, coefficient
extraction, and framebuffer drawing.

The NDK owns only the Android API boundary: NativeActivity lifecycle, touch
events, `ANativeWindow`, and the final Android shared-library link. This follows
the ICK source-to-assembly boundary: the shim's source, including pointer-scale
division, reaches ICK unchanged; NDK Clang assembles that output. Android
headers, the Bionic sysroot, unmodified native-app glue and the final link are
still supplied by the NDK. No source normalization or compiler fallback occurs.

The APK has no application DEX, Gradle, Java, Kotlin, or C++ layer.

Current target:

- package: `org.functorialgames.mocktheta`
- ABI: `armeabi-v7a`
- API floor: 21
- target API: 36
