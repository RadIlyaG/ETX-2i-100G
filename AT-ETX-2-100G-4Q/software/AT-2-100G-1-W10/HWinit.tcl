set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)  2
      set gaSet(comAux)  6
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT31CP7A  
  }
  2 {
      set gaSet(comDut)    2
      set gaSet(comAux)  6
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT6YLYRN         
  }
  
}  
source lib_PackSour.tcl
