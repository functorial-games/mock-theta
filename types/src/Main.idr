module Main

import MockTheta.Tetris
import MockTheta.Interaction
import MockTheta.Validation

%default total

main : IO ()
main = do
  putStrLn "mock-theta typed shape-sum model"
  putStrLn
    ("factor 2 shape: " ++
      show (allowed_coefficients_through 3 (Shape factor_2)))
  putStrLn
    ("factor 5 shape: " ++
      show (allowed_coefficients_through 9 (Shape factor_5)))
  putStrLn
    ("blog five-shape Tetris sum: " ++
      show (allowed_coefficients_through 9 blog_five_panel_polynomial))
  putStrLn
    ("typed Tetris polynomial: " ++
      status_name
        (mock_theta_status
          (Finite_tetris_polynomial blog_five_panel_polynomial)))
  putStrLn
    ("five whole-panel gestures: " ++
      show (allowed_coefficients_through 9 (expression five_whole_panel_state)))
  putStrLn
    ("Ramanujan third-order f: " ++
      status_name (mock_theta_status Ramanujan_third_order_f))
