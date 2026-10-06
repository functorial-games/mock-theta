module MockTheta.Interaction

import MockTheta.Tetris

%default total

-- -------------------------------------------------------------------------
-- NDK-facing vocabulary
-- -------------------------------------------------------------------------

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

public export
data NdkEvent
  = Touch PointerSample
  | SurfaceChanged FramebufferSurface
  | AppPaused
  | AppResumed

-- -------------------------------------------------------------------------
-- What may move on screen
-- -------------------------------------------------------------------------

||| A whole coloured factor panel may be animated toward the addition stack.
||| The offset is presentation state only.
public export
record PanelPreview (factor : FactorIndex) where
  constructor Preview
  offset : PixelDelta

public export
previewDiagram :
     {factor : FactorIndex}
  -> PanelPreview factor
  -> Diagram
previewDiagram {factor} preview =
  factorPanel factor

private
addDelta : PixelDelta -> PixelDelta -> PixelDelta
addDelta (Delta x1 y1) (Delta x2 y2) =
  Delta (x1 + x2) (y1 + y2)

public export
movePreview :
     {factor : FactorIndex}
  -> PixelDelta
  -> PanelPreview factor
  -> PanelPreview factor
movePreview delta preview =
  Preview (addDelta (offset preview) delta)

||| Moving a panel picture cannot change any q-degree, sign, or provenance.
public export
previewMotionPreservesMathematics :
     {factor : FactorIndex}
  -> (delta : PixelDelta)
  -> (preview : PanelPreview factor)
  -> previewDiagram (movePreview delta preview)
     =
     previewDiagram preview
previewMotionPreservesMathematics delta preview =
  Refl

-- -------------------------------------------------------------------------
-- "Tetris" state: a running addition, not a falling-block game
-- -------------------------------------------------------------------------

public export
record AdditionState where
  constructor Addition
  addedPanels : List FactorIndex
  stack : Diagram

public export
emptyAddition : AdditionState
emptyAddition =
  Addition [] []

||| This is the semantic Tetris operation:
||| add one complete coloured polynomial diagram into the shared columns.
public export
addPanel : FactorIndex -> AdditionState -> AdditionState
addPanel factor state =
  Addition
    (addedPanels state ++ [factor])
    (tetrisAdd (stack state) (factorPanel factor))

public export
coefficientInState : Degree -> AdditionState -> Coefficient
coefficientInState wanted state =
  coefficientAt wanted (stack state)

-- -------------------------------------------------------------------------
-- UI commands
-- -------------------------------------------------------------------------

public export
data GestureTarget
  = FactorPanel FactorIndex
  | AdditionStack
  | DegreeColumn Degree
  | Background

public export
data CommandKind
  = PresentationOnly
  | Arithmetic
  | Inspection

||| No command exists for rotating, colliding, or independently relocating a
||| Cell. A Cell's degree is mathematical data.
public export
data UiCommand : CommandKind -> Type where
  MovePanelPreview :
       FactorIndex
    -> PixelDelta
    -> UiCommand PresentationOnly

  AddWholePanel :
       FactorIndex
    -> UiCommand Arithmetic

  ResetAddition :
    UiCommand Arithmetic

  InspectDegree :
       Degree
    -> UiCommand Inspection

public export
applyArithmetic :
     UiCommand Arithmetic
  -> AdditionState
  -> AdditionState
applyArithmetic (AddWholePanel factor) state =
  addPanel factor state
applyArithmetic ResetAddition state =
  emptyAddition

||| Dragging may make the red-arrow "drop" literal as an animation, but release
||| into the Tetris area means exactly one thing mathematically: addition of
||| the entire panel.
public export
data DropDecision
  = ReturnPanel
  | CommitPanelAddition FactorIndex

public export
record InteractionFrame where
  constructor InteractionInput
  surface : FramebufferSurface
  rawEvent : NdkEvent
  target : GestureTarget

-- -------------------------------------------------------------------------
-- Checked reconstruction of the blog's five-panel addition sequence.
-- -------------------------------------------------------------------------

public export
blogAdditionState : AdditionState
blogAdditionState =
  addPanel factor1
    (addPanel factor2
      (addPanel factor3
        (addPanel factor4
          (addPanel factor5 emptyAddition))))

public export
blogAdditionCoefficients :
  coefficientsThrough 9 (stack MockTheta.Interaction.blogAdditionState)
    =
  [15, -5, -5, -4, -4, -3, 2, 2, 1, 1]
blogAdditionCoefficients =
  Refl
