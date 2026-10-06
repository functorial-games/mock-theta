module MockTheta.Interaction

import MockTheta.Tetris

%default total

-- -------------------------------------------------------------------------
-- NDK-facing vocabulary
-- -------------------------------------------------------------------------

||| Pixel coordinates belong to the framebuffer/input side only.
||| They do not carry algebraic meaning.
public export
record PixelPoint where
  constructor Pixel
  pixelX : Int
  pixelY : Int

public export
record PixelDelta where
  constructor Delta
  deltaX : Int
  deltaY : Int

public export
record FramebufferSurface where
  constructor Surface
  widthPixels : Nat
  heightPixels : Nat
  stridePixels : Nat

public export
data PointerPhase
  = PointerDown
  | PointerMove
  | PointerUp
  | PointerCancel

public export
record PointerSample where
  constructor Pointer
  pointerNumber : Nat
  phase : PointerPhase
  position : PixelPoint
  eventTimeMillis : Nat

||| Events exposed by the thin Android/NDK adapter.
||| No constructor here knows what a q-series term is.
public export
data NdkEvent
  = Touch PointerSample
  | FrameTick Nat
  | SurfaceChanged FramebufferSurface
  | AppPaused
  | AppResumed

-- -------------------------------------------------------------------------
-- Gesture vocabulary
-- -------------------------------------------------------------------------

public export
data Gesture
  = Tap PixelPoint
  | Drag PixelPoint PixelPoint
  | Swipe PixelDelta
  | Release PixelPoint
  | CancelGesture

||| Hit testing decides which UI region owns a gesture.
||| This is deliberately separate from gesture recognition.
public export
data GestureTarget
  = ActivePieceBody
  | PreviousTermControl
  | NextTermControl
  | RotateControl
  | SoftDropControl
  | HardDropControl
  | BoardBackground
  | OutsideBoard

-- -------------------------------------------------------------------------
-- Commands crossing from UI interaction into the Tetris model
-- -------------------------------------------------------------------------

||| The kind index is the important boundary.
||| SpatialOnly commands are forbidden from changing Term factor.
||| AlgebraChoice commands may change the selected term.
||| PieceLifecycle commands may commit/drop the already selected meaning.
public export
data CommandKind
  = SpatialOnly
  | AlgebraChoice
  | PieceLifecycle

public export
data BlockCommand : CommandKind -> Factor -> Type where
  TranslateBy :
       {factor : Factor}
    -> PixelDelta
    -> BlockCommand SpatialOnly factor

  RotateTo :
       {factor : Factor}
    -> QuarterTurn
    -> BlockCommand SpatialOnly factor

  SoftDropRows :
       {factor : Factor}
    -> Nat
    -> BlockCommand SpatialOnly factor

  SelectPrevious :
       {factor : Factor}
    -> BlockCommand AlgebraChoice factor

  SelectNext :
       {factor : Factor}
    -> BlockCommand AlgebraChoice factor

  SelectExact :
       {factor : Factor}
    -> Term factor
    -> BlockCommand AlgebraChoice factor

  HardDrop :
       {factor : Factor}
    -> BlockCommand PieceLifecycle factor

  RequestLock :
       {factor : Factor}
    -> BlockCommand PieceLifecycle factor

  CancelPiece :
       {factor : Factor}
    -> BlockCommand PieceLifecycle factor

||| Existential command returned by a gesture policy.
||| The command kind remains visible in the constructor instead of being erased.
public export
data InteractionDecision : Factor -> Type where
  IgnoreGesture :
    InteractionDecision factor

  SpatialDecision :
       BlockCommand SpatialOnly factor
    -> InteractionDecision factor

  AlgebraDecision :
       BlockCommand AlgebraChoice factor
    -> InteractionDecision factor

  LifecycleDecision :
       BlockCommand PieceLifecycle factor
    -> InteractionDecision factor

-- -------------------------------------------------------------------------
-- The algebra boundary
-- -------------------------------------------------------------------------

||| Only an AlgebraChoice command has an operation capable of replacing
||| Term factor. Previous can fail at the first term.
public export
applyAlgebraChoice :
     {factor : Factor}
  -> BlockCommand AlgebraChoice factor
  -> Term factor
  -> Maybe (Term factor)
applyAlgebraChoice SelectPrevious current =
  previousTerm current
applyAlgebraChoice SelectNext current =
  Just (nextTerm current)
applyAlgebraChoice (SelectExact selected) current =
  Just selected

||| Spatial commands can inspect the current term for drawing, but this
||| operation has no route for replacing it.
public export
termAfterSpatial :
     {factor : Factor}
  -> BlockCommand SpatialOnly factor
  -> FallingPiece factor
  -> Term factor
termAfterSpatial command piece =
  term piece

public export
spatialPreservesMeaning :
     {factor : Factor}
  -> (command : BlockCommand SpatialOnly factor)
  -> (piece : FallingPiece factor)
  -> termAfterSpatial command piece = term piece
spatialPreservesMeaning command piece =
  Refl

||| Lifecycle commands commit or discard the selected piece; they do not
||| reinterpret it as a different q-series term before doing so.
public export
termBeforeLifecycle :
     {factor : Factor}
  -> BlockCommand PieceLifecycle factor
  -> FallingPiece factor
  -> Term factor
termBeforeLifecycle command piece =
  term piece

public export
lifecyclePreservesMeaningUntilCommit :
     {factor : Factor}
  -> (command : BlockCommand PieceLifecycle factor)
  -> (piece : FallingPiece factor)
  -> termBeforeLifecycle command piece = term piece
lifecyclePreservesMeaningUntilCommit command piece =
  Refl

-- -------------------------------------------------------------------------
-- Placement is proposed by interaction and judged by the board.
-- -------------------------------------------------------------------------

public export
record PlacementProposal where
  constructor ProposedPlacement
  proposedPosition : ScreenPosition
  proposedOrientation : QuarterTurn

public export
data PlacementVerdict
  = AcceptPlacement
  | RejectCollision
  | RejectOutsideBoard

||| The interaction layer proposes geometry.
||| The board/collision layer remains authoritative about whether it is legal.
public export
record SpatialRequest (factor : Factor) where
  constructor SpatialMove
  originalTerm : Term factor
  proposedPlacement : PlacementProposal

-- -------------------------------------------------------------------------
-- One input packet passed across the C/Lua <-> typed-model boundary.
-- -------------------------------------------------------------------------

public export
record InteractionFrame (factor : Factor) where
  constructor InteractionInput
  surface : FramebufferSurface
  piece : FallingPiece factor
  rawEvent : NdkEvent
  gesture : Maybe Gesture
  target : GestureTarget

||| Rendering returns hit regions separately from the algebraic piece.
||| That keeps framebuffer rectangles from becoming mathematical blocks.
public export
record PixelRect where
  constructor Rect
  leftPixel : Int
  topPixel : Int
  rightPixel : Int
  bottomPixel : Int

public export
record HitRegion where
  constructor Hit
  region : PixelRect
  target : GestureTarget

public export
record BlockInteractionOverlay where
  constructor Overlay
  hitRegions : List HitRegion

-- -------------------------------------------------------------------------
-- Policy examples
--
-- These describe semantics, not a final Android gesture map.
-- C/Lua may choose different recognizers without weakening the type boundary.
-- -------------------------------------------------------------------------

public export
pieceDrag :
     {factor : Factor}
  -> PixelDelta
  -> InteractionDecision factor
pieceDrag delta =
  SpatialDecision (TranslateBy delta)

public export
pieceRotate :
     {factor : Factor}
  -> QuarterTurn
  -> InteractionDecision factor
pieceRotate turn =
  SpatialDecision (RotateTo turn)

public export
choosePrevious :
     {factor : Factor}
  -> InteractionDecision factor
choosePrevious =
  AlgebraDecision SelectPrevious

public export
chooseNext :
     {factor : Factor}
  -> InteractionDecision factor
chooseNext =
  AlgebraDecision SelectNext

public export
hardDrop :
     {factor : Factor}
  -> InteractionDecision factor
hardDrop =
  LifecycleDecision HardDrop

-- -------------------------------------------------------------------------
-- Checked examples
-- -------------------------------------------------------------------------

public export
interactionExampleTerm :
  Term (EulerMinus 3)
interactionExampleTerm =
  MinusTerm 2

public export
interactionNextExample :
  applyAlgebraChoice SelectNext
    MockTheta.Interaction.interactionExampleTerm
    =
  Just (MinusTerm 3)
interactionNextExample =
  Refl

public export
interactionPreviousExample :
  applyAlgebraChoice SelectPrevious
    MockTheta.Interaction.interactionExampleTerm
    =
  Just (MinusTerm 1)
interactionPreviousExample =
  Refl
