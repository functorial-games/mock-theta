# Algebraic Tetris type model

The Tetris screen is an executable view of a factorized \(q\)-series calculation.

The governing rule is:

> A visible mathematical block must retain the exact term of the exact factor that created it.

The renderer can change pixels, camera, color, animation, collision response, framebuffer representation, and touch mechanics. It cannot invent a block with no algebraic meaning.

## First supported factors

The initial Idris model understands

\[
\frac{1}{1-q^m}
  = \sum_{k\ge0}q^{km}
\]

and

\[
\frac{1}{(1+q^m)^2}
  = \sum_{k\ge0}(-1)^k(k+1)q^{km}.
\]

For the first factor, choosing MinusTerm k contributes degree \(km\) and coefficient \(1\).

For the second, choosing PlusSquaredTerm k contributes degree \(km\) and coefficient \((-1)^k(k+1)\).

Those are deliberately different visual problems. The mock-theta denominator has signed weights; pretending every contribution is an ordinary unsigned Tetris block would erase the mathematics.

## Product paths

Choices factors is a heterogeneous list indexed by the factors themselves. A value of

    Choices [f1, f2, ..., fn]

contains one valid Term fi for every factor. A CompletedPath therefore cannot be constructed until the play-through has supplied one mathematically valid choice for every factor.

Its result is

    baseCoefficient * product selectedCoefficients

at degree

    baseDegree + sum selectedDegrees.

Different completed paths can land on the same degree. Adding their coefficients is exactly coefficient extraction in the truncated product.

That coefficient ledger should become the bridge between the game and the ordinary power-series display.

## Partition mode

For

\[
\prod_{m=1}^{M}\frac{1}{1-q^m},
\]

the \(m\)-th factor asks how many parts of size \(m\) to take.

A completed path is therefore a partition with largest allowed part at most \(M\). Enumerating all paths of total degree \(n\) reconstructs the truncated partition coefficient.

This is the cleanest first playable mode because every path has positive weight \(1\).

## Ramanujan-f summand mode

For one summand of Ramanujan's third-order function

\[
\frac{q^{n^2}}
{\prod_{j=1}^{n}(1+q^j)^2},
\]

the recipe starts at degree \(n^2\). Each denominator factor contributes a signed, weighted term.

The Tetris representation should preserve three things separately:

1. degree \(jk\);
2. sign;
3. multiplicity \(k+1\).

Color can encode factor identity. Geometry can encode degree or multiplicity. Sign should remain explicit rather than being hidden in color alone.

## Input

Touch motion splits naturally into two layers.

### Pixel motion

Dragging, dropping, rotation animation and collision response belong to C/Lua and do not change the mathematical term unless the UI explicitly says so.

### Algebra motion

Moving to the previous or next valid term changes \(k\):

    ... q^(m(k-1))  <->  q^(mk)  <->  q^(m(k+1)) ...

previousTerm and nextTerm define that neighborhood without allowing an invalid term.

## C/Lua boundary

Idris is not intended to own the Android renderer.

    Idris type model
        |
        | defines legal meanings, fixtures and invariants
        v
    Lua game state and q-series orchestration
        |
        v
    C framebuffer, touch input, geometry and drawing

The C/Lua representation can be flat and cheap. Its tests should be generated from or checked against fixtures corresponding to the Idris examples.

## Validation boundary

Tetris legality and mock-theta validity are different propositions.

A legal block proves only that a term belongs to the factor being played. A completed
Tetris path proves only a coefficient contribution to its factorized product. Neither
fact is evidence that the resulting whole (q)-series is a mock theta function.

`MockTheta.Validation` therefore accepts whole `QSeriesSpec` values, not
`FallingPiece` values. A generic `TetrisProduct` is classified `Unverified` and
cannot construct `ValidatedMockTheta`. The known full Ramanujan third-order (f(q))
has separate evidence.

A finite coefficient prefix also remains `Unverified`: matching finitely many
coefficients cannot establish the infinite analytic and modular conditions.

The partition generating series is explicitly classified separately as
`KnownNonMockTheta`. In particular, a mathematically legal Tetris construction does
not become a mock theta function merely because Tetris can display it.

## Deliberately outside the Tetris module

These should share a higher-level mathematical representation but should not be folded into the Tetris types:

- the implementation of theta-function and mock-modular validation;
- moving through parameter families;
- lattice and fundamental-parallelogram visualization;
- Wegert plots;
- modular transformations;
- shadows and nonholomorphic completions;
- coefficient plots.

Tetris consumes a factorized series recipe. Those other views consume the function itself.

## Next executable step

Implement the two first factors in Lua with a small coefficient ledger and make the following Idris examples cross-language fixtures:

- partition choice: degree \(4\), coefficient \(1\);
- mock denominator choice: degree \(5\), coefficient \(-6\).

Only after those agree should the renderer attach falling geometry to the terms.
