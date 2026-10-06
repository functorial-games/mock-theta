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

||| A whole primitive Shape may be animated toward the addition stack.
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
  diagram (Shape factor)

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
-- "Tetris" state: the state itself stores an AllowedPolynomial.
-- No raw cell list is authoritative.
-- -------------------------------------------------------------------------

public export
record AdditionState where
  constructor Addition
  expression : AllowedPolynomial

public export
emptyAddition : AdditionState
emptyAddition =
  Addition Zero

||| Add one permitted Shape. The result stays inside AllowedPolynomial by type.
public export
addPanel : FactorIndex -> AdditionState -> AdditionState
addPanel factor state =
  Addition (Add (expression state) (Shape factor))

||| Rendering is always derived from the typed expression.
public export
stack : AdditionState -> Diagram
stack state =
  diagram (expression state)

public export
coefficientInState : Degree -> AdditionState -> Coefficient
coefficientInState wanted state =
  allowedCoefficientAt wanted (expression state)

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

public export
blogAdditionState : AdditionState
blogAdditionState =
  Addition blogFivePanelPolynomial
