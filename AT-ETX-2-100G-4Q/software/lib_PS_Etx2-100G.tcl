# ***************************************************************************
# PS_RetriveDutFam
# ***************************************************************************
proc PS_RetriveDutFam {} {
  global gaSet
  set dutInitName $gaSet(DutInitName)
  puts "\nPS_RetriveDutFam $dutInitName"
  set gaSet(dutFam) 19.0.0.0.0.0.0
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set PS noPS
  if {[string match *.WR.* $dutInitName]==1} {
    set PS WR
  } elseif {[string match *.ACDC* $dutInitName]==1} {
    set PS ACDC
  } elseif {[string match *DC* $dutInitName]==1 || [string match *DRF* $dutInitName]==1} {
    set PS DC
  } elseif {[string match *.AC* $dutInitName]==1 || [string match *ARF* $dutInitName]==1} {
    set PS AC
  } elseif {[string match *.NULL.* $dutInitName]==1} {
    set PS AC
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$PS.$np.$up  
  }
  set gaSet(dutBox) $b
    
  puts "PS_RetriveDutFam dutInitName:$dutInitName dutBox:$gaSet(dutBox) DutFam:$gaSet(dutFam)" ; update
  return {}
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc PS_ID {run} {
  global gaSet
  # if {[string match "*[lindex [info level 0] 0]*" $gaSet(startFrom)]} {
    # set ret [Wait "Wait fot SFPs ..." 90]
    # if {$ret!=0} {return $ret}
  # }
  
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  } 
  
  foreach {b r p d psType np up} [split $gaSet(dutFam) .] {}
  
  set com $gaSet(comDut)
  set gaSet(fail) "Logon fail"
  set ret [LogonDebug $com]
  
  set ret [Send $com "debug mea\r\r" FPGA]
  if {$ret!=0} {return $ret}
  
  Power all on
  foreach ps {1} {
    
    set ret [Send $com "mea util ps show $ps\r" FPGA]
    if {$ret!=0} {return $ret}
    
    if [string match "*ENTU_ERROR*" $buffer] {
      set gaSet(fail) "\'ENTU_ERROR\' in \'ps show $ps\'"  
      return -1
    }
    
    set res [regexp {reg\[0x9A\] MFR_MODEL[\.\s]+([A-Z0-9\-]+).+FPGA\>} $buffer ma val]
    if !$res {
      set gaSet(fail) "Read MFR_MODEL Fail"
      return -1
    }
    if {$psType eq "AC"} {
      set models $::models_AC
    } elseif {$psType eq "DC"} {
      set models $::models_DC
    }  
    
    puts "MFR_MODEL:<$val> models:<$models>"
    if {[lsearch $models $val]=="-1"} {
      set gaSet(fail) "The MFR_MODEL is \'$val\'. Should be one of the \'$models\'"  
      return -1
    }    
  } 
  
  set ret [Send $com "exit\r\r" stam 2]
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {set gaSet(fail) "Can't reach ETX-2"; return $ret}
  set ret [Send $com "configure chassis\r" ">chassis"]
  if {$ret!=0} {set gaSet(fail) "Can't reach >chassis"; return $ret}
  set ret [Send $com "show environment\r" ">chassis"]
  if {$ret!=0} {set gaSet(fail) "Can't reach >chassis"; return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set psQty [regexp -all $ps $buffer]
  set psQtyShBe 2
  puts "PS_IDTest b:$b psQty:$psQty psQtyShBe:$psQtyShBe"
  if {$psQty!=$psQtyShBe} {
    set gaSet(fail) "Qty or type of PSs is wrong."
    return -1
  }
  set res [regexp {\-+\s(.+\s+FAN)} $buffer - psStatus]
  if {$res==0} {
    set gaSet(fail) "Can't get psStatus"
    return -1
  }
  set res [regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status]
  if {$res==0} {
    set gaSet(fail) "Can't get ps1Status"
    return -1
  }
  set ps1Status [string trim $ps1Status]
  puts "psStatus:<$psStatus> ps1Status:<$ps1Status>"
  
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
    return -1
  }
   
  return $ret
}
# ***************************************************************************
# PS_DataTransmission
# ***************************************************************************
proc PS_DataTransmission  {run} {
  global gaSet
  Power all on
  
  for {set i 1} {$i<=4} {incr i} { 
    puts "\n[MyTime] $i x 10sec"
    set ret [MeaGenerator_Start]
    if {$ret!=0} {return $ret}
    set ret [Wait "Data is running" 10 white]
    if {$ret!=0} {return $ret}
    set ret [MeaGenerator_Check]
    if {$ret!=0} {
      after 2000
    } else {
      break
    }
  }
  if {$ret!=0} {return $ret}
    
  set ret [MeaGenerator_Start]
  if {$ret!=0} {return $ret}
  set ret [Wait "Data is running" 120 white]
  if {$ret!=0} {return $ret}
  set ret [MeaGenerator_Check]
  if {$ret!=0} {return $ret}
  
  return $ret
}