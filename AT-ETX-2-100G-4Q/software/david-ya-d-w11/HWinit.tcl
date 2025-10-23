set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     1
      set gaSet(comAux)  7
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT6YM2PB  
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
  }
  2 {
      set gaSet(comDut)    2
      set gaSet(comAux)  6
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT5PF5N0    
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA      
  }
  
}  
source lib_PackSour.tcl
