module MockTheta.Validation

import MockTheta.Tetris

%default total

||| Tetris diagrams are finite signed coefficient pictures. They are useful
||| calculations and visualizations, but drawing/adding one does not establish
||| an infinite analytic or modular property.
public export
data QSeriesSpec
  = FiniteTetrisDiagram Diagram
  | PartitionGeneratingSeries Nat
  | RamanujanThirdOrderF
  | UserTruncation (List Coefficient)

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
mockThetaStatus (FiniteTetrisDiagram diagram) =
  Unverified
mockThetaStatus (UserTruncation coefficients) =
  Unverified

public export
data ValidatedMockTheta : QSeriesSpec -> Type where
  RamanujanThirdOrderFValidated :
    ValidatedMockTheta RamanujanThirdOrderF

public export
validateMockTheta :
     (series : QSeriesSpec)
  -> Maybe (ValidatedMockTheta series)
validateMockTheta RamanujanThirdOrderF =
  Just RamanujanThirdOrderFValidated
validateMockTheta (PartitionGeneratingSeries cutoff) =
  Nothing
validateMockTheta (FiniteTetrisDiagram diagram) =
  Nothing
validateMockTheta (UserTruncation coefficients) =
  Nothing

public export
finiteTetrisDoesNotCertify :
  validateMockTheta (FiniteTetrisDiagram blogFivePanelTetris) = Nothing
finiteTetrisDoesNotCertify =
  Refl

public export
partitionIsNotMockTheta :
  mockThetaStatus (PartitionGeneratingSeries 8) = KnownNonMockTheta
partitionIsNotMockTheta =
  Refl

public export
finitePrefixDoesNotCertify :
  validateMockTheta (UserTruncation [1, 1, -2, 3, 5]) = Nothing
finitePrefixDoesNotCertify =
  Refl

public export
ramanujanFValidates :
  validateMockTheta RamanujanThirdOrderF =
    Just RamanujanThirdOrderFValidated
ramanujanFValidates =
  Refl
