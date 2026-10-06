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

||| A Cell is the mathematical "block" in the post.
|||
||| It has no rotation, velocity, collision box, tetromino identity, or
||| independent horizontal position. Its horizontal column IS its q-degree.
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

||| The exact coloured panel headed "1 - q^n times..." in the blog.
|||
||| Algebraically this is
|||
|||   (1-q^n) * [1 + (1-q) + ... + (1-q^(n-1))].
|||
||| The result remains expanded into signed unit cells instead of prematurely
||| collapsing equal degrees into one coefficient.
public export
factorPanel : FactorIndex -> Diagram
factorPanel factor =
  expandAll factor (panelSeed factor)

||| "Tetris" in the post means addition.
|||
||| Adding two pictures means putting their signed cells into the same degree
||| columns. We deliberately DO NOT delete opposite signs: the coloured
||| provenance stays visible, and the coefficient is read by summing signs.
public export
tetrisAdd : Diagram -> Diagram -> Diagram
tetrisAdd left right =
  left ++ right

public export
tetrisPanels : List FactorIndex -> Diagram
tetrisPanels [] =
  []
tetrisPanels (factor :: rest) =
  tetrisAdd (factorPanel factor) (tetrisPanels rest)

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
coefficientsFrom nextDegree Z diagram =
  []
coefficientsFrom nextDegree (S count) diagram =
  coefficientAt nextDegree diagram ::
  coefficientsFrom (S nextDegree) count diagram

public export
coefficientsThrough : Degree -> Diagram -> List Coefficient
coefficientsThrough lastDegree diagram =
  coefficientsFrom 0 (S lastDegree) diagram

||| The blog lays the five coloured panels out in this order before the red
||| "Tetris" arrows: n=5,4,3,2,1.
public export
blogFivePanelOrder : List FactorIndex
blogFivePanelOrder =
  [factor5, factor4, factor3, factor2, factor1]

public export
blogFivePanelTetris : Diagram
blogFivePanelTetris =
  tetrisPanels blogFivePanelOrder

-- -------------------------------------------------------------------------
-- Checked arithmetic from the supplied screenshots.
-- -------------------------------------------------------------------------

public export
factor1Coefficients :
  coefficientsThrough 1 (factorPanel factor1)
    =
  [1, -1]
factor1Coefficients =
  Refl

public export
factor2Coefficients :
  coefficientsThrough 3 (factorPanel factor2)
    =
  [2, -1, -2, 1]
factor2Coefficients =
  Refl

public export
factor3Coefficients :
  coefficientsThrough 5 (factorPanel factor3)
    =
  [3, -1, -1, -3, 1, 1]
factor3Coefficients =
  Refl

public export
factor4Coefficients :
  coefficientsThrough 7 (factorPanel factor4)
    =
  [4, -1, -1, -1, -4, 1, 1, 1]
factor4Coefficients =
  Refl

public export
factor5Coefficients :
  coefficientsThrough 9 (factorPanel factor5)
    =
  [5, -1, -1, -1, -1, -5, 1, 1, 1, 1]
factor5Coefficients =
  Refl

||| This is the coefficient row underneath the final stacked picture:
|||
|||   15 -5q -5q^2 -4q^3 -4q^4 -3q^5
|||      +2q^6 +2q^7 +q^8 +q^9.
public export
blogFivePanelCoefficients :
  coefficientsThrough 9 blogFivePanelTetris
    =
  [15, -5, -5, -4, -4, -3, 2, 2, 1, 1]
blogFivePanelCoefficients =
  Refl
