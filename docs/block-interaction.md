# Block interaction between the NDK framebuffer and algebraic Tetris

The interaction layer should not let framebuffer gestures acquire mathematical meaning by accident.

The intended stack is:

    Android NDK touch / frame events
        ↓
    gesture recognition + hit testing
        ↓
    typed block command
        ↓
    Tetris piece / algebraic term
        ↓
    board collision + coefficient bookkeeping
        ↓
    framebuffer drawing

`types/src/MockTheta/Interaction.idr` sketches that boundary.

## What touching a block should do

### Grab and drag

Touching the active block grabs it.

Dragging changes only its proposed screen position. Horizontal drag is the main steering action. Downward drag can accelerate descent.

Dragging must **not** change which term of the factor the block represents.

A piece representing \(q^{6}\) before a drag still represents \(q^{6}\) afterward.

The type sketch encodes this as a `SpatialOnly` command and proves that the selected `Term factor` survives such a command unchanged.

### Tap

A short tap on the active piece should rotate it by one quarter-turn.

Rotation changes geometry only. It must not change degree, coefficient, factor identity or selected multiplicity.

### Release

Ordinary release should stop direct manipulation and return the piece to falling under the game clock.

Release should not by itself mean “commit this coefficient”. That would make small touch errors mathematically consequential.

### Downward flick

A deliberate fast downward flick can be the hard-drop gesture.

Hard drop moves the already-selected term to its final legal position and then requests locking. It still does not reinterpret the term.

### Collision

The gesture layer proposes a placement. The board decides whether that placement is legal.

This prevents touch code from becoming authoritative about board geometry. The interaction layer produces a `PlacementProposal`; collision code returns an accept/reject verdict.

## Changing the algebra

Changing the selected term is a different interaction class.

For a factor

\[
\frac{1}{1-q^m},
\]

the user may need to move among

\[
1,\ q^m,\ q^{2m},\ q^{3m},\ldots
\]

For

\[
\frac{1}{(1+q^m)^2},
\]

the same step changes both degree and signed coefficient.

I would give this an explicit previous/next control adjacent to the active piece or its formula row rather than overload dragging.

So:

- previous term = algebra command;
- next term = algebra command;
- dragging = spatial command;
- rotation = spatial command;
- hard drop / lock = lifecycle command.

That separation is more important than the exact gesture chosen later.

## Why not use horizontal swipe to change the term?

Because horizontal motion already has an obvious spatial meaning in Tetris.

If the same movement sometimes means “move the piece one column” and sometimes means “replace \(q^{km}\) with \(q^{(k+1)m}\)”, the UI can silently change the mathematics while the user thinks they are only positioning a block.

The type sketch makes those two effects inhabit different command types.

## Hit regions

Framebuffer drawing and hit testing should also remain separate.

The renderer can return ordinary pixel rectangles tagged as:

- active piece body;
- previous-term control;
- next-term control;
- rotate control;
- soft-drop control;
- hard-drop control;
- board background.

Those are `GestureTarget`s, not mathematical objects.

A visible rectangle only becomes mathematically meaningful after the corresponding typed command reaches the Tetris model.

## No ordinary line-clearing semantics

I would not make line clearing part of the mathematical core.

Destroying locked pieces would destroy the visible provenance of coefficient contributions. If a line-clear animation is ever useful, it should be a display transformation over already-recorded ledger entries, not deletion of the algebraic history.

The coefficient ledger remains authoritative even if the screen later compresses or animates old blocks.

## Proposed first control scheme

For the first APK:

- touch + drag active piece: move;
- tap active piece: rotate \(90^\circ\);
- hold/drag downward: soft drop;
- fast downward flick: hard drop and request lock;
- previous/next buttons beside the formula/active piece: change the selected term;
- release after ordinary drag: resume falling;
- collision: board-owned and fail-closed;
- algebraic selection: explicit and visibly reflected in degree/coefficient labels.

The important invariant is:

> positioning a block cannot change its \(q\)-series meaning, and changing its \(q\)-series meaning cannot happen as a side effect of positioning it.