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
  
  if ![info exist ::uutIsPs] {
    set ::uutIsPs 0
  }
  puts "\n BuildTests ::uutIsPs:$::uutIsPs"
  if $::uutIsPs {
    PS_RetriveDutFam
  } else {
    RetriveDutFam
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set glTests ""
  set lTestsAllTests [list]
  if {$gaSet(rbTestMode) eq "On_Off"} {
    set lTests On_Off
  } else {
    if $::uutIsPs {
      lappend lTestNames PS_ID
      lappend lTestNames PS_DataTransmission
      lappend lTestNames HotSwap
      lappend lTestNames VendorSerial_ID
    } elseif !$::uutIsPs {
      set lDownloadTests [list BootDownload Pages SetDownload SoftwareDownload]
      eval lappend lTestsAllTests $lDownloadTests
      
      lappend lTestNames SetToDefault VoltageTest
      lappend lTestNames SFP_Id ID 
    
    
      if {$gaSet(rbTestMode)=="Full"} {
        lappend lTestNames PowerSupplyTest
        lappend lTestNames DyingGaspConf DyingGaspTest
      }
    
      lappend lTestNames DataTransmission_Set DataTransmission_FecOff DataTransmission_FecOn
    
      if {$gaSet(rbTestMode)=="Full"} {
        lappend lTestNames HotSwap        
        lappend lTestNames LedsTest ; # 28/04/2019 10:23:45 LedsTest1 LedsTest2
        ## 09:48 04/03/2024 lappend lTestNames FD_button
        lappend lTestNames FinalSetToDefault 
      
        if {$gaSet(DefaultCF)!="" && $gaSet(DefaultCF)!="c:/aa"} {
          lappend lTestNames LoadDefaultConfiguration CheckUserDefaultFile
        }
        
        if $::repairMode {
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
    set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "SW2/2 ON" -message $txt]
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
      if {$gaSet(rbTestMode) eq "On_Off"} {
        set gaSet(fail) "The OFF-ON Test fail. See log file" 
        set retTxt $gaSet(fail)
      } 
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
  
  if {$ret == 0 && [string match *.NULL.* $gaSet(DutInitName)]} {
    Power all off
    RLSound::Play information
    set txt "Remove PS-1 and PS-2"
    set res [DialogBoxRamzor -type "OK" -icon /images/info -title "No PS option" \
          -message $txt -bg yellow -font {TkDefaultFont 11}]
    update
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
  
  set ret [Login]
  
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
  
  
  if !$::uutIsPs {}
  set ret [8SFPP_Config data]
  
  return $ret
  
}  

# ***************************************************************************
# DataTransmission_FecOff
# ***************************************************************************
proc DataTransmission_FecOff  {run} {
  global gaSet
  Power all on
  
  set ret [FecMode off]
  if {$ret!=0} {return $ret}
  
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
# ***************************************************************************
# DataTransmission_FecOn
# ***************************************************************************
proc DataTransmission_FecOn  {run} {
  global gaSet
  Power all on
  
  set ret [FecMode on]
  if {$ret!=0} {return $ret}
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

# ***************************************************************************
# HotSwap
# ***************************************************************************
proc HotSwap {run} {
  global gaSet
  set ret [MeaGenerator_Start]
  if {$ret!=0} {return $ret}
  if $::uutIsPs {
    set PSs 1
  } else {
    set PSs {1 2}
  }
  foreach ps $PSs {
    if $::uutIsPs {
      set txt "Verify the following:\n\n\
    On PS$ps the LED is ORANGE\n\
    On Front Panel PWR LED is RED"
    } else {
      set txt "Verify the following:\n\n\
    On PS$ps the LED is ORANGE\n\
    On Front Panel PWR LED is RED\n\
    20 Data Ports LINK/ACT LEDs are Blinking Green"
    }
  
    Power $ps off
    
    RLSound::Play information
    set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
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
      set res [DialogBoxRamzor -type "OK Cancel" -icon /images/question -title "Hot Swap Test" -message $txt]
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
      set res [DialogBoxRamzor -type "OK Cancel" -icon /images/question -title "Hot Swap Test" -message $txt]
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
      set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
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
# ID
# ***************************************************************************
proc ID {run} {
  global gaSet
  Power all on
  if {[string match "*[lindex [info level 0] 0]*" $gaSet(startFrom)]} {
    set ret [Wait "Wait fot SFPs ..." 90]
    if {$ret!=0} {return $ret}
  }
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
# SFP_Id
# ***************************************************************************
proc SFP_Id {run} {
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
  
  if {[string match "*[lindex [info level 0] 0]*" $gaSet(startFrom)]} {
    set ret [Wait "Wait fot SFPs ..." 90]
    if {$ret!=0} {return $ret}
  }
  if {$run=="on_off"} {
    set ret [Wait "Wait fot SFPs ..." 90]
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
  
  set ret [Login]
  
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
  global gaSet
  if {[string match "*[lindex [info level 0] 0]*" $gaSet(startFrom)]} {
    set ret [Wait "Wait fot SFPs ..." 90]
    if {$ret!=0} {return $ret}
  }
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
    foreach {a b c d} $gaSet(entDUT) {}
    puts "a:<$a> b:<$b> c:<$c> d:<$d>"; update
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
    if {[string length $d]==0} {
      set onDur random
    } elseif {[string is integer $d]} {
      set onDur $d
    } else {
      set gaSet(fail) "The fourth parameter (ON duration) should be \'random\' or an integer or nothing"
      return -1
    }
  }
  
  set r [set p [set f 0]]
  set ::breakLoginOnError 0
  
  puts "offOnQty:<$offOnQty> offDur:<$offDur> sof:<$sof>"; update
  
  for {set i 1} {$i<=$offOnQty} {incr i} {
    Status "OFF-ON $i from $offOnQty"
    set r $i
    Power all off
    set ret [Wait "$offDur sec in OFF state" $offDur white]
    if {$ret!=0} {return $ret} 
    Power all on
    ## 08:48 08/02/2024 set ret [Login]
    set ret [SFP_Id on_off]
    if {$ret=="-2"} {return $ret}
    if {$ret==0} {
      set res PASS
      incr p
    } elseif {$ret=="-1"} {
      set res FAIL_$gaSet(fail)
      set retRet -1
      incr f
      AddToPairLog $gaSet(pair) "OFF-ON $i Result Power ON: $res"
      
      if {[string match {*occured during*} $gaSet(fail)]} {
        AddToPairLog $gaSet(pair) "Admin Reset"
        set ret [AdminReset]
        if {$ret=="-1"} {
          set resAR FAIL_$gaSet(fail)
          set retRet -1          
        } else {
          set resAR $ret
        }
        AddToPairLog $gaSet(pair) "OFF-ON $i Result after Admin Reset: $resAR"
      }
    }
    puts "OFF-ON $i from $offOnQty. Res: $res\n"; update
    if {$onDur=="random"} {
      set randMinutes [expr {int(10*rand())}]; set randSeconds [expr {60*$randMinutes}]
      if {$randMinutes==0} {set randMinutes 1}
      set randSeconds [expr {60*$randMinutes}]
    } else {
      set randSeconds $onDur
    }
    set ret [Wait "$randSeconds sec in ON state" $randSeconds white]
    AddToPairLog $gaSet(pair) "$randSeconds sec in ON state"
    AddToPairLog $gaSet(pair) "OFF-ON $i Result:$res"
    set st "$gaSet(logTime) Run:$r, Pass:$p, Fail:$f"
    $gaSet(startTime) configure -text $st
    if {$retRet=="-1" && $sof=="yes"} {
      break
    }
  }
  
  AddToPairLog $gaSet(pair) "-------------------"
  AddToPairLog $gaSet(pair) "Run:$r, Pass:$p, Fail:$f"
  return $retRet
}
# ***************************************************************************
# FD_button
# ***************************************************************************
proc FD_button {run} {
  set ret [FD_buttonPerf]
  if {$ret!=0} {return $ret}
  set ret [Login]
  return $ret
}

# ***************************************************************************
# CheckUserDefaultFile
# ***************************************************************************
proc CheckUserDefaultFile {run} {
  global gaSet 
  Power all on
  set ret [CheckUserDefaultFilePerf]
  return $ret 
}
# ***************************************************************************
# VendorSerial_ID
# ***************************************************************************
proc VendorSerial_ID {run} {
global gaSet 
  Power all on
  set ret [VendorSerialIDPerf]
  return $ret 
}