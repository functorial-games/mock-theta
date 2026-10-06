module MockTheta.Tetris

%default total

public export
Degree : Type
Degree = Nat

public export
Coefficient : Type
Coefficient = Integer

||| One visible square contributes exactly +1 or -1 to one coefficient column.
public export
data Sign
  = Plus
  | Minus

public export
sign_value : Sign -> Coefficient
sign_value Plus = 1
sign_value Minus = -1

public export
flip_sign : Sign -> Sign
flip_sign Plus = Minus
flip_sign Minus = Plus

||| Factor stores n-1, so every Factor_index denotes a genuine positive n.
||| Factor 0 means (1 - q), Factor 1 means (1 - q^2), and so on.
public export
data Factor_index
  = Factor Nat

public export
factor_degree : Factor_index -> Degree
factor_degree (Factor zeroBased) = S zeroBased

public export
factor_1 : Factor_index
factor_1 = Factor 0

public export
factor_2 : Factor_index
factor_2 = Factor 1

public export
factor_3 : Factor_index
factor_3 = Factor 2

public export
factor_4 : Factor_index
factor_4 = Factor 3

public export
factor_5 : Factor_index
factor_5 = Factor 4

||| These are the ONLY constructors for a polynomial admitted by the Tetris
||| language.
|||
||| In particular, there is no constructor taking a coefficient list or a raw
||| cell diagram. Every inhabited Allowed_polynomial is structurally a finite
||| sum of permitted Shape values (with Zero as the empty sum).
public export
data Allowed_polynomial
  = Zero
  | Shape Factor_index
  | Add Allowed_polynomial Allowed_polynomial

||| Safe convenience constructor: a list of factors still becomes only a sum
||| of permitted shapes.
public export
shape_sum : List Factor_index -> Allowed_polynomial
shape_sum [] =
  Zero
shape_sum (factor :: rest) =
  Add (Shape factor) (shape_sum rest)

||| In the blog drawings the input to the n-th coloured panel is
|||
|||   1 + (1−q) + (1−q^2) + ... + (1−q^(n-1)).
|||
||| We preserve which summand produced each unit square.
public export
data Seed_origin
  = Leading_one
  | Previous_euler_factor Degree

||| Multiplication by (1−q^n) makes two copies:
|||
|||   P(q)          and          −q^n P(q).
public export
data Multiplication_branch
  = Unshifted
  | Shifted_negated

public export
record Seed_cell where
  constructor Seed
  seed_degree : Degree
  seed_sign : Sign
  seed_origin : Seed_origin

||| A Cell is a read/render view of the mathematical "block" in the post.
|||
||| A raw Cell or Diagram is NOT an Allowed_polynomial and there is no public
||| conversion from arbitrary cells back to Allowed_polynomial.
public export
record Cell where
  constructor Signed_cell
  degree : Degree
  sign : Sign
  panel_factor : Factor_index
  seed_origin : Seed_origin
  branch : Multiplication_branch

public export
Diagram : Type
Diagram = List Cell

private
previousSeed_cells : (remaining : Nat) -> (next_degree : Degree) -> List Seed_cell
previousSeed_cells Z next_degree =
  []
previousSeed_cells (S remaining) next_degree =
  Seed 0 Plus (Previous_euler_factor next_degree) ::
  Seed next_degree Minus (Previous_euler_factor next_degree) ::
  previousSeed_cells remaining (S next_degree)

||| Unit-square expansion of
|||
|||   1 + sum_{j=1}^{n-1} (1−q^j).
public export
panel_seed : Factor_index -> List Seed_cell
panel_seed (Factor zeroBased) =
  Seed 0 Plus Leading_one ::
  previousSeed_cells zeroBased 1

private
expandSeed_cell : Factor_index -> Seed_cell -> Diagram
expandSeed_cell factor seed =
  [ Signed_cell
      (seed_degree seed)
      (seed_sign seed)
      factor
      (seed_origin seed)
      Unshifted
  , Signed_cell
      (seed_degree seed + factor_degree factor)
      (flip_sign (seed_sign seed))
      factor
      (seed_origin seed)
      Shifted_negated
  ]

private
expand_all : Factor_index -> List Seed_cell -> Diagram
expand_all factor [] =
  []
expand_all factor (seed :: rest) =
  expandSeed_cell factor seed ++ expand_all factor rest

||| Render view of one permitted primitive Shape.
public export
factor_panel : Factor_index -> Diagram
factor_panel factor =
  expand_all factor (panel_seed factor)

||| "Tetris" in the post means addition of diagrams.
||| This is a derived rendering operation, not a constructor for
||| Allowed_polynomial.
public export
tetris_add : Diagram -> Diagram -> Diagram
tetris_add left right =
  left ++ right

||| The only interpretation from an allowed formula into visible signed cells.
public export
diagram : Allowed_polynomial -> Diagram
diagram Zero =
  []
diagram (Shape factor) =
  factor_panel factor
diagram (Add left right) =
  tetris_add (diagram left) (diagram right)

public export
coefficient_at : Degree -> Diagram -> Coefficient
coefficient_at wanted [] =
  0
coefficient_at wanted (cell :: rest) =
  let contribution =
        if degree cell == wanted
           then sign_value (sign cell)
           else 0
   in contribution + coefficient_at wanted rest

public export
allowed_coefficient_at : Degree -> Allowed_polynomial -> Coefficient
allowed_coefficient_at wanted polynomial =
  coefficient_at wanted (diagram polynomial)

public export
column_cells : Degree -> Diagram -> List Cell
column_cells wanted [] =
  []
column_cells wanted (cell :: rest) =
  if degree cell == wanted
     then cell :: column_cells wanted rest
     else column_cells wanted rest

private
coefficients_from :
     (next_degree : Degree)
  -> (count : Nat)
  -> Diagram
  -> List Coefficient
coefficients_from next_degree Z diagram_view =
  []
coefficients_from next_degree (S count) diagram_view =
  coefficient_at next_degree diagram_view ::
  coefficients_from (S next_degree) count diagram_view

public export
coefficients_through : Degree -> Diagram -> List Coefficient
coefficients_through last_degree diagram_view =
  coefficients_from 0 (S last_degree) diagram_view

public export
allowed_coefficients_through :
     Degree
  -> Allowed_polynomial
  -> List Coefficient
allowed_coefficients_through last_degree polynomial =
  coefficients_through last_degree (diagram polynomial)

||| The blog lays the five coloured panels out in this order before the red
||| "Tetris" arrows: n=5,4,3,2,1.
public export
blog_five_panel_order : List Factor_index
blog_five_panel_order =
  [factor_5, factor_4, factor_3, factor_2, factor_1]

||| The allowed formula itself. It is impossible to construct this value from
||| arbitrary coefficients; it is visibly a sum of five permitted Shapes.
public export
blog_five_panel_polynomial : Allowed_polynomial
blog_five_panel_polynomial =
  shape_sum blog_five_panel_order

public export
blog_five_panel_tetris : Diagram
blog_five_panel_tetris =
  diagram blog_five_panel_polynomial

-- -------------------------------------------------------------------------
-- Laws showing that Allowed_polynomial really means "sum of permitted shapes".
-- -------------------------------------------------------------------------

public export
zero_diagram_law :
  diagram Zero = []
zero_diagram_law =
  Refl

public export
shape_diagram_law :
     (factor : Factor_index)
  -> diagram (Shape factor) = factor_panel factor
shape_diagram_law factor =
  Refl

public export
addition_diagram_law :
     (left : Allowed_polynomial)
  -> (right : Allowed_polynomial)
  -> diagram (Add left right)
     =
     tetris_add (diagram left) (diagram right)
addition_diagram_law left right =
  Refl

-- -------------------------------------------------------------------------
-- Checked arithmetic from the supplied screenshots.
-- -------------------------------------------------------------------------

public export
factor_1Coefficients :
  allowed_coefficients_through 1 (Shape MockTheta.Tetris.factor_1)
    =
  [1, -1]
factor_1Coefficients =
  Refl

public export
factor_2Coefficients :
  allowed_coefficients_through 3 (Shape MockTheta.Tetris.factor_2)
    =
  [2, -1, -2, 1]
factor_2Coefficients =
  Refl

public export
factor_3Coefficients :
  allowed_coefficients_through 5 (Shape MockTheta.Tetris.factor_3)
    =
  [3, -1, -1, -3, 1, 1]
factor_3Coefficients =
  Refl

public export
factor_4Coefficients :
  allowed_coefficients_through 7 (Shape MockTheta.Tetris.factor_4)
    =
  [4, -1, -1, -1, -4, 1, 1, 1]
factor_4Coefficients =
  Refl

public export
factor_5Coefficients :
  allowed_coefficients_through 9 (Shape MockTheta.Tetris.factor_5)
    =
  [5, -1, -1, -1, -1, -5, 1, 1, 1, 1]
factor_5Coefficients =
  Refl

public export
blog_five_panel_coefficients :
  allowed_coefficients_through 9 MockTheta.Tetris.blog_five_panel_polynomial
    =
  [15, -5, -5, -4, -4, -3, 2, 2, 1, 1]
blog_five_panel_coefficients =
  Refl
