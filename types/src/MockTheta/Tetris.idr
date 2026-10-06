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
signValue : Sign -> Coefficient
signValue Plus = 1
signValue Minus = -1

public export
flipSign : Sign -> Sign
flipSign Plus = Minus
flipSign Minus = Plus

||| Factor stores n-1, so every FactorIndex denotes a genuine positive n.
||| Factor 0 means (1 - q), Factor 1 means (1 - q^2), and so on.
public export
data FactorIndex
  = Factor Nat

public export
factorDegree : FactorIndex -> Degree
factorDegree (Factor zeroBased) = S zeroBased

public export
factor1 : FactorIndex
factor1 = Factor 0

public export
factor2 : FactorIndex
factor2 = Factor 1

public export
factor3 : FactorIndex
factor3 = Factor 2

public export
factor4 : FactorIndex
factor4 = Factor 3

public export
factor5 : FactorIndex
factor5 = Factor 4

||| These are the ONLY constructors for a polynomial admitted by the Tetris
||| language.
|||
||| In particular, there is no constructor taking a coefficient list or a raw
||| cell diagram. Every inhabited AllowedPolynomial is structurally a finite
||| sum of permitted Shape values (with Zero as the empty sum).
public export
data AllowedPolynomial
  = Zero
  | Shape FactorIndex
  | Add AllowedPolynomial AllowedPolynomial

||| Safe convenience constructor: a list of factors still becomes only a sum
||| of permitted shapes.
public export
shapeSum : List FactorIndex -> AllowedPolynomial
shapeSum [] =
  Zero
shapeSum (factor :: rest) =
  Add (Shape factor) (shapeSum rest)

||| In the blog drawings the input to the n-th coloured panel is
|||
|||   1 + (1-q) + (1-q^2) + ... + (1-q^(n-1)).
|||
||| We preserve which summand produced each unit square.
public export
data SeedOrigin
  = LeadingOne
  | PreviousEulerFactor Degree

||| Multiplication by (1-q^n) makes two copies:
|||
|||   P(q)          and          -q^n P(q).
public export
data MultiplicationBranch
  = Unshifted
  | ShiftedNegated

public export
record SeedCell where
  constructor Seed
  seedDegree : Degree
  seedSign : Sign
  seedOrigin : SeedOrigin

||| A Cell is a read/render view of the mathematical "block" in the post.
|||
||| A raw Cell or Diagram is NOT an AllowedPolynomial and there is no public
||| conversion from arbitrary cells back to AllowedPolynomial.
public export
record Cell where
  constructor SignedCell
  degree : Degree
  sign : Sign
  panelFactor : FactorIndex
  seedOrigin : SeedOrigin
  branch : MultiplicationBranch

public export
Diagram : Type
Diagram = List Cell

private
previousSeedCells : (remaining : Nat) -> (nextDegree : Degree) -> List SeedCell
previousSeedCells Z nextDegree =
  []
previousSeedCells (S remaining) nextDegree =
  Seed 0 Plus (PreviousEulerFactor nextDegree) ::
  Seed nextDegree Minus (PreviousEulerFactor nextDegree) ::
  previousSeedCells remaining (S nextDegree)

||| Unit-square expansion of
|||
|||   1 + sum_{j=1}^{n-1} (1-q^j).
public export
panelSeed : FactorIndex -> List SeedCell
panelSeed (Factor zeroBased) =
  Seed 0 Plus LeadingOne ::
  previousSeedCells zeroBased 1

private
expandSeedCell : FactorIndex -> SeedCell -> Diagram
expandSeedCell factor seed =
  [ SignedCell
      (seedDegree seed)
      (seedSign seed)
      factor
      (seedOrigin seed)
      Unshifted
  , SignedCell
      (seedDegree seed + factorDegree factor)
      (flipSign (seedSign seed))
      factor
      (seedOrigin seed)
      ShiftedNegated
  ]

private
expandAll : FactorIndex -> List SeedCell -> Diagram
expandAll factor [] =
  []
expandAll factor (seed :: rest) =
  expandSeedCell factor seed ++ expandAll factor rest

||| Render view of one permitted primitive Shape.
public export
factorPanel : FactorIndex -> Diagram
factorPanel factor =
  expandAll factor (panelSeed factor)

||| "Tetris" in the post means addition of diagrams.
||| This is a derived rendering operation, not a constructor for
||| AllowedPolynomial.
public export
tetrisAdd : Diagram -> Diagram -> Diagram
tetrisAdd left right =
  left ++ right

||| The only interpretation from an allowed formula into visible signed cells.
public export
diagram : AllowedPolynomial -> Diagram
diagram Zero =
  []
diagram (Shape factor) =
  factorPanel factor
diagram (Add left right) =
  tetrisAdd (diagram left) (diagram right)

public export
coefficientAt : Degree -> Diagram -> Coefficient
coefficientAt wanted [] =
  0
coefficientAt wanted (cell :: rest) =
  let contribution =
        if degree cell == wanted
           then signValue (sign cell)
           else 0
   in contribution + coefficientAt wanted rest

public export
allowedCoefficientAt : Degree -> AllowedPolynomial -> Coefficient
allowedCoefficientAt wanted polynomial =
  coefficientAt wanted (diagram polynomial)

public export
columnCells : Degree -> Diagram -> List Cell
columnCells wanted [] =
  []
columnCells wanted (cell :: rest) =
  if degree cell == wanted
     then cell :: columnCells wanted rest
     else columnCells wanted rest

private
coefficientsFrom :
     (nextDegree : Degree)
  -> (count : Nat)
  -> Diagram
  -> List Coefficient
coefficientsFrom nextDegree Z diagramView =
  []
coefficientsFrom nextDegree (S count) diagramView =
  coefficientAt nextDegree diagramView ::
  coefficientsFrom (S nextDegree) count diagramView

public export
coefficientsThrough : Degree -> Diagram -> List Coefficient
coefficientsThrough lastDegree diagramView =
  coefficientsFrom 0 (S lastDegree) diagramView

public export
allowedCoefficientsThrough :
     Degree
  -> AllowedPolynomial
  -> List Coefficient
allowedCoefficientsThrough lastDegree polynomial =
  coefficientsThrough lastDegree (diagram polynomial)

||| The blog lays the five coloured panels out in this order before the red
||| "Tetris" arrows: n=5,4,3,2,1.
public export
blogFivePanelOrder : List FactorIndex
blogFivePanelOrder =
  [factor5, factor4, factor3, factor2, factor1]

||| The allowed formula itself. It is impossible to construct this value from
||| arbitrary coefficients; it is visibly a sum of five permitted Shapes.
public export
blogFivePanelPolynomial : AllowedPolynomial
blogFivePanelPolynomial =
  shapeSum blogFivePanelOrder

public export
blogFivePanelTetris : Diagram
blogFivePanelTetris =
  diagram blogFivePanelPolynomial

-- -------------------------------------------------------------------------
-- Laws showing that AllowedPolynomial really means "sum of permitted shapes".
-- -------------------------------------------------------------------------

public export
zeroDiagramLaw :
  diagram Zero = []
zeroDiagramLaw =
  Refl

public export
shapeDiagramLaw :
     (factor : FactorIndex)
  -> diagram (Shape factor) = factorPanel factor
shapeDiagramLaw factor =
  Refl

public export
additionDiagramLaw :
     (left : AllowedPolynomial)
  -> (right : AllowedPolynomial)
  -> diagram (Add left right)
     =
     tetrisAdd (diagram left) (diagram right)
additionDiagramLaw left right =
  Refl

-- -------------------------------------------------------------------------
-- Checked arithmetic from the supplied screenshots.
-- -------------------------------------------------------------------------

public export
factor1Coefficients :
  allowedCoefficientsThrough 1 (Shape MockTheta.Tetris.factor1)
    =
  [1, -1]
factor1Coefficients =
  Refl

public export
factor2Coefficients :
  allowedCoefficientsThrough 3 (Shape MockTheta.Tetris.factor2)
    =
  [2, -1, -2, 1]
factor2Coefficients =
  Refl

public export
factor3Coefficients :
  allowedCoefficientsThrough 5 (Shape MockTheta.Tetris.factor3)
    =
  [3, -1, -1, -3, 1, 1]
factor3Coefficients =
  Refl

public export
factor4Coefficients :
  allowedCoefficientsThrough 7 (Shape MockTheta.Tetris.factor4)
    =
  [4, -1, -1, -1, -4, 1, 1, 1]
factor4Coefficients =
  Refl

public export
factor5Coefficients :
  allowedCoefficientsThrough 9 (Shape MockTheta.Tetris.factor5)
    =
  [5, -1, -1, -1, -1, -5, 1, 1, 1, 1]
factor5Coefficients =
  Refl

public export
blogFivePanelCoefficients :
  allowedCoefficientsThrough 9 MockTheta.Tetris.blogFivePanelPolynomial
    =
  [15, -5, -5, -4, -4, -3, 2, 2, 1, 1]
blogFivePanelCoefficients =
  Refl
