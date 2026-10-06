module MockTheta.Validation

import MockTheta.Tetris

%default total

||| A Tetris expression can enter validation only as an Allowed_polynomial.
||| Arbitrary Diagram values and arbitrary coefficient lists cannot masquerade
||| as Tetris-expressible formulas.
public export
data Q_series_spec
  = Finite_tetris_polynomial Allowed_polynomial
  | Partition_generating_series Nat
  | Ramanujan_third_order_f
  | User_truncation (List Coefficient)

public export
data Mock_theta_status
  = Proven_mock_theta
  | Known_non_mock_theta
  | Unverified

public export
status_name : Mock_theta_status -> String
status_name Proven_mock_theta = "proven mock theta"
status_name Known_non_mock_theta = "known non-mock-theta"
status_name Unverified = "unverified"

public export
mock_theta_status : Q_series_spec -> Mock_theta_status
mock_theta_status Ramanujan_third_order_f =
  Proven_mock_theta
mock_theta_status (Partition_generating_series cutoff) =
  Known_non_mock_theta
mock_theta_status (Finite_tetris_polynomial polynomial) =
  Unverified
mock_theta_status (User_truncation coefficients) =
  Unverified

public export
data Validated_mock_theta : Q_series_spec -> Type where
  Ramanujan_third_order_f_validated :
    Validated_mock_theta Ramanujan_third_order_f

public export
validate_mock_theta :
     (series : Q_series_spec)
  -> Maybe (Validated_mock_theta series)
validate_mock_theta Ramanujan_third_order_f =
  Just Ramanujan_third_order_f_validated
validate_mock_theta (Partition_generating_series cutoff) =
  Nothing
validate_mock_theta (Finite_tetris_polynomial polynomial) =
  Nothing
validate_mock_theta (User_truncation coefficients) =
  Nothing

public export
finite_tetris_does_not_certify :
  validate_mock_theta
    (Finite_tetris_polynomial blog_five_panel_polynomial)
    =
  Nothing
finite_tetris_does_not_certify =
  Refl

public export
partition_is_not_mock_theta :
  mock_theta_status (Partition_generating_series 8) = Known_non_mock_theta
partition_is_not_mock_theta =
  Refl

public export
finite_prefix_does_not_certify :
  validate_mock_theta (User_truncation [1, 1, -2, 3, 5]) = Nothing
finite_prefix_does_not_certify =
  Refl

public export
ramanujan_f_validates :
  validate_mock_theta Ramanujan_third_order_f =
    Just Ramanujan_third_order_f_validated
ramanujan_f_validates =
  Refl
