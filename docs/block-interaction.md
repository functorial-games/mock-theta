# Interaction between the NDK framebuffer and Tetris-as-addition

The interaction layer follows the blog construction literally.

A **cell** is fixed mathematical data: one signed unit at one \(q\)-degree. Individual cells are not game pieces.

A **panel** is a complete coloured polynomial diagram such as the orange \(A_4(q)\) or blue \(A_5(q)\) panel in the screenshots.

## What can move

Only presentation objects move.

The renderer may animate an entire panel downward toward the common coefficient columns. That motion is a pixel offset attached to a `PanelPreview`.

The typed invariant is that moving a preview changes only its pixel offset; the `previewDiagram` before and after is identical. Animation therefore cannot alter degree, sign, or provenance.

## What dropping means

A downward animation can visually resemble dropping blocks because that is how the red Tetris arrows are drawn.

But the semantic event at the end is simply `AddWholePanel factor`, meaning current stack plus `factorPanel factor`. No collision solver is involved.

If a drag is cancelled or released outside the addition area, no arithmetic occurs.

## Framebuffer geometry

The framebuffer derives geometry from mathematics:

- cell degree -> horizontal coefficient column
- cell order in a column -> vertical stack position
- cell sign -> + or - glyph
- panel factor -> colour family
- provenance -> optional shade/detail

Pixels never determine degree. Degree determines pixels.

## Useful touch targets

The first useful interaction vocabulary is small:

- a coloured factor panel
- the shared addition/Tetris area
- a degree column for inspection
- background

Possible interactions are whole-panel drag/addition, provenance highlighting, degree-column inspection, and reset. The exact gesture mapping can change without changing the mathematics.

## Things intentionally absent

The type sketch has no tetrominoes, rotating cells, gravity, line clearing, collision, hard drop, soft drop, or independent horizontal relocation of a cell.

Those concepts came from the mistaken interpretation of the word Tetris and do not belong in this construction.

## NDK boundary

`MockTheta.Interaction` still gives Android ordinary framebuffer and pointer types. Presentation, arithmetic, and inspection commands are indexed separately so screen motion cannot accidentally alter the polynomial.

The C framebuffer should be a renderer for these typed coefficient diagrams, not a Tetris game engine.