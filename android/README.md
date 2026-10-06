# First Android APK

This is the intentionally direct first native slice of Mock Theta Tetris.

It is a framework `android.app.NativeActivity` with no application DEX and no
Gradle/Java/Kotlin layer. C owns the Android event loop, raw `ANativeWindow`
framebuffer, touch handling, board geometry and the first small amount of game
state.

The first build demonstrates:

- a 10 × 16 falling-block board;
- seven ordinary tetromino geometries;
- gravity and collision;
- drag the active piece directly;
- tap the active piece to rotate;
- fast downward flick or `DROP` to hard-drop;
- explicit `PREV` / `NEXT` controls for algebraic term selection;
- factors \(m=1,2,3,4\) from
  \[
  \prod_{m=1}^{4}(1+q^m)^{-2};
  \]
- selected term
  \[
  (-1)^k(k+1)q^{mk};
  \]
- completed four-factor path degree and coefficient;
- a deliberately visible `SERIES UNVERIFIED` status.

That last label is important. A legal Tetris path through these denominator
factors is not automatically a mock theta function. The Idris validation layer
keeps that distinction separately checked.

## Interaction boundary

Spatial gestures change only position/orientation. `PREV` / `NEXT` change the
algebraic term. The C code keeps those fields separate just as
`MockTheta.Interaction` does in the type sketch.

There is no line clearing in this first build. Locked blocks retain their
provenance on the board until top-out resets the demonstration.

## Build

`android/build-native.sh` compiles `libmocktheta.so` directly with the NDK.
CI then invokes the maintained
`isomorphisms/android-NDK/apk/build-nativeactivity-apk.sh` packager and the
mandatory `isomorphisms/ai-ci/android-producer` gate.

The current phone artifact is `armeabi-v7a`, API floor 21, target API 36.
