module Main

import MockTheta.Tetris
import MockTheta.Interaction
import MockTheta.Validation

%default total

main : IO ()
main = do
  putStrLn "mock-theta Idris type model"
  putStrLn ("partition example degree: " ++ show (choicesDegree partitionExample))
  putStrLn ("partition example coefficient: " ++ show (choicesCoefficient partitionExample))
  putStrLn ("mock denominator degree: " ++ show (choicesDegree mockDenominatorExample))
  putStrLn ("mock denominator coefficient: " ++ show (choicesCoefficient mockDenominatorExample))
  putStrLn "interaction boundary: spatial commands preserve algebraic term"
  putStrLn
    ("random Tetris product: " ++
      statusName (mockThetaStatus (TetrisProduct (partitionRecipe 4))))
  putStrLn
    ("Ramanujan third-order f: " ++
      statusName (mockThetaStatus RamanujanThirdOrderF))
