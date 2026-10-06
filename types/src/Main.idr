module Main

import MockTheta.Tetris

%default total

main : IO ()
main = do
  putStrLn "mock-theta Idris type model"
  putStrLn ("partition example degree: " ++ show (choicesDegree partitionExample))
  putStrLn ("partition example coefficient: " ++ show (choicesCoefficient partitionExample))
  putStrLn ("mock denominator degree: " ++ show (choicesDegree mockDenominatorExample))
  putStrLn ("mock denominator coefficient: " ++ show (choicesCoefficient mockDenominatorExample))
