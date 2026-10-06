module MockTheta.Tetris

%default total

public export
Degree : Type
Degree = Nat

public export
Coefficient : Type
Coefficient = Integer

public export
data Factor
  = EulerMinus Nat
  | EulerPlusSquared Nat

public export
data Term : Factor -> Type where
  MinusTerm :
       {step : Nat}
    -> (multiplicity : Nat)
    -> Term (EulerMinus step)

  PlusSquaredTerm :
       {step : Nat}
    -> (multiplicity : Nat)
    -> Term (EulerPlusSquared step)

private
isEven : Nat -> Bool
isEven Z = True
isEven (S Z) = False
isEven (S (S n)) = isEven n

public export
termDegree : {factor : Factor} -> Term factor -> Degree
termDegree {factor = EulerMinus step} (MinusTerm multiplicity) =
  multiplicity * step
termDegree {factor = EulerPlusSquared step} (PlusSquaredTerm multiplicity) =
  multiplicity * step

public export
termCoefficient : {factor : Factor} -> Term factor -> Coefficient
termCoefficient (MinusTerm multiplicity) =
  1
termCoefficient (PlusSquaredTerm multiplicity) =
  let magnitude : Integer = cast (S multiplicity)
   in if isEven multiplicity
         then magnitude
         else negate magnitude

public export
data Choices : List Factor -> Type where
  NoChoices :
    Choices []

  Choose :
       (factor : Factor)
    -> {rest : List Factor}
    -> Term factor
    -> Choices rest
    -> Choices (factor :: rest)

public export
choicesDegree :
     {factors : List Factor}
  -> Choices factors
  -> Degree
choicesDegree NoChoices = 0
choicesDegree (Choose factor term rest) =
  termDegree {factor = factor} term + choicesDegree rest

public export
choicesCoefficient :
     {factors : List Factor}
  -> Choices factors
  -> Coefficient
choicesCoefficient NoChoices = 1
choicesCoefficient (Choose factor term rest) =
  termCoefficient {factor = factor} term * choicesCoefficient rest

public export
record ProductRecipe where
  constructor Recipe
  name : String
  baseDegree : Degree
  baseCoefficient : Coefficient
  factors : List Factor

public export
record CompletedPath (recipe : ProductRecipe) where
  constructor Complete
  choices : Choices (factors recipe)

public export
completedDegree :
     (recipe : ProductRecipe)
  -> CompletedPath recipe
  -> Degree
completedDegree recipe path =
  baseDegree recipe + choicesDegree (choices path)

public export
completedCoefficient :
     (recipe : ProductRecipe)
  -> CompletedPath recipe
  -> Coefficient
completedCoefficient recipe path =
  baseCoefficient recipe * choicesCoefficient (choices path)

private
oneTo : Nat -> List Nat
oneTo Z = []
oneTo (S n) = oneTo n ++ [S n]

public export
partitionRecipe : (maxPart : Nat) -> ProductRecipe
partitionRecipe maxPart =
  Recipe
    "partition generating function"
    0
    1
    (map EulerMinus (oneTo maxPart))

public export
mockFSummandRecipe : (n : Nat) -> ProductRecipe
mockFSummandRecipe n =
  Recipe
    "Ramanujan third-order f summand"
    (n * n)
    1
    (map EulerPlusSquared (oneTo n))

public export
record Offset where
  constructor XY
  x : Int
  y : Int

public export
data QuarterTurn
  = Turn0
  | Turn90
  | Turn180
  | Turn270

public export
record Polyomino where
  constructor Shape
  cells : List Offset

public export
data PieceMeaning
  = PartBlocks
  | MultiplicityBlocks
  | SignedCoefficientBlock
  | MonomialBlock

public export
record ScreenPosition where
  constructor At
  x : Int
  y : Int

public export
record FallingPiece (factor : Factor) where
  constructor Falling
  term : Term factor
  shape : Polyomino
  meaning : PieceMeaning
  position : ScreenPosition
  orientation : QuarterTurn

public export
data SomeFallingPiece : Type where
  PackFalling :
       (factor : Factor)
    -> FallingPiece factor
    -> SomeFallingPiece

public export
data LockedPiece : Type where
  Lock :
       (factor : Factor)
    -> Term factor
    -> Polyomino
    -> ScreenPosition
    -> QuarterTurn
    -> LockedPiece

public export
lockedDegree : LockedPiece -> Degree
lockedDegree (Lock factor term shape position orientation) =
  termDegree {factor = factor} term

public export
lockedCoefficient : LockedPiece -> Coefficient
lockedCoefficient (Lock factor term shape position orientation) =
  termCoefficient {factor = factor} term

public export
data AlgebraMove : Factor -> Type where
  Select :
       {factor : Factor}
    -> Term factor
    -> AlgebraMove factor

  Rotate :
       {factor : Factor}
    -> QuarterTurn
    -> AlgebraMove factor

  Drop :
       {factor : Factor}
    -> AlgebraMove factor

  Commit :
       {factor : Factor}
    -> AlgebraMove factor

public export
nextTerm :
     {factor : Factor}
  -> Term factor
  -> Term factor
nextTerm (MinusTerm multiplicity) =
  MinusTerm (S multiplicity)
nextTerm (PlusSquaredTerm multiplicity) =
  PlusSquaredTerm (S multiplicity)

public export
previousTerm :
     {factor : Factor}
  -> Term factor
  -> Maybe (Term factor)
previousTerm (MinusTerm Z) =
  Nothing
previousTerm (MinusTerm (S multiplicity)) =
  Just (MinusTerm multiplicity)
previousTerm (PlusSquaredTerm Z) =
  Nothing
previousTerm (PlusSquaredTerm (S multiplicity)) =
  Just (PlusSquaredTerm multiplicity)

public export
record TetrisState where
  constructor State
  recipe : ProductRecipe
  nextFactor : Nat
  active : Maybe SomeFallingPiece
  locked : List LockedPiece

public export
lockedDegreeTotal : List LockedPiece -> Degree
lockedDegreeTotal [] = 0
lockedDegreeTotal (piece :: rest) =
  lockedDegree piece + lockedDegreeTotal rest

public export
lockedCoefficientTotal : List LockedPiece -> Coefficient
lockedCoefficientTotal [] = 1
lockedCoefficientTotal (piece :: rest) =
  lockedCoefficient piece * lockedCoefficientTotal rest

public export
partitionExample :
  Choices [EulerMinus 1, EulerMinus 2]
partitionExample =
  Choose (EulerMinus 1) (MinusTerm 2)
    (Choose (EulerMinus 2) (MinusTerm 1)
      NoChoices)

public export
partitionExampleDegree : choicesDegree MockTheta.Tetris.partitionExample = 4
partitionExampleDegree = Refl

public export
partitionExampleCoefficient : choicesCoefficient MockTheta.Tetris.partitionExample = 1
partitionExampleCoefficient = Refl

public export
mockDenominatorExample :
  Choices [EulerPlusSquared 1, EulerPlusSquared 2]
mockDenominatorExample =
  Choose (EulerPlusSquared 1) (PlusSquaredTerm 1)
    (Choose (EulerPlusSquared 2) (PlusSquaredTerm 2)
      NoChoices)

public export
mockDenominatorDegree : choicesDegree MockTheta.Tetris.mockDenominatorExample = 5
mockDenominatorDegree = Refl

public export
mockDenominatorCoefficient : choicesCoefficient MockTheta.Tetris.mockDenominatorExample = -6
mockDenominatorCoefficient = Refl
