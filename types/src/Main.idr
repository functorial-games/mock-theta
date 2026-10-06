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
      show (allowedCoefficientsThrough 3 (Shape factor2)))
  putStrLn
    ("factor 5 shape: " ++
      show (allowedCoefficientsThrough 9 (Shape factor5)))
  putStrLn
    ("blog five-shape Tetris sum: " ++
      show (allowedCoefficientsThrough 9 blogFivePanelPolynomial))
  putStrLn
    ("typed Tetris polynomial: " ++
      statusName
        (mockThetaStatus
          (FiniteTetrisPolynomial blogFivePanelPolynomial)))
  putStrLn
    ("Ramanujan third-order f: " ++
      statusName (mockThetaStatus RamanujanThirdOrderF))
