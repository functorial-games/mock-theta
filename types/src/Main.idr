module Main

import MockTheta.Tetris
import MockTheta.Interaction
import MockTheta.Validation

%default total

main : IO ()
main = do
  putStrLn "mock-theta coefficient-diagram type model"
  putStrLn
    ("factor 2 panel: " ++
      show (coefficientsThrough 3 (factorPanel factor2)))
  putStrLn
    ("factor 5 panel: " ++
      show (coefficientsThrough 9 (factorPanel factor5)))
  putStrLn
    ("blog five-panel Tetris sum: " ++
      show (coefficientsThrough 9 blogFivePanelTetris))
  putStrLn
    ("finite Tetris diagram: " ++
      statusName (mockThetaStatus (FiniteTetrisDiagram blogFivePanelTetris)))
  putStrLn
    ("Ramanujan third-order f: " ++
      statusName (mockThetaStatus RamanujanThirdOrderF))
