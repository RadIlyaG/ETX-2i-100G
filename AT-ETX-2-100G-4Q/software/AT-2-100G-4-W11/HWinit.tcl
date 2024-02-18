set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     4
      set gaSet(comAux)   5
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT7EUBTT  
  }
  2 {
      set gaSet(comDut)    2
      set gaSet(comAux)  6
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT6YLYRN         
  }
  
}  
source lib_PackSour.tcl
