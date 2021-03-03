func mapRange( val: float64, 
               fromMin: float64, 
               fromMax: float64, 
               toMin: float64, 
               toMax: float64 ): float64 =
    return toMin+((toMax-toMin)/(fromMax-fromMin))*(val-fromMin)