module MockTheta.Interaction

import MockTheta.Tetris

%default total

-- -------------------------------------------------------------------------
-- NDK-facing vocabulary
-- -------------------------------------------------------------------------

public export
record Pixel_point where
  constructor Pixel
  pixel_x : Int
  pixel_y : Int

public export
record Pixel_delta where
  constructor Delta
  delta_x : Int
  delta_y : Int

public export
record Framebuffer_surface where
  constructor Surface
  width_pixels : Nat
  height_pixels : Nat
  stride_pixels : Nat

public export
data Pointer_phase
  = Pointer_down
  | Pointer_move
  | Pointer_up
  | Pointer_cancel

public export
record Pointer_sample where
  constructor Pointer
  pointer_number : Nat
  phase : Pointer_phase
  position : Pixel_point
  event_time_millis : Nat

public export
data Ndk_event
  = Touch Pointer_sample
  | Surface_changed Framebuffer_surface
  | App_paused
  | App_resumed

-- -------------------------------------------------------------------------
-- What may move on screen
-- -------------------------------------------------------------------------

||| A whole primitive Shape may be animated toward the addition stack.
||| The offset is presentation state only.
public export
record Panel_preview (factor : Factor_index) where
  constructor Preview
  offset : Pixel_delta

public export
preview_diagram :
     {factor : Factor_index}
  -> Panel_preview factor
  -> Diagram
preview_diagram {factor} preview =
  diagram (Shape factor)

private
add_delta : Pixel_delta -> Pixel_delta -> Pixel_delta
add_delta (Delta x1 y1) (Delta x2 y2) =
  Delta (x1 + x2) (y1 + y2)

public export
move_preview :
     {factor : Factor_index}
  -> Pixel_delta
  -> Panel_preview factor
  -> Panel_preview factor
move_preview delta preview =
  Preview (add_delta (offset preview) delta)

public export
preview_motion_preserves_mathematics :
     {factor : Factor_index}
  -> (delta : Pixel_delta)
  -> (preview : Panel_preview factor)
  -> preview_diagram (move_preview delta preview)
     =
     preview_diagram preview
preview_motion_preserves_mathematics delta preview =
  Refl

-- -------------------------------------------------------------------------
-- "Tetris" state: the state itself stores an Allowed_polynomial.
-- No raw cell list is authoritative.
-- -------------------------------------------------------------------------

public export
record Addition_state where
  constructor Addition
  expression : Allowed_polynomial

public export
empty_addition : Addition_state
empty_addition =
  Addition Zero

||| Add one permitted Shape. The result stays inside Allowed_polynomial by type.
public export
add_panel : Factor_index -> Addition_state -> Addition_state
add_panel factor state =
  Addition (Add (expression state) (Shape factor))

||| Rendering is always derived from the typed expression.
public export
stack : Addition_state -> Diagram
stack state =
  diagram (expression state)

public export
coefficient_in_state : Degree -> Addition_state -> Coefficient
coefficient_in_state wanted state =
  allowed_coefficient_at wanted (expression state)

-- -------------------------------------------------------------------------
-- UI commands
-- -------------------------------------------------------------------------

public export
data Gesture_target
  = Factor_panel Factor_index
  | Addition_stack
  | Degree_column Degree
  | Background

public export
data Command_kind
  = Presentation_only
  | Arithmetic
  | Inspection

public export
data Ui_command : Command_kind -> Type where
  Move_panel_preview :
       Factor_index
    -> Pixel_delta
    -> Ui_command Presentation_only

  Add_whole_panel :
       Factor_index
    -> Ui_command Arithmetic

  Reset_addition :
    Ui_command Arithmetic

  Inspect_degree :
       Degree
    -> Ui_command Inspection

public export
apply_arithmetic :
     Ui_command Arithmetic
  -> Addition_state
  -> Addition_state
apply_arithmetic (Add_whole_panel factor) state =
  add_panel factor state
apply_arithmetic Reset_addition state =
  empty_addition

public export
data Drop_decision
  = Return_panel
  | Commit_panel_addition Factor_index

public export
record Interaction_frame where
  constructor Interaction_input
  surface : Framebuffer_surface
  raw_event : Ndk_event
  target : Gesture_target

public export
blog_addition_state : Addition_state
blog_addition_state =
  Addition blog_five_panel_polynomial
