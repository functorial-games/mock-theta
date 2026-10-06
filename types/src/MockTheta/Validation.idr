module MockTheta.Validation

import MockTheta.Tetris

%default total

||| A mathematical q-series object that can be presented to the validator.
|||
||| A single FallingPiece is deliberately not a QSeriesSpec. A Tetris block is
||| a contribution to a calculation, not itself a q-series.
public export
data QSeriesSpec
  = TetrisProduct ProductRecipe
  | PartitionGeneratingSeries Nat
  | RamanujanThirdOrderF
  | UserTruncation (List Coefficient)

||| Conservative public result.
|||
||| "Unverified" is important: failure to recognize a series is not a proof
||| that the series can never have mock-modular structure.
public export
data MockThetaStatus
  = ProvenMockTheta
  | KnownNonMockTheta
  | Unverified

public export
statusName : MockThetaStatus -> String
statusName ProvenMockTheta = "proven mock theta"
statusName KnownNonMockTheta = "known non-mock-theta"
statusName Unverified = "unverified"

public export
mockThetaStatus : QSeriesSpec -> MockThetaStatus
mockThetaStatus RamanujanThirdOrderF =
  ProvenMockTheta
mockThetaStatus (PartitionGeneratingSeries cutoff) =
  KnownNonMockTheta
mockThetaStatus (TetrisProduct recipe) =
  Unverified
mockThetaStatus (UserTruncation coefficients) =
  Unverified

||| Evidence is indexed by the exact series being certified.
|||
||| There is intentionally no constructor for TetrisProduct, a random
||| coefficient list, or one summand of Ramanujan's f(q). Merely being
||| constructible by the Tetris engine cannot promote an expression to a mock
||| theta function.
public export
data ValidatedMockTheta : QSeriesSpec -> Type where
  RamanujanThirdOrderFValidated :
    ValidatedMockTheta RamanujanThirdOrderF

||| Conservative validator.
|||
||| At this stage it accepts only series for which this module carries explicit
||| mathematical evidence. Future named mock theta functions can be added as
||| new QSeriesSpec constructors plus corresponding evidence constructors.
public export
validateMockTheta :
     (series : QSeriesSpec)
  -> Maybe (ValidatedMockTheta series)
validateMockTheta RamanujanThirdOrderF =
  Just RamanujanThirdOrderFValidated
validateMockTheta (PartitionGeneratingSeries cutoff) =
  Nothing
validateMockTheta (TetrisProduct recipe) =
  Nothing
validateMockTheta (UserTruncation coefficients) =
  Nothing

||| A random legal Tetris product is not automatically promoted.
public export
tetrisDoesNotImplyMockTheta :
  validateMockTheta (TetrisProduct (partitionRecipe 4)) = Nothing
tetrisDoesNotImplyMockTheta = Refl

||| The ordinary partition generating series is explicitly classified
||| separately from mock theta functions.
public export
partitionIsNotMockTheta :
  mockThetaStatus (PartitionGeneratingSeries 8) = KnownNonMockTheta
partitionIsNotMockTheta = Refl

||| A finite coefficient prefix cannot certify an infinite analytic/modular
||| property, even if it happens to match a known mock theta function for a
||| while.
public export
finitePrefixDoesNotCertify :
  validateMockTheta (UserTruncation [1, 1, -2, 3, 5]) = Nothing
finitePrefixDoesNotCertify = Refl

||| The named full Ramanujan function is accepted.
public export
ramanujanFValidates :
  validateMockTheta RamanujanThirdOrderF =
    Just RamanujanThirdOrderFValidated
ramanujanFValidates = Refl
