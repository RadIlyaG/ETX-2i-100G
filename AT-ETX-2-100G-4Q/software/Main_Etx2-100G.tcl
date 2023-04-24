# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set glTests ""
  set lTestsAllTests [list]
  if {$gaSet(rbTestMode) eq "On_Off"} {
    set lTests On_Off
  } else {
    if ![string match *.PS.*  $gaSet(DutInitName)] {
      set lDownloadTests [list BootDownload Pages SetDownload SoftwareDownload]
      eval lappend lTestsAllTests $lDownloadTests
      
      
      lappend lTestNames SetToDefault VoltageTest
      lappend lTestNames SFP_ID ID 
    }
    
    if {$gaSet(rbTestMode)=="Full"} {
      lappend lTestNames PowerSupplyTest
    
      if ![string match *.PS.*  $gaSet(DutInitName)] {
        lappend lTestNames DyingGaspConf DyingGaspTest
      }
    }
    
    lappend lTestNames DataTransmission_Set DataTransmission_Test
    
    if {$gaSet(rbTestMode)=="Full"} {
      lappend lTestNames HotSwap
      
      if ![string match *.PS.*  $gaSet(DutInitName)] {
        lappend lTestNames LedsTest ; # 28/04/2019 10:23:45 LedsTest1 LedsTest2
        lappend lTestNames FinalSetToDefault 
      
        if {$gaSet(DefaultCF)!="" && $gaSet(DefaultCF)!="c:/aa"} {
          lappend lTestNames LoadDefaultConfiguration
        }
        
        if {[string match *david-ya* [info host]]} {
          ##  don't do it at David's
        } else {
          lappend lTestNames Mac_BarCode
        }
      }
    }
    
    eval lappend lTestsAllTests $lTestNames
    
    
    set gaSet(TestMode) AllTests
    set lTests [set lTests$gaSet(TestMode)]
  }
    
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
#   AddToLog "********* DUT start *********"
  AddToPairLog $gaSet(pair) "********* DUT start *********"
#   if {$gaSet(dutBox)!="DNFV"} {
#     AddToLog "$gaSet(1.barcode1)"
#   }     
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"
  
  if {[lsearch $lRunTests *exProg*]!="-1"} {
    Power all off
    
    set txt "Set SW2/2 to ON"
    RLSound::Play information
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "SW2/2 ON" -message $txt]
    update
    if {$res=="OK"} {
      set ret 0
    } else {
      set ret -2
    }
    if {$ret!=0} {return $ret}
  
  }

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
#     AddToLog "Test \'$testName\' started"
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    puts "ret of the \'$testName\':<$ret>" ; update
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
#     AddToLog "Test \'$testName\' $retTxt"
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }

  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"
  
  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# 20secPrompt
# ***************************************************************************
proc 20secPrompt {run} {
  global gaSet buffer
  return 0
}

# ***************************************************************************
# LedsTest
# ***************************************************************************
proc LedsTest  {run} {
  global gaSet
  set ret [LedsTest_perf]
  return $ret
} 
# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  
#   30/04/2019 10:46:21
#   set ret [20secPromptPerf]
#   if {$ret!=0} {return $ret}
#   Wait "Wait for UUT up" 20
  
  Power all on
  
  
  set ret [FactDefault stda cont]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# FinalSetToDefault
# ***************************************************************************
proc FinalSetToDefault {run} {
  global gaSet gaGui
  
#   30/04/2019 10:46:21
#   set ret [20secPromptPerf]
#   if {$ret!=0} {return $ret}
#   Wait "Wait for UUT up" 20
  
  Power all on
  
  set pair $::pair 
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  
  set ret [FactDefault stda break]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for reset" 30 white]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DataTransmission_Set
# ***************************************************************************
proc DataTransmission_Set  {run} {
  global gaSet
  Power all on
  
  set ret [FactDefault std break]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for reset" 30 white]
  if {$ret!=0} {return $ret}
  
  set ret [8SFPP_Config data]
  return $ret
  
}  

# ***************************************************************************
# DataTransmission_Test
# ***************************************************************************
proc DataTransmission_Test  {run} {
  global gaSet
  Power all on
  
  set ret [MeaGenerator_Start]
  if {$ret!=0} {return $ret}
  set ret [Wait "Data is running" 10 white]
  if {$ret!=0} {return $ret}
  set ret [MeaGenerator_Check]
  if {$ret!=0} {return $ret}
  
  set ret [MeaGenerator_Start]
  if {$ret!=0} {return $ret}
  set ret [Wait "Data is running" 120 white]
  if {$ret!=0} {return $ret}
  set ret [MeaGenerator_Check]
  if {$ret!=0} {
#     set ret [MeaGenerator_Start]
#     if {$ret!=0} {return $ret}
#     set ret [Wait "Data is running" 120 white]
#     if {$ret!=0} {return $ret}
#     set ret [MeaGenerator_Check]
#     if {$ret!=0} {return $ret}
  }
  
  return $ret
}  

# ***************************************************************************
# HotSwap
# ***************************************************************************
proc HotSwap {run} {
  global gaSet
  set ret [MeaGenerator_Start]
  if {$ret!=0} {return $ret}
  
  foreach ps {1 2} {
    Power $ps off
    
    RLSound::Play information
    set txt "Verify the following:\n\n\
    On PS$ps the LED is ORANGE\n\
    On Front Panel PWR LED is RED\n\
    20 Data Ports LINK/ACT LEDs are Blinking Green"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
    update
    if {$res=="OK"} {
      set ret 0
    } else {
      set gaSet(fail) "PS$ps LEDs are not ORANGE/RED"
      set ret -1
    }
    
    if {$ret==0} {
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Failed"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
  #       AddToLog $gaSet(fail)
        return -1
      }
    }  
    
    if {$ret==0} {
      RLSound::Play information
      set txt "Extract PS$ps"
      set res [DialogBox -type "OK Cancel" -icon /images/question -title "Hot Swap Test" -message $txt]
      update
      if {$res=="OK"} {
        set ret 0
      } else {
        set ret -2
      }
    }
    
    if {$ret==0} {
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Not exist"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
  #       AddToLog $gaSet(fail)
        return -1
      }
    } 
    
    if {$ret==0} {
      RLSound::Play information
#       set txt "Reinsert PS$ps and check Front Panel LED is RED"
      set txt "Reinsert PS$ps and it's power cord"
      set res [DialogBox -type "OK Cancel" -icon /images/question -title "Hot Swap Test" -message $txt]
      update
      if {$res=="OK"} {
        set ret 0
      } else {
        set gaSet(fail) "PS$ps Front Panel LED is not RED"
        set ret -2
      }
    }
  
    Power $ps on
    
    if {$ret==0} {
      RLSound::Play information
      set txt "Verify the following:\n\n\
      On PS$ps the LED is GREEN\n\
      On Front Panel PWR LED is GREEN"
      set res [DialogBox -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
      update
      if {$res=="OK"} {
        set ret 0
      } else {
        set gaSet(fail) "PS$ps LEDS are not GREEN"
        set ret -1
      }
    }
    
    if {$ret==0} {
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="OK"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"OK\""
  #       AddToLog $gaSet(fail)
        return -1
      }
    }
    
    
    if {$ret!=0} {break}
  }
  
  if {$ret==0} {
    set ret [MeaGenerator_Check]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc ID {run} {
  global gaSet
  Power all on
  set ret [PS_IDTest]
  return $ret
}

# ***************************************************************************
# DateTime
# ***************************************************************************
proc DateTime {run} {
  global gaSet
  Power all on
  set ret [DateTime_Test]
  return $ret
} 

# ***************************************************************************
# SFP_ID
# ***************************************************************************
proc SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open ./TeamLeaderFiles/sfpList.txt r]
    while {[gets $id line]>=0} {
      lappend glSFPs $line
    }
  close $id
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
 
 set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
      
  if {$b=="19"} {
    set portsL [list 3/1 3/2 3/3 3/4 1/1 1/2 1/3 1/4 1/5 1/6 1/7 1/8 2/1 2/2 2/3 2/4 2/5 2/6 2/7 2/8] 
  }
  foreach port $portsL {
    set ret [ReadEthPortStatus $port]
    if {$ret!="0"} {
      set ret [ReadEthPortStatus $port]
      if {$ret!="0"} {return $ret}
    }
  }
  return $ret
}  
# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  set pair $::pair 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  #set ret [ReadBarcode [PairsToTest]]
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  set ret [RegBC]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [LoadDefConf]
  return $ret
}
 
# ***************************************************************************
# DDR
# ***************************************************************************
proc DDR {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_single
# ***************************************************************************
proc DDR_single {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_multi
# ***************************************************************************
proc DDR_multi {run} {
  global gaSet
  Power all on
  for {set i 1} {$i<=$gaSet(ddrMultyQty)} {incr i} {
    set ret [DdrTest $i]
    if {$ret!=0} {break}
    Power all off
    after 2000
    Power all on
  }  
  return $ret
}
# ***************************************************************************
# BootDownload
# ***************************************************************************
proc BootDownload {run} {
#  28/01/2021 08:57:23
#   set ret [20secPromptPerf]
#   if {$ret!=0} {return $ret}
  
  set ret [Boot_Download]
  if {$ret!=0} {return $ret}
  
  set ret [FormatFlashAfterBootDnl]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SetDownload
# ***************************************************************************
proc SetDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer
  
  set ret [EntryBootMenu]
  puts "Pages Ret of EntryBootMenu:<$ret>"
  if {$ret!=0} {return $ret}
  
  set ret [GetPageFile $gaSet($::pair.barcode1)  $gaSet($::pair.traceId)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload {run} {
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DyingGaspConf
# ***************************************************************************
proc DyingGaspConf {run} {
  global gaSet
  
  set ret [8SFPP_Config dg]
  if {$ret!=0} {return $ret}
  
  Power all on
 
  set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGaspTest
# ***************************************************************************
proc DyingGaspTest {run} {
  global gaSet
  #Power all on
  set psOffOn 1
  set psOff   2
  Power $psOffOn on
  Power $psOff off
  for {set i 1} {$i<=3} {incr i} {
    if {$gaSet(act)==0} {return -2}
    Status "DyingGasp trial $i"
    set ret [DyingGaspPerf $psOffOn $psOff]
    #AddToLog "Result of DyingGasp trial $i : <$ret> "
    AddToPairLog $gaSet(pair) "Result of DyingGasp trial $i : <$ret> "
#     if {$gaSet(pair)=="5"} {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     } else {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     }
    puts "[MyTime] Ret of DyingGasp trial $i : $ret" ; update
    if {$ret==0} {break}
  }
  if {$ret==0} {
    Power $psOffOn on
    Power $psOff on
  }
  
  return $ret
}

# ***************************************************************************
# PowerSupplyTest
# ***************************************************************************
proc PowerSupplyTest {run} {
  set ret [PowerSupplyTestPerf]
  return $ret
}

# ***************************************************************************
# VoltageTest
# ***************************************************************************
proc VoltageTest {run} {
 set ret [VoltageTestPerf]
  return $ret
}
# ***************************************************************************
# On_Off
# ***************************************************************************
proc On_Off {run} {
  global gaSet gaGui gRelayState
  Status ""
  set retRet 0
  set offDur 30
  
  if ![llength $gaSet(entDUT)] {
    set gaSet(fail) "The \'UUT's barcode\' should contain at least one parameter"
    return -1
  } else {
    foreach {a b c} $gaSet(entDUT) {}
    puts "a:<$a> b:<$b> c:<$c>"; update
    if {[string is integer $a] && [string length $a]>0} {
      set offOnQty $a
    } else {
      set gaSet(fail) "The first parameter (OFF-ON cycles quantity) should be an integer"
      return -1
    }
    if {[string is integer $b] && [string length $b]>0} {
      set offDur $b
    } elseif {[string length $b]==0} {
      set offDur 30
    } else {
      set gaSet(fail) "The second parameter (OFF duration) should be an integer"
      return -1
    }
    if {[string length $c]==0} {
      set sof no
    } elseif {$c=="yes" || $c=="no"} {
      set sof $c
    } else {
      set gaSet(fail) "The third parameter (StopOnFail) should be \'yes\' or \'no\' or nothing"
      return -1
    }
  }
  
  #if {[string is integer $gaSet(entDUT)] && [string length $gaSet(entDUT)]>0} {
  #  set offOnQty $gaSet(entDUT)
  #} else {
  #  set offOnQty 50
  #  set gaSet(entDUT) $offOnQty
  #}
  set r [set p [set f 0]]
  
  puts "offOnQty:<$offOnQty> offDur:<$offDur> sof:<$sof>"; update
  
  for {set i 1} {$i<=$offOnQty} {incr i} {
    Status "OFF-ON $i from $offOnQty"
    set r $i
    Power all off
    set ret [Wait "$offDur sec in OFF state" $offDur white]
    if {$ret!=0} {return $ret} 
    Power all on
    set ret [Login]
    if {$ret=="-2"} {return $ret}
    if {$ret==0} {
      set res PASS
      incr p
    } elseif {$ret=="-1"} {
      # if {[string match {*occured during*} $gaSet(fail)]} {
        # set res FAIL_$gaSet(fail)
      # } else {
        # set res FAIL
      # }
      set res FAIL_$gaSet(fail)
      set retRet -1
      incr f
    }
    puts "OFF-ON $i from $offOnQty. Res: $res\n"; update
    AddToPairLog $gaSet(pair) "OFF-ON $i Result:$res"
    #set st [$gaSet(startTime) cget -text]
    set st "$gaSet(logTime) Run:$r, Pass:$p, Fail:$f"
    $gaSet(startTime) configure -text $st
    if {$ret=="-1" && $sof=="yes"} {
      break
    }
  }
  return $retRet
}
