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
  
  set lTestsAllTests [list]
  set lDownloadTests [list BootDownload Pages ReflexProgramming ReflexDDRTest\
      SetDownload  SoftwareDownload]
  eval lappend lTestsAllTests $lDownloadTests
  
  lappend lTestNames SetToDefault
  lappend lTestNames SFP_ID ID PowerSupplyTest
  lappend lTestNames DyingGaspConf DyingGaspTest
  lappend lTestNames DataTransmission
  #lappend lTestNames DDR  ; #30/05/2019 07:05:38
  lappend lTestNames LedsTest ; # 28/04/2019 10:23:45 LedsTest1 LedsTest2
  lappend lTestNames HotSwap
  lappend lTestNames FinalSetToDefault Mac_BarCode
  
#   lappend lTestNames  OpenLicense SetToDefault
#    
#   lappend lTestNames ID SFP_ID USBport 
#   lappend lTestNames DyingGasp_conf DyingGasp_run
#   lappend lTestNames DataTransmission_conf DataTransmission_run
#   
#   if {$p=="P"} {
#     lappend lTestNames ExtClk  SyncE_conf SyncE_run
#   }
#   lappend lTestNames DDR 
# 
#   lappend lTestNames SetToDefault
#   lappend lTestNames  Leds_FAN_conf Leds_FAN 
#   if {$np=="npo" || $np=="2SFPP"} {
#     lappend lTestNames CloseLicense
#   } 
#   lappend lTestNames Mac_BarCode
#   
#   if {[string match *CEL* $gaSet(DutFullName)]} {
#     lappend lTestNames LoadDefaultConfiguration
#   }
  
  eval lappend lTestsAllTests $lTestNames
  
  set glTests ""
  set gaSet(TestMode) AllTests
  set lTests [set lTests$gaSet(TestMode)]
    
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
# LedsTest2
# ***************************************************************************
proc neLedsTest2  {run} {
  global gaSet
  set ret [LedsTest2_perf]
  return $ret
}  
# ***************************************************************************
# LedsTest1
# ***************************************************************************
proc neLedsTest1  {run} {
  global gaSet
  set ret [LedsTest1_perf]
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
  
  return $ret
}


# ***************************************************************************
# DataTransmission
# ***************************************************************************
proc DataTransmission  {run} {
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
    On Front Panel the PS$ps LED is RED\n\
    10GbE and 100GbE ports' GREEN \'LINK\' LEDs  are ON and YELLOW \'ACT\' LEDs are blinking"
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
      set txt "Extract PS$ps and check Front Panel LED is OFF"
      set res [DialogBox -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
      update
      if {$res=="OK"} {
        set ret 0
      } else {
        set gaSet(fail) "PS$ps Front Panel LED is not OFF"
        set ret -1
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
      set res [DialogBox -type "OK Fail" -icon /images/question -title "Hot Swap Test" -message $txt]
      update
      if {$res=="OK"} {
        set ret 0
      } else {
        set gaSet(fail) "PS$ps Front Panel LED is not RED"
        set ret -1
      }
    }
  
    Power $ps on
    
    if {$ret==0} {
      RLSound::Play information
      set txt "Verify the following:\n\n\
      On PS$ps the LED is GREEN\n\
      On Front Panel PS$ps LED is GREEN"
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
# USBport
# ***************************************************************************
proc neUSBport {run} {
  global gaSet
  set ret 0
   ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app
  
  set ret [CheckUsbPort]
  if {$ret!=0} {return $ret}
  
#   set ret [EntryBootMenu]
#   if {$ret!=0} {return $ret}
#   
#   set ret [DeleteUsbPortApp]
#   if {$ret!=0} {return $ret}
  
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
# SFPPlic
# ***************************************************************************
proc neSFPPlic {run} {
  global gaSet
  Power all on
  set ret [SFPPlicTest]
  return $ret
}

# ***************************************************************************
# DyingGasp_conf
# ***************************************************************************
proc neDyingGasp_conf {run} {
  global gaSet  buffer gRelayState
  Power all on
  Status "DyingGasp_conf"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DGaspCF)
  set cfTxt "Dying Gasp"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  Power all off
  after 1000
  Power all on
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  ##set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGasp_run
# ***************************************************************************
proc neDyingGasp_run {run} {
  global gaSet
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  MuxMngIO ioToPc ioToGen
  
  if {$up=="4SFP_0"} {
    ## uut with 4 sfp only connected to the ATE net by port 0/6
    set mngPort 0/6
  } else {
    ## all the rest products are connected to the ATE net by port 0/9
    set mngPort 0/9
  }
  set ret [SpeedEthPort $mngPort 100]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait Port $mngPort up" 40 white]
  if {$ret!=0} {return $ret}
  
  set ret [DyingGaspPerf 1 2]
  if {$ret!=0} {return $ret}
  
  Power all on
  set ret [Wait "Wait for ETX up" 20 white]
  if {$ret!=0} {return $ret}
  
  set ret [FactDefault std]
  if {$ret!=0} {return $ret}
  
  MuxMngIO ioToGenMngToPc ioToGen
  
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
# DataTransmission_conf
# ***************************************************************************
proc neDataTransmission_conf {run} {
  global gaSet
  Power all on    
  set ret [DataTransmissionSetup]
  return $ret
} 

# ***************************************************************************
# SFP_ID
# ***************************************************************************
proc SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open sfpList.txt r]
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
    set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10 0/11 0/12 0/13] 
  }
  foreach port $portsL {
    set ret [ReadEthPortStatus $port]
    if {$ret!="0"} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# DataTransmission_run
# ***************************************************************************
proc neDataTransmission_run {run} {
  global gaSet gRelayState
  Status "Init GENERATOR"
  set ret [RL10GbGen::Init $gaSet(id220)]  
  if {$ret!=0} {
    set gaSet(fail) "Init GENERATOR fail"
    return $ret
  } 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  switch -exact -- $b {
    19 {
      set 10GlineRate 50%
      set 1GlineRate  50%
    }
    Half19 {
      set 10GlineRate 90%
      set 1GlineRate  100%
    }
  }
  Status "Config GENERATOR"
  
  Etx220Config 1 $10GlineRate
  Etx220Config 5 $1GlineRate
  set ret [DataTransmissionTestPerf 10]  
  if {$ret!=0} {return $ret} 
  
  Etx220Config 1 $10GlineRate
  Etx220Config 5 $1GlineRate
  set ret [DataTransmissionTestPerf 120]  
  if {$ret!=0} {
#     Etx220Config 1 $10GlineRate
#     Etx220Config 5 $1GlineRate
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     Etx220Config 1 $10GlineRate
#     Etx220Config 5 $1GlineRate
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc neDataTransmissionTestPerf {checkTime} {
  global gaSet
  Power all on 
  
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  Etx220Start 1
  Etx220Start 5
  set ret [Wait "Data is running" $checkTime white]
  if {$ret!=0} {return $ret}
  Etx220Stop 1
  Etx220Stop 5
  set ret [Etx220Check 1]
  if {$ret!=0} {return $ret}
  set ret [Etx220Check 5]
  if {$ret!=0} {return $ret}
  
 
  return $ret
}  
# ***************************************************************************
# ExtClkUnlocked 
# ***************************************************************************
# proc ExtClkUnlocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Unlocked]
#   return $ret
# }
# ***************************************************************************
# ExtClkLocked
# ***************************************************************************
# proc ExtClkLocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Locked]
#   return $ret
#}
# ***************************************************************************
# ExtClk
# ***************************************************************************
proc neExtClk {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# Leds_FAN_conf
# ***************************************************************************
proc neLeds_FAN_conf {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
   set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set cf C:/AT-ETX-2i-10G/ConfFiles/mng_5.9.1.txt
  set cfTxt "MNG port"
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"    
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  set ret [RL10GbGen::Init $gaSet(id220)]  
  if {$ret!=0} {
    set gaSet(fail) "Init GENERATOR fail"
    return $ret
  } 
  
  switch -exact -- $b {
    19 {
      set 10GlineRate 50%
      set 1GlineRate  50%
    }
    Half19 {
      set 10GlineRate 90%
      set 1GlineRate  100%
    }
  }
  Status "Config GENERATOR"
  
  Etx220Config 1 $10GlineRate
  Etx220Config 5 $1GlineRate
  
  Etx220Start 1
  Etx220Start 5
  
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc neLeds_FAN {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set ret [FanStatusTest]
  if {$ret!=0} {return $ret}

  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2" "Manual Test"
  
  if {$gaSet(pair)==5} {
    set dutIp 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set dutIp 10.10.10.111
    } else {
      set dutIp 10.10.10.1[set gaSet(pair)]
    }  
  }
  catch {set pingId [exec ping.exe $dutIp] -t &]}
  
  set txt "1. Check 0.95V\n"
  RLSound::Play information
  if {$b=="19"} {
    set tstLedState ON
  } elseif {$b=="Half19"} {
    set tstLedState OFF ; # 21/11/2018 09:45:38
  }
  set txt1 "2. Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  RED \'TST/ALM\' led is $tstLedState\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON and Blinking respectively\n"
  
  set txt2_19 "On each PS GREEN \'PWR\' led is ON\n"
  set txt2_9 "" ; #"On PS GREEN \'PWR\' led is ON\n"
  
  set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
  GREEN \'LINK/ACT\' leds of 1GbE ports are Blinking\n\
  EXT CLK's GREEN \'SD\' led is ON (if exists)\n\
  FAN rotates"
  
  append txt $txt1
  if {$b=="19"} {
    append txt ${txt2_19}
  } elseif {$b=="Half19"} {
    append txt ${txt2_9}
  } 
  append txt $txt3
  
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
  update
  
  catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  #set ret [Loopback off]
  #if {$ret!=0} {return $ret} 
  
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
#   set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 
  
  if {$b=="19"} {
    foreach ps {2 1} {
      Power $ps off
      #after 10000
      set ret [Wait "Wait for PS-$ps is OFF" 5 white]
      if {$ret!=0} {return $ret}
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Failed"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
  #       AddToLog $gaSet(fail)
        return -1
      }
      RLSound::Play information
      set txt "Verify on PS-$ps that RED led is ON"
      set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
      
      RLSound::Play information
      set txt "Remove PS-$ps and verify that led is OFF"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      
      set val [ShowPS $ps]
      puts "val:<$val>"
      if {$val=="-1"} {return -1}
      if {$val!="Not exist"} {
        set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
  #       AddToLog $gaSet(fail)
        return -1
      }
      
  #     RLSound::Play information
  #     set txt "Verify on PS $ps that led is OFF"
  #     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  #     update
  #     if {$res!="OK"} {
  #       set gaSet(fail) "LED Test failed"
  #       return -1
  #     } else {
  #       set ret 0
  #     }
      
      RLSound::Play information
      set txt "Assemble PS-$ps"
      set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      Power $ps on
      after 2000
    }
  }
  
#   RLSound::Play information
#   set txt "Verify EXT CLK's GREEN SD led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  if {$p=="P"} {
    RLSound::Play information
    set txt "Remove the EXT CLK cable and verify the SD led is OFF"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
  }
 
#   set ret [TstAlm off]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is OFF"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  RLSound::Play information
  set txt "Disconnect all cables and optic fibers (except POWER and CONTROL) and verify GREEN leds are OFF\n\
  and RED \'TST/ALM\' led is ON"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
#   set ret [TstAlm on]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  return $ret
}
# ***************************************************************************
# OpenLicense
# ***************************************************************************
proc neOpenLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [LicensePerf Open]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefault_CloseLicense
# ***************************************************************************
proc neSetToDefault_CloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda Close]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# CloseLicense
# ***************************************************************************
proc neCloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [LicensePerf Close]
  if {$ret!=0} {return $ret}
  
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
# MacSwID
# ***************************************************************************
proc neMacSwID {run} {
   set ret [MacSwIDTest]
  if {$ret!=0} {return $ret}
  
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
  set ret [20secPromptPerf]
  if {$ret!=0} {return $ret}
  
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
  
  set ret [GetPageFile $gaSet($::pair.barcode1)]
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
# FanEepromBurn
# ***************************************************************************
proc neFanEepromBurn {run} {
  set ret [FanEepromBurnTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}  
# ***************************************************************************
# SyncE_conf
# ***************************************************************************
proc neSyncE_conf {run} {
  global gaSet
  if {$gaSet(pair)!="SE"} {
    set gaSet(fail) "It is no possible to perform SyncE test on this Tester"
    return -1
  }
  Power all on    
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set cf $gaSet([set b]SyncECF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  MuxMngIO ioToCnt ioToCnt
    
  return $ret
} 

# ***************************************************************************
# SyncE_run
# ***************************************************************************
proc neSyncE_run {run} {
  global gaSet
  if {$gaSet(pair)!="SE"} {
    set gaSet(fail) "It is no possible to perform SyncE test on this Tester"
    return -1
  }
  Power all on  
  after 2000
  MuxMngIO ioToCnt ioToCnt
  
  set ret [SyncELockClkTest] 
  if {$ret!=0} {return $ret}
  
  set ret [GpibOpen]
  if {$ret!=0} {
    set gaSet(fail) "Open channel to TDS fail"
    return $ret
  }
  
  set ret [ExistTds520B]
  if {$ret!=0} {return $ret}
  
  DefaultTds520b
  ##ClearTds520b
  after 2000
  SetLockClkTds   
  
  after 3000
  set ret [ChkLockClkTds]
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [SyncELockClkTest]
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [CheckJitter 100]
  GpibClose
  if {$ret=="-1" || $ret=="-2"} {return $ret}
  if {$ret>30} {
    set gaSet(fail) "Jitter: $ret nSec, should not exceed 30 nSec"
    set ret -1
  } else {
    set ret 0
  }
     
  return $ret
} 
# ***************************************************************************
# DyingGaspConf
# ***************************************************************************
proc DyingGaspConf {run} {
  global gaSet
  Power all on
  set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGaspTest
# ***************************************************************************
proc DyingGaspTest {run} {
  global gaSet
  Power all on
  for {set i 1} {$i<=3} {incr i} {
    if {$gaSet(act)==0} {return -2}
    Status "DyingGasp trial $i"
    set ret [DyingGaspPerf 1 2]
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
  
  return $ret
}
# ***************************************************************************
# SetDownloadDdrTest
# ***************************************************************************
proc neSetDownloadDdrTest {run} {
  set ret [SetDownloadDdrTestPerf]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# ReflexDDRTest
# ***************************************************************************
proc ReflexDDRTest {run} {
  set ret [SetDownloadDdrTestPerf]
  if {$ret!=0} {return $ret}
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DownloadDdrTestPerf]
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  } 
  
  set ret [Wait "Wait for Reflex LED" 10 white]
  if {$ret!=0} {return $ret}
  
  set txt "Verify the following:\n\n\
  Reflex LED is Green"
  RLSound::Play information
  set res [DialogBox -type "OK Fail" -icon /images/question -title "Reflex LED Test" -message $txt]
  update
  if {$res=="OK"} {
    set ret 0
  } else {
    set gaSet(fail) "Reflex LED Test fail"
    set ret -1
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
# ReflexProgramming
# ***************************************************************************
proc ReflexProgramming {run} {
  global gaSet buffer
  
  #Power all off
  
  ##26/05/2019 11:41:47 . Performed at Testing proc
#   set txt "Set SW2/2 to ON"
#   RLSound::Play information
#   set res [DialogBox -type "OK Cancel" -icon /images/info -title "SW2/2 ON" -message $txt]
#   update
#   if {$res=="OK"} {
#     set ret 0
#   } else {
#     set ret -2
#   }
#   if {$ret!=0} {return $ret}
  
  ##Power all on  ; ## power on will be performed by EntryDebugBootMenu
  
  set ret [EntryDebugBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [m_c29]
  if {$ret!=0} {return $ret}
  
  Wait "Wait for up" 10 white
  
#   set q_pgmPath C:/intelFPGA_pro/18.0/qprogrammer/bin64/quartus_pgm
  catch {exec [file dirname $gaSet(quartusPrg)]/jtagconfig -n} res
  puts "resJtagConfig:<$res>"
  catch {exec $gaSet(quartusPrg) --auto} res
  puts "resPrg:<$res>"
  if [string match {*Quartus Prime Programmer was successful. 0 errors, 0 warnings*} $res] {
    set ret 0
  } else {
    set ret -1
    set gaSet(fail) "Check programming cable fail"
  }
  
  if {$ret==0} {
    set res [regexp {ing cable\s+(.+)\nInfo} $res ma cable]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read programming cable fail"
    }
  }
  
  if {$ret==0} {
    Status "EPCQL1024 Programming.."
    set ::updateRunTimeEn 1
    set ::updateRunTimeCnt 1
    UpdateRunTime
    
    catch {exec $gaSet(quartusPrg) -c "JTAG USB \[USB-1\]" $gaSet(jicCdf)} res
    puts "[MyTime] res:<$res>"
    set ::updateRunTimeEn 0

    if [string match {*Quartus Prime Programmer was successful. 0 errors, 0 warnings*} $res] {
      set ret 0
    } else {
      set ret -1
      set gaSet(fail) "EPCQL1024 Programming fail"
    }
  }
  
  if {$ret==0} {
    Status "10M16SA Programming.."
    set ::updateRunTimeEn 1
    set ::updateRunTimeCnt 1
    UpdateRunTime
    
    catch {exec $gaSet(quartusPrg) -c "JTAG USB \[USB-1\]" $gaSet(pofCdf)} res
    puts "[MyTime] res:<$res>"
    set ::updateRunTimeEn 0

    if [string match {*Quartus Prime Programmer was successful. 0 errors, 0 warnings*} $res] {
      set ret 0
    } else {
      set ret -1
      set gaSet(fail) "10M16SA Programming fail"
    }
  }
  
  if {$ret==0} {
    Power all off
  
    set txt "Set SW2/2 to OFF"
    RLSound::Play information
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "SW2/2 OFF" -message $txt]
    update
    if {$res=="OK"} {
      set ret 0
    } else {
      set ret -2
    }
    if {$ret!=0} {return $ret}
    
    Power all on
  }
  
  return $ret
}