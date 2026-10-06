# Algebraic Tetris: the blog construction

In this repository **Tetris means addition**.

It does not mean tetrominoes, gravity, rotation, collision, line clearing, or a falling-block ruleset.

The supplied blog screenshots are the reference fixture for this model.

## The mathematical block

A visible square is one signed unit contribution to one coefficient:

\[
+q^d \qquad\text{or}\qquad −q^d.
\]

Its horizontal position is therefore not free geometry. It is the degree \(d\).

Each square also carries provenance: which coloured panel produced it and which part of the multiplication produced it. The renderer may move an entire panel around while animating, but it must not change a square's degree or sign.

## The coloured panels in the screenshots

For the panel headed \(1−q^n\), the screenshots first form

\[
B_n(q)=1+\sum_{j=1}^{n-1}(1−q^j)=n-\sum_{j=1}^{n-1}q^j.
\]

Then they multiply by \(1−q^n\):

\[
A_n(q)=(1−q^n)B_n(q)=B_n(q)−q^nB_n(q).
\]

This is why every panel consists of an unshifted copy and a copy shifted right by \(n\) columns with every sign reversed. The Idris module records those branches as `Unshifted` and `Shifted_negated`.

The first five checked coefficient rows are:

- \(A_1=[1,-1]\)
- \(A_2=[2,-1,-2,1]\)
- \(A_3=[3,-1,-1,-3,1,1]\)
- \(A_4=[4,-1,-1,-1,-4,1,1,1]\)
- \(A_5=[5,-1,-1,-1,-1,-5,1,1,1,1]\)

## Tetris

The red-arrow step labelled **Tetris** is addition.

`tetris_add left right` concatenates the signed cells and the renderer places equal degrees in the same vertical column.

Opposite signs are deliberately not deleted from the picture. The coloured cells remain visible so provenance survives. The numerical coefficient of degree \(d\) is obtained by summing the signs in that column.

## Five-panel screenshot fixture

The screenshot order is \(A_5,A_4,A_3,A_2,A_1\). Stacking them gives the checked row

\[
15-5q-5q^2-4q^3-4q^4-3q^5+2q^6+2q^7+q^8+q^9.
\]

The Idris proof `blog_five_panel_coefficients` reduces the exact signed-cell construction to that exact coefficient list.

The type sketch does not silently identify this finite addition with any other infinite series or with mock-theta validity. Those are separate mathematical claims.

## Android boundary

```text
Idris: exact signed-cell construction and screenshot fixtures
  → Lua/small C state: panel sequencing and inspection
  → C framebuffer: degree → x, stack order → y, colours and +/- glyphs
```

The Android layer may animate a whole panel downward, matching the red arrows. It may not invent rotation, collision, tetromino shapes, or independent block motion.

## Validation boundary

A finite signed coefficient diagram is a calculation, not proof of mock modularity. `MockTheta.Validation` therefore classifies a `Finite_tetris_polynomial` as `Unverified`.