# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu"; update
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  if {[string match {*\[boot \(debug-mode\)\]:*} $buffer]==1} {
    return 0
  }
  
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  if {[string match {*\[boot \(debug-mode\)\]:*} $buffer]==1} {
    return 0
  }
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
  Status "Entry to Boot Menu"
  set gaSet(fail) "Entry to Boot Menu fail"
  set ret [Send $gaSet(comDut) \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:"]
  if {[string match {*\[boot \(debug-mode\)\]:*} $buffer]==1} {
    return 0
  }
  if {$ret!=0} {return $ret}
  return 0
}
# ***************************************************************************
# EntryDebugBootMenu
# ***************************************************************************
proc EntryDebugBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryDebugBootMenu"; update
  set ret [Send $gaSet(comDut) \r\r "\[boot \(debug-mode\)\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot \(debug-mode\)\]:" 2]
  if {$ret==0} {return $ret}
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
  Status "Entry to Debug Boot Menu"
  set gaSet(fail) "Entry to Debug Boot Menu fail"
  set ret [Send $gaSet(comDut) \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot \(debug-mode\)\]:"]
  if {$ret!=0} {return $ret}
  
  return 0
}


# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc PS_IDTest {} {
  global gaSet buffer
  Status "PS_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  
#   set ret [LogonDebug $com]
#   if {$ret!=0} {return $ret}
#   set gaSet(fail) "Login to MEA fail"
#   set ret [Send $com "debug mea\r\r\r" FPGA]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "mea port show\r" FPGA]
#   if {$ret!=0} {return $ret}
#   vv
#   set ret [Send $com "exit\r\r" ETX-2]
#   set ret [Send $com "exit\r\r" ETX-2]

  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
#   set ret [Send $com "info\r" more 80]  
#   regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  set ret [Send $com "le\r" ETX-2]  
  regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  puts "sw:$sw"
    
#   set ret [Send $com "\3" ETX-2 0.25]
#   if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  if {$gaSet(rbTestMode)=="PreHeat"} {
    ## don't check PSs before heat
  } else {
    if {$ps=="ACDC"} {
      set psQty 0
      incr psQty [regexp -all AC $buffer]
      incr psQty [regexp -all DC $buffer]
    } else {
      set psQty [regexp -all $ps $buffer]
    }
    if {$b=="19"} {
      set psQtyShBe 2
    }
    puts "PS_IDTest b:$b psQty:$psQty psQtyShBe:$psQtyShBe"
    if {$psQty!=$psQtyShBe} {
      set gaSet(fail) "Qty or type of PSs is wrong."
  #     AddToLog $gaSet(fail)
      return -1
    }
    #regexp {\-+\s(.+)\s+FAN} $buffer - psStatus
    regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
    if {$b=="19"} { 
      regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
    }
    set ps1Status [string trim $ps1Status]
    
    if {$ps1Status!="OK"} {
      set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
  #     AddToLog $gaSet(fail)
      return -1
    }
    
    if {$b=="19"} {
      regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
      set ps2Status [string trim $ps2Status]
      if {$ps2Status!="OK"} {
        set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
    #     AddToLog $gaSet(fail)
        return -1
      }
      
    }
  }
  
  regexp {FAN Status[\s-]+(.+)\sSensor} $buffer ma fanSt
  if ![info exists fanSt] {
    set gaSet(fail) "Can't read FAN Status"
    return -1
  }
  puts "fanSt:$fanSt"
  if {$b=="19"} { 
    if {$fanSt!="1 OK 2 OK 3 OK 4 OK"} {
      set gaSet(fail) "FAN Status is \'$fanSt\'"
      return -1
    }
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  #set gaSet(dbrSW) "6.6.1(0.17t2)"
  #20/02/2019 15:57:08
  #set gaSet(dbrSW) "6.6.1(0.32)"   ; #22/09/2019 09:50:47
  #set gaSet(dbrSW) "6.8.1(0.24)" ; # 28/01/2021 08:59:35 
  #set gaSet(dbrSW) "6.8.1(0.33)" ; # 16/02/2021 16:34:54
  ## as in DBR   24/05/2021 10:42:16
  puts "sw:$sw gaSet(dbrSW):$gaSet(dbrSW)"
  
  
  if {$sw!=$gaSet(dbrSW)} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
    return -1
  }
  
    
#   set ret [ReadCPLD]
#   if {$ret!=0} {return $ret}
  
  if {![info exists gaSet(uutBootVers)] || $gaSet(uutBootVers)==""} {
    set ret [Send $com "exit all\r" 2I]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin reboot\r" "yes/no"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "seconds" 20]
    if {$ret!=0} {return $ret}
    set ret [ReadBootVersion 1]
    if {$ret!=0} {return $ret}
  }
  
  # temporarely 18/12/2018 10:21:35
  #set gaSet(dbrBVer) 1.17
  
  #set gaSet(dbrBVer) 1.19 ; #28/01/2021 09:01:26
  

  puts "gaSet(uutBootVers):<$gaSet(uutBootVers)>"
  puts "gaSet(dbrBVer):<$gaSet(dbrBVer)>"
  if {[string index $gaSet(dbrBVer) 0]=="B"} {
    set dbrBVer [string range $gaSet(dbrBVer) 1 end]
  } else {
    set dbrBVer $gaSet(dbrBVer)
  }
  puts "dbrBVer:<$dbrBVer>"
  update
  if {$gaSet(uutBootVers)!=$dbrBVer} {
    set gaSet(fail) "Boot Version is \"$gaSet(uutBootVers)\". Should be \"$dbrBVer\""
    return -1
  }
  set gaSet(uutBootVers) ""
  

  return $ret
}
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 

  set ret [Wait "Wait for Management up" 120 white]
  if {$ret!=0} {return $ret}
   
  set wsDir C:\\Program\ Files\\Wireshark
  set npfL [exec $wsDir\\tshark.exe -D]
  ## 1. \Device\NPF_{3EEEE372-9D9D-4D45-A844-AEA458091064} (ATE net)
  ## 2. \Device\NPF_{6FBA68CE-DA95-496D-83EA-B43C271C7A28} (RAD net)
  set intf ""
  foreach npf [split $npfL "\n\r"] {
    set res [regexp {(\d)\..*ATE} $npf - intf] ; puts "<$res> <$npf> <$intf>"
    if {$res==1} {break}
  }
  if {$res==0} {
    set gaSet(fail) "Get ATE net's Network Interface fail"
    return -1
  }
  
  if {$gaSet(pair)==5} {
    set dutIp 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set dutIp 10.10.10.111
    } else {
      set dutIp 10.10.10.1[set gaSet(pair)]
    }  
  }
  #set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [PingTraps $intf $dutIp]
  if {$ret=="-1"} {
    set ret [Wait "Wait Management up" 20 white]
    if {$ret!=0} {return $ret}
    set ret [PingTraps $intf $dutIp]
    if {$ret!=0} {return $ret}
  }

  #file delete -force $resFile
  
  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
  set maxLogOutIn 5
  set resLogOutInFail 0
  for {set logOutIn 1} {$logOutIn<=$maxLogOutIn} {incr logOutIn} {
    puts "\n start logOutIn $logOutIn"
    if {$gaSet(act)==0} {return -2}
    #Send $gaSet(comDut) logout\r user
    after 1000
    Status "Wait for Login trap"
    set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
    set dur 6
    exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
    #catch {exec C:\\Program\ Files\\Wireshark\\tshark.exe -i $intf -O snmp -x -S lIsT -a duration:$dur  -A "c:\\temp\\tmp.cap" > [set resFile] &} rr
    #after 1000
    set dutIp 10.10.10.1[set gaSet(pair)]
    Send $gaSet(comDut) logout\r user
    Send $gaSet(comDut) su\r password
    Send $gaSet(comDut) 1234\r ETX
    if {$ret!=0} {return $ret}
    after "[expr {$dur +1}]000" ; ## one sec more then duration
    set id [open $resFile r]
      set monData [read $id]
      set ::md $monData 
    close $id  
  
    puts "\r[MyTime] logOutIn_$logOutIn resFile:$resFile ---<$monData>---\r"; update
    
    set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n" $monData]
    if {[llength $framsL]==0} {
      set gaSet(fail) "No frame from $dutIp was detected"
      incr resLogOutInFail
      continue
    }
    
    ## 6c 6f 67 69 6e    == login
    ## 6c 6f 67 6f 75 74 == logout
    set res 0
    foreach fram $framsL {
      puts "\rFrameA---<$fram>---\r"; update
      if {[string match *6c6f67696e* $fram] || [string match *6c6f676f7574* $fram] || \
          [string match *ogin* $fram] || [string match *ogout* $fram]} {
        set res 1
        file delete -force $resFile
        break
      }
    } 
    if {$res} {
      puts "\rFrameB---<$fram>---\r"; update
    }
    if {$res==1} {
      set ret 0
      break
    } elseif {$res==0} {
      set ret -1
      set gaSet(fail) "No \"Login\" trap was detected"
    }
      
    file delete -force $resFile  
  }
  
  puts "resLogOutInFail:$resLogOutInFail maxLogOutIn:$maxLogOutIn "
  if {$resLogOutInFail==$maxLogOutIn} {
    set ret -1
    set gaSet(fail) "No \"Login\" trap was detected"
  }
  if {$ret!=0} {return $ret}
  
  Power $psOffOn on
  Power $psOff off
  
  Status "Wait for Dying Gasp trap"
  set dur 10
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  catch {exec C:\\Program\ Files\\Wireshark\\tshark.exe -i $intf -O snmp -x -S lIsT -a duration:$dur  -A "c:\\temp\\tmp.cap" > [set resFile] &} rr
  #exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &  
     
  after 5000
  Power $psOffOn off
  after 2000
  Power $psOffOn on
  #Power $psOff on
  
  after "[expr {$dur + 1 - 5}]000" ; ## one more sec then duration  , minus 5 sec after starting of tshark
  
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\rMonData---<$monData>---\r"; update
  
  
  ## 4479696e672067617370
  ## D y i n g   g a s p
  #set framsL [wsplit $monData lIsT]
  set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n" $monData]
  if {[llength $framsL]==0} {
    set gaSet(fail) "No frame from $dutIp was detected"
    return -1
  }
  puts "\rDying gasp == 4479696e672067617370\r"; update
  set res 0
  foreach fram $framsL {
    puts "\rFrameA---<$fram>---\r"; update
    if {[string match "*Src: $dutIp*" $fram] && \
        ([string match *4479696e672067617370* $fram] ||  [string match {*Dying gasp*} $fram])} {
      set res 1
      #file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }
#   set frameQty [expr {[regexp -all "Frame " $monData] - 1}]
#   for {set fFr 1; set nextFr 2} {$fFr <= $frameQty} {incr fFr} {
#     puts "fFr:$fFr  nextFr:$nextFr"
#     if [regexp "Frame $fFr:.*\\sFrame $nextFr" $monData m] {
#       if [regexp "Src: [set dutIp].*" $m mm] {
#         if [string match *4479696e672067617370* $mm] {
#           puts $mm
#           set res 1
#         }
#       }
#     }
#     puts ""
#     
#     incr nextFr
#     if {$nextFr>$frameQty} {set nextFr 99}
#   }
# 
#   

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}


# ***************************************************************************
# DateTime_Test
# ***************************************************************************
proc DateTime_Test {} {
  global gaSet buffer
  Status "DateTime_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" >system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show system-date\r" >system]
  if {$ret!=0} {return $ret}
  
  regexp {date\s+([\d-]+)\s+([\d:]+)\s} $buffer - dutDate dutTime
  
  set dutTimeSec [clock scan $dutTime]
  set pcSec [clock seconds]
  set delta [expr abs([expr {$pcSec - $dutTimeSec}])]
  if {$delta>300} {
    set gaSet(fail) "Difference between PC and the DUT is more then 5 minutes ($delta)"
    set ret -1
  } else {
    set ret 0
  }
  
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    if {$pcDate!=$dutDate} {
      set gaSet(fail) "Date of the DUT is \"$dutDate\". Should be \"$pcDate\""
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
}

# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {} {
  global gaSet
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
    
  return $ret
}

# ***************************************************************************
# TstAlm 
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  
  set mac 00-00-00-00-00-00
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  set mac2 0x$mac1
  puts "mac1:$mac1" ; update
  if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {
    RLSound::Play fail
    set gaSet(fail) "The MAC of UUT is $mac"
    set ret [DialogBox -type "Terminate Continue" -icon /images/error -title "MAC check"\
        -text $gaSet(fail) -aspect 2000]
    if {$ret=="Terminate"} {
      return -1
    }
  }
  set gaSet(${::pair}.mac1) $mac1
  
  return 0
}

#***************************************************************************
#**  Login
#***************************************************************************
proc Login {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {[string match {*user>*} $buffer]==0} {
    set ret -1  
  } else {
    puts "Login user>" ; update
    set ret 0
  }
  if {[string match {*-2I*} $buffer]==0} {
    set ret -1  
  } else {
    puts "Login -2I" ; update
    set ret 0
    set gaSet(prmpt) "2I"
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
    Send $gaSet(comDut) n\r stam 1
    append gaSet(loginBuffer) "$buffer"
    puts "Login Are you sure?" ; update
  }
  if {[string match *WallGarden_TYPE-7* $buffer]} {
    set ret 0
    set gaSet(prmpt) "WallGarden_TYPE-7"
    puts "login lo:9 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ZTP* $buffer]} {
    set ret 0
    set gaSet(prmpt) "ZTP"
    puts "login lo:10 ret:<$ret>" ; update
    return 0
  }
   
   
  if {[string match *password* $buffer]} {
    set ret 0
    Send $gaSet(comDut) \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
    puts "Login password" ; update
  }
  if {[string match {*press a key*} $buffer]} {
    set ret 0
    Send $gaSet(comDut) \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
    puts "Login press a key" ; update
  }
  
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $gaSet(comDut) exit\r\r -2
    append gaSet(loginBuffer) "$buffer"
    puts "Login FPGA" ; update
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $gaSet(comDut) \x1F\r\r -2
  }
#   if {[string match *-2* $buffer]} {
#     set ret 0
#     puts "Login -2" ; update
#     return 0
#   }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    puts "Login C:\\" ; update
    return 0
  } 
  if {[string match *user>* $buffer]} {
    Send $gaSet(comDut) su\r stam 0.25
    set ret [Send $gaSet(comDut) 1234\r "ETX-2"]
    if {[string match *-2I* $buffer]} {
      set gaSet(prmpt) "-2I"
      set ret 0
      puts "login lo:1 ret:<$ret>" ; update
    }
    if {[string match *WallGarden_TYPE-7* $buffer]} {
      set gaSet(prmpt) "WallGarden_TYPE-7"
      set ret 0
      puts "login lo:2 ret:<$ret>" ; update
    }
    if {[string match *ZTP* $buffer]} {
      set gaSet(prmpt) "ZTP"
      set ret 0
      puts "login lo:3 ret:<$ret>" ; update
    }
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    #set ret [Wait "Wait for ETX up" 20 white]
    #if {$ret!=0} {return $ret}  
  }
  
  if ![info exists ::loginLoopsQty] {
    set ::loginLoopsQty 64
  }
  if ![info exists ::breakLoginOnError] {
    set ::breakLoginOnError 1
  }
  set wasBootError 0
  
  for {set i 1} {$i <= $::loginLoopsQty} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2"
    puts "Login into ETX-2 i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $gaSet(comDut) \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
        set gaSet(fail) "\'$ber\' occured during ETX's up"  
        set wasBootError $gaSet(fail)
        if $::breakLoginOnError {
          return -1
        }
      } else {
        ## 13:29 26/07/2022` puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2 user> } 5 60]
    if {[string match {*ETX-2*} $buffer]==1} {
      if {[regexp {Device\s+\:\s+ETX-2i-100G} $buffer]==1} {
        ## still in up progress
      } else {
        puts "if1.1 <$buffer>"
        set ret 0
        break
      }
    }
    if {[string match {*user>*} $buffer]==1} {
      Send $gaSet(comDut) \r\r stam 1
      if {[string match *user>* $buffer]} {
        puts "if1.2 <$buffer>"
        set ret 0
        break
      }
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $gaSet(comDut) run\r stam 1
      append gaSet(loginBuffer) "$buffer"
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $gaSet(comDut) \x1F\r\r -2I
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
    if {[string match *FPGA* $buffer]} {
      Send $gaSet(comDut) exit\r\r stam 1
      append gaSet(loginBuffer) "$buffer"
      puts "Login FPGA" ; update
    }
  }
  if {$ret==0} {
    if {[string match *user>* $buffer]} {
      Send $gaSet(comDut) \r\r stam 1
      if {[string match *user>* $buffer]} {
        Send $gaSet(comDut) su\r stam 1
        set ret [Send $gaSet(comDut) 1234\r "-2" 3]
        if {[string match *-2I* $buffer]} {
          set gaSet(prmpt) "-2I"
          set ret 0
          puts "login lo:19 ret:<$ret>" ; update
        }
        if {[string match *WallGarden_TYPE-7* $buffer]} {
          set gaSet(prmpt) "WallGarden_TYPE-7"
          set ret 0
          puts "login lo:21 ret:<$ret>" ; update
        }
        if {[string match *ZTP* $buffer]} {
          set gaSet(prmpt) "ZTP"
          set ret 0
          puts "login lo:22 ret:<$ret>" ; update
        }
      }
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2 Fail"
  }
  if {$wasBootError != 0} {
    set ret -1
    set gaSet(fail) $wasBootError
  }
  puts "login lo:24 ret:<$ret>" ; update
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# FormatFlash
# ***************************************************************************
proc FormatFlash {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  Power all on 
  
  return $ret
}
# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode contMode} {
  global gaSet buffer 
  Status "FactDefault $mode $contMode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  
  
  set gaSet(fail) "Set to Default fail"
  Send $com "exit all\r" stam 0.25 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "seconds" 20]
  if {$ret!=0} {return $ret}
  
  if {$contMode=="break"} {
    return $ret
  }
  
  set ret [ReadBootVersion 1]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait DUT down" 20 white]
  return $ret
}
# ***************************************************************************
# ReadBootVersion
# ***************************************************************************
proc ReadBootVersion {readPage3} {
  global gaSet buffer
  puts "ReadBootVersion $readPage3"
  set com $gaSet(comDut)
  set ::buff ""
  set gaSet(uutBootVers) ""
  set ret -1
  for {set sec 1} {$sec<20} {incr sec} {
    if {$gaSet(act)==0} {return -2}
    RLSerial::Waitfor $com buffer xxx 1
    puts "sec:$sec buffer:<$buffer>" ; update
    append ::buff $buffer
    if {[string match {*to view available commands*} $::buff]==1 || \
        [string match {*available commands*} $::buff]==1 || \
        [string match {*to view available*} $::buff]==1} {      
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Can't read the boot"
    return $ret
  }
  set res [regexp {Boot version:\s([\d\.\(\)]+)\s} $::buff - value]
  if {$res==0} {
    set gaSet(fail) "Can't read the Boot version"
    return -1
  } else {
    set gaSet(uutBootVers) $value
    puts "gaSet(uutBootVers):$gaSet(uutBootVers)"
    set ret 0
  }
  
  if {$readPage3=="1"} {
    set ret [EntryBootMenu]
    if {$ret!=0} {
      set gaSet(fail) "Can't entry into the boot"
      return $ret
    }
    
    Send $com "d2 00\r" boot 2
    regexp {Page 3:\s+([0-9\.A-Z]+)\s} $buffer ma val
    set pageBarcode ""
    foreach he [lrange [split $val .] 2 12] {
      append pageBarcode [format %c [scan $he %x]]
    }
    set guiBarcode [string range $gaSet(1.barcode1) 0 10]
    puts "ReadBootVersion pageBarcode:<$pageBarcode> guiBarcode:<$guiBarcode>"
    if {$pageBarcode != $guiBarcode} {
      set gaSet(fail) "Mismatch between Page3 and scanned Barcodes" 
      AddToPairLog $gaSet(pair) "Mismatch between Page3 (pageBarcode) and scanned (guiBarcode) Barcodes"
      return -1
    }
  }
  return $ret
}
# ***************************************************************************
# ShowPS
# ***************************************************************************
proc ShowPS {ps} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read PS-$ps status"
  set gaSet(fail) "Read PS-$ps status fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" Celsius]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    set res [regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val]
  } elseif {$ps==2} {
    set res [regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val]
  }
  if {$res==0} {
    if {$ps==1} {
      set res [regexp {1\s+\-\s+([\w\s]+)\s2} $buffer - val]
    } elseif {$ps==2} {
      set res [regexp {2\s+\-\s+([\w\s]+)\sFAN} $buffer - val]
    }
    if {$res==0} {
      set gaSet(fail) "Read PS-$ps status fail"
      return -1
    }
  }
  set val [string trim $val]
  puts "ShowPS val:<$val>"
  if {[lindex [split $val " "] 0] == "HP"} {
    set val [lrange [split $val " "] 1 end] 
  }
  return $val
}
# ***************************************************************************
# DateTime_Set
# ***************************************************************************
proc DateTime_Set {} {
  global gaSet buffer
  OpenComUut
  Status "Set DateTime"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
  }
  if {$ret==0} {
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure system\r" >system]
  }
  if {$ret==0} {
    set gaSet(fail) "Set DateTime fail"
    set ret [Send $com "date-and-time\r" "date-time"]
  }
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    set ret [Send $com "date $pcDate\r" "date-time"]
  }
  if {$ret==0} {
    set pcTime [clock format [clock seconds] -format "%H:%M"]
    set ret [Send $com "time $pcTime\r" "date-time"]
  }
  CloseComUut
  RLSound::Play information
  if {$ret==0} {
    Status Done yellow
  } else {
    Status $gaSet(fail) red
  } 
}
# ***************************************************************************
# LoadDefConf
# ***************************************************************************
proc LoadDefConf {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DefaultCF) 
  set cfTxt "DefaultConfiguration"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "successfull" 80]
  
  return $ret
}
# ***************************************************************************
# DdrTest
# ***************************************************************************
proc DdrTest {attm} {
  global gaSet buffer
  Status "DDR Test (attempt $attm)"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG (attempt $attm)"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read MEA LOG fail on attempt $attm"
  set ret [Send $com "debug mea\r\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea debug log show\r" FPGA>> 30]
  if {$ret!=0} {return $ret}
  
  if {[string match {*ENTU_ERROR*} $buffer]} {   
    set gaSet(fail) "\'ENTU_ERROR\' exists in the MEA log (attempt $attm)"
    return -1
  }
  if {[string match {*init DDR ..........................OK*} $buffer]==0} {
    set gaSet(fail) "\'init DDR ..OK\' doesn't exist in the MEA log (attempt $attm)"
    return -1
  }
  if {[string match {*DDR NOT OK*} $buffer]==1} {
    set gaSet(fail) "\'DDR NOT OK\' exists in the MEA log (attempt $attm)"
    return -1
  }
  
  set ret [Send $com "exit\r\r\r" ETX-2 16]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r\r" ETX-2 16]
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# DryContactTest
# ***************************************************************************
proc neDryContactTest {} {
  global gaSet buffer
  Status "Dry Contact Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2 1]
    if {$ret!=0} {return $ret}
  }      
  
  RLUsbPio::SetConfig $gaSet(idDrc) 11111000 ; # 3 first bits are OUT
  RLUsbPio::Set $gaSet(idDrc) xxxxx000 ; # 3 first bits are 0 
  
  set gaSet(fail) "Read MEA HW DRY fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea hw dry\r" dry>>]
  if {$ret!=0} {return $ret}
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf7"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf7\'"
    return -1
  }
  
  set ret [Send $com "read 1\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x1\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 1\' fail"
    return -1
  }
  if {$val!="0xff"} {
    set gaSet(fail) "The value of 0x1 is \'$val\'. Should be \'0xff\'"
    return -1
  }
  
  RLUsbPio::Set $gaSet(idDrc) xxxxx111 ; # 3 first bits are 1
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf0"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf0\'"
    return -1
  }
     
  set ret [Send $com "exit\r\r" ETX-2 16]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# ShowArpTable
# ***************************************************************************
proc ShowArpTable {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Show ARP Table fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure router 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show arp-table\r" (1)]
  if {$ret!=0} {return $ret}
  
  set lin1 "1.1.1.1 00-00-00-00-00-01 Dynamic"
  set lin2 "2.2.2.1 00-00-00-00-00-02 Dynamic"
   
  foreach lin [list $lin1 $lin2] {
    if {[string match *$lin* $buffer]==0} {
      set gaSet(fail) "The \'$lin\' doesn't exist"
      return -1
    }
  }

  return 0
}

# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  # Download:   
  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 40] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  return $ret
} 



# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {port} {
  global gaSet buffer bu glSFPs
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read EthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  if {$port=="0/1" || $port=="0/2" || $port=="0/3" || $port=="0/4"}  {
    set ret [Send $com "show status\r" $port]
  } else {
#     set ret [Send $com "show status\r" more]    24/05/2021 15:08:31
    set ret [Send $com "show status\r" stam 3]
  }
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  if {$port=="0/1" || $port=="0/2" || $port=="0/3" || $port=="0/4"}  {
    set res [regexp {QSFP\sIn} $bu - ]
  } else {
    set res [regexp {SFP\+?\sIn} $bu - ]
  }
  if {$res==0} {
    set gaSet(fail) "The status of port $port is not \'SFP In\'"
    return -1
  }
  
  set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)Typical} $bu - val]
  if {$res==0} {
    set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)SFP Manufacture Date} $bu - val]
    if {$res==0} {
      set gaSet(fail) "Read Manufacturer Part Number of SFP in port $port fail"
      return -1
    } 
  }
  set val [string trim $val]
  puts "val:<$val> glSFPs:<$glSFPs>" ; update
  if {[lsearch $glSFPs $val]=="-1"} {
    set gaSet(fail) "The Manufacturer Part Number of SFP in port $port is \'$val\'"
    return -1  
  }
  
  return 0
}

# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc SpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  
# ***************************************************************************
# ReadCPLD
# ***************************************************************************
proc ReadCPLD {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Read CPLD"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read CPLD"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2 1]
    if {$ret!=0} {return $ret}
  }      
  
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) ???
  } 
  set gaSet(fail) "Read CPLD fail"  
  set ret [Send $com "debug memory address c0100000 read char length 1\r" 2I]
  if {$ret!=0} {return $ret}
  set res [regexp {0xC0100000\s+(\d+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD value:<$value> gaSet(cpld):<$gaSet(cpld)>\n"; update
  if {$value!=$gaSet(cpld)} {
    set gaSet(fail) "CPLD is \'$value\'. Should be \'$gaSet(cpld)\'"  
    return -1
  }
  set gaSet(cpld) ""
  return $ret
}
# ***************************************************************************
# Boot_Download
# ***************************************************************************
proc Boot_Download {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Empty unit prompt"
  Send $com "\r\r" "=>" 2
  set ret [Send $com "\r\r" "=>" 2]
  if {$ret!=0} {
    # no:
    puts "Skip Boot Download" ; update
    set ret 0
  } else {
    # yes:   
    Status "Setup in progress ..."
    
    #dec to Hex
    set x [format %.2x $::pair]
    
    # Config Setup:
    Send $com "env set ethaddr 00:20:01:02:03:$x\r" "=>"
    Send $com "env set netmask 255.255.255.0\r" "=>"
    Send $com "env set gatewayip 10.10.10.10\r" "=>"
    Send $com "env set ipaddr 10.10.10.1[set ::pair]\r" "=>"
    Send $com "env set serverip 10.10.10.10\r" "=>"
    
    # Download Comment: download command is: run download_vxboot
    # the download file name should be always: vxboot.bin
    # else it will not work !
    if [file exists c:/download/temp/vxboot.bin] {
      file delete -force c:/download/temp/vxboot.bin
    }
    if {[file exists $gaSet(BootCF)]!=1} {
      set gaSet(fail) "The BOOT file ($gaSet(BootCF)) doesn't exist"
      return -1
    }
    file copy -force $gaSet(BootCF) c:/download/temp             
    #regsub -all {\.[\w]*} $gaSet(BootCF) "" boot_file
    
    
        
    # Download:   
    Send $com "run download_vxboot\r" stam 1
    set ret [Wait "Download Boot in progress ..." 10]
    if {$ret!=0} {return $ret}
    
    file delete -force c:/download/temp/vxboot.bin
    
    
    Send $com "\r\r" "=>" 1
    Send $com "\r\r" "=>" 3
    
    set ret [regexp {Error} $buffer]
    if {$ret==1} {
      set gaSet(fail) "Boot download fail" 
      return -1
    }  
    
    Status "Reset the unit ..."
    Send $com "reset\r" "stam" 1
    set ret [Wait "Wait for Reboot ..." 40]
    if {$ret!=0} {return $ret}
    
  }      
  return $ret
}
# ***************************************************************************
# FormatFlashAfterBootDnl
# ***************************************************************************
proc FormatFlashAfterBootDnl {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Format Flash after Boot Download"
  Send $com "\r\r" "Are you sure(y/n)?" 2
  set ret [Send $com "\r\r" "Are you sure(y/n)?" 2]
  if {$ret!=0} {
    puts "Skip Flash format" ; update
    set ret 0
  } else {
    Send $com "y\r" "\[boot\]:"
    puts "Format in progress ..." ; update
    set ret [MyWaitFor $com [list "boot]:"  "boot (debug-mode)"] 5 1300]
  }
  return $ret
}

# ***************************************************************************
# SetSWDownload
# ***************************************************************************
proc SetSWDownload {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  if {[file exists $gaSet(SWCF)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(SWCF)) doesn't exist"
    return -1
  }
     
  ## C:/download/SW/6.0.1_0.32/etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin -->> \
  ## etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp 
  
  #gaInfo(TftpIp.$::ID) = 10.10.8.1 (device IP)
  #gaInfo(PcIp) = "10.10.10.254" (gateway IP/server IP)
  #gaInfo(mask) = "255.255.248.0"  (device mask)  
  #gaSet(Apl) = C:/Apl/4.01.10sw-pack_203n.bin

  
  # Config Setup:
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }  
  
  return $ret  
}
# ***************************************************************************
# DeleteBootFiles
# ***************************************************************************
proc DeleteBootFiles {} {
  global  gaSet buffer
  set com $gaSet(comDut)
  
  Status "Delete Boot Files"
  Send $com "dir\r" "\[boot\]:"
  set ret0 [regexp -all {No files were found} $buffer]
  set ret1 [regexp -all {sw-pack-1} $buffer]
  set ret2 [regexp -all {sw-pack-2} $buffer]
  set ret3 [regexp -all {sw-pack-3} $buffer]
  set ret4 [regexp -all {sw-pack-4} $buffer]
  set ret5 [regexp -all {factory-default-config} $buffer]
  set ret6 [regexp -all {user-default-config} $buffer]
  set ret7 [regexp {Active SW-pack is:\s*(\d+)} $buffer var ActSw]
  set ret8 [regexp -all {startup-config} $buffer]
  
  
  if {$ret7==1} {set ActSw [string trim $ActSw]}
  
  # No files were found:
  if {$ret0!=0} {
    puts "No files were found to delete" ; update
    return 0
  }
  
  foreach SwPack "1 2 3 4" {
    # Del sw-pack-X:
    if {[set ret$SwPack]!=0} {
      if {([info exist ActSw]== 1) && ($ActSw==$SwPack)} {
        # exist:  (Active SW-pack is: 1)
        Send $com "delete sw-pack-[set SwPack]\r" "y/n"
        set res [Send $com "y\r" "deleted successfully" 40]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }      
      } else {
        # not exist: ("Active SW-pack isn't: X"   or  "No active SW-pac")
        set res [Send $com "delete sw-pack-[set SwPack]\r" "deleted successfully" 40]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }       
      }
      puts "sw-pack-[set SwPack] Delete" ; update
    } else {
      puts "sw-pack-[set SwPack] not found" ; update
    }
  }

  # factory-default-config:
  if {$ret5!=0} {
    set res [Send $com "delete factory-default-config\r" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "fac-def-config delete fail"
      return -1      
    } 
    puts "factory-default-config Delete" ; update      
  } else {
    puts "factory-default-config not found" ; update
  }
  
  # user-default-config:
  if {$ret6!=0} {
    set res [Send $com "delete user-default-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-def-config delete fail"
      return -1      
    } 
    puts "user-default-config Delete" ; update      
  } else {
    puts "user-default-config not found" ; update
  }
  
  # startup-config:
  if {$ret8!=0} {
    set res [Send $com "delete startup-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-str-config delete fail"
      return -1      
    } 
    puts "startup-config Delete" ; update      
  } else {
    puts "startup-config not found" ; update
  }  
    
  return 0
}
# ***************************************************************************
# FanEepromBurnTest
# ***************************************************************************
proc _FanEepromBurnTest {} {
  global gaSet buffer 
  Status "Fan EEPROM Burn"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Fan EEPROM Burn"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2 1]
    if {$ret!=0} {return $ret}
  }     
    
  set gaSet(fail) "Fan EEPROM Burn fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "mea util fan\r" fan]
  if {$ret!=0} {return $ret} 
  foreach {reg val} {0x00 0x11 0x05 0x2D 0x20 0x00 0x21 0x00 0x22 0x00 0x23 0x00\
                     0x24 0x00 0x25 0x00 0x26 0x00 0x27 0x00 0x28 0x00 0x29 0x00\
                     0x2A 0x00 0x2B 0x00 0x2C 0x00 0x2D 0x00 0x2E 0x00 0x2F 0x00\
                     0x30 0x33 0x31 0x4C 0x32 0x66 0x33 0x80 0x34 0x99 0x35 0xB2\
                     0x36 0xCC 0x36 0xE5 0x37 0xFF 0x02 0x01 0x5B 0x1F} {
    set ret [Send $com "Write $reg $val\r" fan]
    if {$ret!=0} {return $ret}                      
  }
  return $ret
}  
  
# ***************************************************************************
# Login205
# ***************************************************************************
proc Login205 {aux} {
  global gaSet buffer gaLocal
  set ret 0
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into AUX-$aux"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2 user>} 5 1]
  set com $gaSet(com$aux)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {([string match {*205A*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r 205A
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r 205A
  }
  if {[string match *205A* $buffer]} {
    set ret 0
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    return 0
  } 
  if {[string match *user* $buffer]} {
    Send $com su\r stam 0.25
    set ret [Send $com 1234\r "205A"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    set ret [Wait "Wait for Aux-$aux up" 20 white]
    if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 60} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into AUX-$aux"
    puts "Login into AUX-$aux i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $com \r stam 5
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*205A*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r 205A
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "205A"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to AUX-$aux Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# SyncELockClkTest
# ***************************************************************************
proc SyncELockClkTest {} {
  puts "[MyTime] SyncELockClkTest"
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Reading Clock's status"
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system clock\r" ">clock"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "domain 1\r" "domain(1)"]
  if {$ret!=0} {return $ret} 
  for {set i 1} {$i<=5} {incr i} {
    puts "\rattempt $i"
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set sysQlty [set sysClkSrc [set sysState ""]]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+Quality[\s:]+(\w+)\s} $buffer syst sysClkSrc sysState sysQlty
    set stat [set statClkSrc [set statState ""]]
    regexp {Station Out Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+} $buffer stat statClkSrc statState 
    puts "sysClkSrc:<$sysClkSrc> sysState:<$sysState> sysQlty:<$sysQlty>"
    puts "statClkSrc:<$statClkSrc> statState:<$statState>"
    update
    set fail ""
    if {$sysClkSrc=="2" && $sysState=="Locked" && $sysQlty=="PRC" && $statClkSrc=="2" && $statState=="Locked"} {
      set ret 0
      break
    } else {  
      if {$sysClkSrc!="1"} {
        append fail "System Clock Source: $sysClkSrc and not 1" , " "
      }  
      if {$sysState!="Locked"} {
        append fail "System Clock State: $sysState and not Locked" , " "
      }
      if {$sysQlty!="PRC"} {
        append fail "System Clock Quality: $sysQlty and not PRC" , " "
      }
      if {$statClkSrc!="1"} {
        append fail "Station Out Clock Source: $statClkSrc and not 1" , " "
      }
      if {$statState!="Locked"} {
        append fail "Station Out Clock State: $statState and not Locked"
      }
      set ret -1
      set fail [string trimright $fail]
      set fail [string trimright $fail ,]
      after 1000
    }
  }
  if {$ret=="-1"} {
    set gaSet(fail) "$fail"
  } elseif {$ret=="0"} {
    #set ret [Send $com "no source 1\r" "domain(1)"]
    #if {$ret!=0} {return $ret}
  }
  
  return $ret
} 
# ***************************************************************************
# PingTraps
# ***************************************************************************
proc PingTraps {intf dutIp} {
  global gaSet
  Status "Wait for Ping traps"
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  set dur 10
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
  after 1000
  
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  after "[expr {$dur +1}]000" ; ## one sec more then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r---<$monData>---\r"; update
  
  set res [regexp -all "Src: $dutIp, Dst: 10.10.10.10" $monData]
  puts "res:$res"
  if {$res<2} {
    set gaSet(fail) "2 Ping traps did not sent"
    return -1
  }
  return 0
}  
# ***************************************************************************
# FanStatusTest
# ***************************************************************************
proc FanStatusTest {} {
  global gaSet buffer
  Status "Fan Status Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  regexp {FAN Status[\s-]+(.+)\sSensor} $buffer ma fanSt
  if ![info exists fanSt] {
    set gaSet(fail) "Can't read FAN Status"
    return -1
  }
  puts "fanSt:$fanSt"
  if {$b=="Half19"} {
    if {$fanSt!="1 OK"} {
      set gaSet(fail) "FAN Status is \'$fanSt\'"
      return -1
    }
  } elseif {$b=="19"} { 
    if {$fanSt!="1 OK 2 OK 3 OK 4 OK"} {
      set gaSet(fail) "FAN Status is \'$fanSt\'"
      return -1
    }
  }
  
  return $ret
}

# ***************************************************************************
# LedsTest_perf
# ***************************************************************************
proc LedsTest_perf {} {
  global gaSet buffer
  Status "LEDs Test"
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set cf "c:/AT-ETX-2-100G-4Q/ConfFiles/Dying Gasp.txt"
  set cfTxt "MNG port"
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  set dutIp 10.10.10.1$gaSet(pair)
  catch {set pingId [exec ping.exe $dutIp -t &]} uu
  set txt "Verify the following:\n\n\
  PWR LED is Green\n\
  ALM LED is Red\n\
  20 LINK/ACT LEDs are Green\n\
  MNG-ETH LINK LED is Green and ACT LED is Orange\n\n\
  Fans rotate"
  RLSound::Play information
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LEDs Test" -message $txt]
  update
  if {$res=="OK"} {
    set ret 0
  } else {
    set gaSet(fail) "LEDs Test fail"
    set ret -1
  }
  catch {exec pskill.exe -t $pingId} ii
  if {$ret!=0} {return $ret}
  
  set txt "Remove SFPPs and QSFPs from all ports and verify that all the LINK leds are off"
  RLSound::Play information
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LEDs Test" -message $txt]
  update
  if {$res=="OK"} {
    set ret 0
  } else {
    set gaSet(fail) "LEDs Test fail"
    set ret -1
  }
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  set ret [LogonDebug $com]

 set gaSet(fail) "LEDs Test configuration fail"
  set ret [Send $com "debug mea\r\r\r" FPGA 11]
  if {$ret!=0} {return $ret}
  
  ## 0x00 = all leds off
  set ret [Send $com "m u ma write 0x8 0x00\r" FPGA]
  after 500
  
  ## 0x1 = ALM, 0x2 = TST, 0x3 = Alm+TST
  set ret [Send $com "m u ma write 0x8 0x03\r" FPGA]
  if {$ret!=0} {return $ret}
  
  set txt "Verify the following:\n\n\
  TST LED is Orange\n\
  ALR LED is Red"
  RLSound::Play information
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LEDs Test" -message $txt]
  update
  if {$res=="OK"} {
    set ret 0
  } else {
    set gaSet(fail) "LEDs Test fail"
    set ret -1
  }

  return $ret
  
}

# ***************************************************************************
# MeaGenerator_Start
# ***************************************************************************
proc MeaGenerator_Start {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set ret [LogonDebug $com]
  
  Wait "Wait for up" 60 white
  
  set ret [Send $com "debug mea\r\r" FPGA]
  if {$ret!=0} {
    after 500
    set ret [Send $com "\r\r" FPGA]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "mea test port\r" FPGA]
  if {$ret!=0} {return $ret}
  set ret [Send $com "start 2 80000 800000\r" FPGA]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# MeaGenerator_Check
# ***************************************************************************
proc MeaGenerator_Check {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read BIST Fail"
  set com $gaSet(comDut)
  set ret [LogonDebug $com]
  
  set ret [Send $com "debug mea\r\r" FPGA]
  #if {$ret!=0} {return $ret}
  #set ret [Send $com "mea test port\r" FPGA]
  #if {$ret!=0} {return $ret}
  
  Status "Read BIST results"
  Send $com \r stam 10
  
  set fail ""
  if [string match {*100G - Fail*} $buffer] {
    append fail " \'100G - Fail\' "  
  }
  if [string match {*10G - Fail*} $buffer] {
    append fail " \'10G - Fail\' "  
  }
  if {[string match {*error*} $buffer] || [string match {*mac_overflow*} $buffer]} {
    append fail " RX_error "  
  }
  if {[string match {*100G - OK*} $buffer] && [string match {*10G - OK*} $buffer]} {
    #set ret 0  
  } else {
    #set fail "10G and 100G are not OK"
  }
  
  set ret [Send $com "mea test port\r" FPGA]
  if {$ret!=0} {return $ret}
  set ret [Send $com "stop 2\r" FPGA]
  if {$ret!=0} {return $ret}
#   set ret [Send $com "mea test port show\r" FPGA]
#   if {$ret!=0} {return $ret}
#   
#   if {[llength [lrange $buffer [lsearch $buffer 10G] [lsearch $buffer FPGA>>]]]>9} {
#     ## old SW
#     set res [regexp {10G Tx[\.\s]+\d\s+(\d+)\s+10G Rx} $buffer ma 10GTx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (10GTx) fail"
#       return -1
#     }
#     set res [regexp {10G Rx[\.\s]+\d\s+(\d+)\s+100G Tx} $buffer ma 10GRx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (10GRx) fail"
#       return -1
#     }
#     set res [regexp {100G Tx[\.\s]+\d\s+(\d+)\s+100G Rx} $buffer ma 100GTx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (100GTx) fail"
#       return -1
#     }
#     set res [regexp {100G Rx[\.\s]+\d\s+(\d+)\s+FPGA} $buffer ma 100GRx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (100GRx) fail"
#       return -1
#     }
#   } else {
#     set res [regexp {10G Tx\.+(\d+)\s+10G Rx} $buffer ma 10GTx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (10GTx) fail"
#       return -1
#     }
#     set res [regexp {10G Rx\.+(\d+)\s+100G Tx} $buffer ma 10GRx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (10GRx) fail"
#       return -1
#     }
#     set res [regexp {100G Tx\.+(\d+)\s+100G Rx} $buffer ma 100GTx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (100GTx) fail"
#       return -1
#     }
#     set res [regexp {100G Rx\.+(\d+)\s+FPGA} $buffer ma 100GRx]
#     if {$res==0} {
#       set gaSet(fail) "Read MEA test (100GRx) fail"
#       return -1
#     }
#   }  
#   
#   set ret 0
#   foreach v [list 10GTx 10GRx 100GTx 100GRx] {
#     puts "$v:<[set $v]>"
#   }
#   set fail ""
#   foreach v [list 10GTx 10GRx 100GTx 100GRx] {
#     if {[set $v]==0} {
#       set gaSet(fail) "$v = 0"
#       return -1
#     }
#   }
#   if {$10GTx!=$10GRx} {
#     append fail "10G Tx($10GTx) != 10G Rx($10GRx) "
#   }
#   if {$100GTx!=$100GRx} {
#     append fail " 100G Tx($100GTx) != 100G Rx($100GRx)"
#   }
  if {$fail!=""} {
    set gaSet(fail) $fail
    set ret -1
  }
  
  return $ret
}
# ***************************************************************************
# LogonDebug
# ***************************************************************************
proc LogonDebug {com} {
  global gaSet buffer
  Send $com "exit all\r" stam 0.25 
  Send $com "logon debug\r" stam 0.25 
  Status "logon debug"
  if {[string match {*command not recognized*} $buffer]==0} {
#     set ret [Send $com "logon debug\r" password]
#     if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  } else {
    set ret 0
  }
  return $ret  
}
# ***************************************************************************
# 20secPromptPerf
# ***************************************************************************
proc 20secPromptPerf {} {
  global gaSet buffer buff
  set com $gaSet(comDut) 

  Power all off
  after 2000
  Power all on
  set buff ""
  set buffer ""
  Status "Wait 20 seconds for a first UUT message"
  set startSec [clock seconds]  
  set ret -1
  while 1 {
    set runSec [expr {[clock seconds] - $startSec}]
    $gaSet(runTime) configure -text $runSec ; update
    if {$runSec>20} {
      break
    } 
    RLSerial::Waitfor $com buffer stam 0.5
    puts "$runSec.buffer:<$buffer>"; update
    set buffer [string trim $buffer]
    puts "$runSec.buffer:<$buffer>"; update
    if [string is ascii $buffer] {
      append buff $buffer
      set bufferLen [string length $buff]
      puts "$runSec.buff:<$buff>"; update
#       if {[string match *\=\>* $buff] || $bufferLen>=10} {
#         set ret 0
#         break
#       }
    }
  
    if {$gaSet(act)==0} {
      return -2
    }
  }
  
  if {$buff!=""} {
    return 0
  } else {
    set gaSet(fail) "No message was received from UUT during the first 20 seconds"
    return -1
  }
}
# ***************************************************************************
# DyingGaspSetup
# ***************************************************************************
proc DyingGaspSetup {} {
  global gaSet buffer gRelayState
  Status "DyingGaspSetup"
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
  
  set goodPings 0
  set dutIp 10.10.10.1[set gaSet(pair)]  
  for {set i 1} {$i<=30} {incr i} {   
    set ret [Ping $dutIp]
    puts "DyingGaspSetup ping after download i:$i ret:$ret"
    if {$ret!=0} {return $ret}
    incr goodPings
    if {$goodPings==3} {
      break
    }
  }
  
  if 0 {
    ## 14:42 14/07/2022
    
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
      
    Power $psOffOn off
    after 2000
    Power $psOffOn on
    
    Wait "Wait ETX booting" 35
    if {$ret!=0} {return $ret}
    
    set ret [Login]
    if {$ret!=0} {
      #set ret [Login]
      if {$ret!=0} {return $ret}
    }
  }

  return $ret
}    
 
# ***************************************************************************
# SetDownloadDdrTestPerf
# ***************************************************************************
proc SetDownloadDdrTestPerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  set gaSet(swDdrTest) c:/download/SW/DdrTest/sw-pack_2i_100g.bin
  if {[file exists $gaSet(swDdrTest)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(swDdrTest)) doesn't exist"
    return -1
  }
     
  ## C:/download/SW/6.0.1_0.32/etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin -->> \
  ## etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin
  set tail [file tail $gaSet(swDdrTest)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(swDdrTest) c:/download/temp 
  
  #gaInfo(TftpIp.$::ID) = 10.10.8.1 (device IP)
  #gaInfo(PcIp) = "10.10.10.254" (gateway IP/server IP)
  #gaInfo(mask) = "255.255.248.0"  (device mask)  
  #gaSet(Apl) = C:/Apl/4.01.10sw-pack_203n.bin

  
  # Config Setup:
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }  
  
  return $ret  
} 

# ***************************************************************************
# DownloadDdrTestPerf
# ***************************************************************************
proc DownloadDdrTestPerf {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  set tail [file tail $gaSet(swDdrTest)]
  set rootTail [file rootname $tail]
  # Download:   
  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 40] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  return $ret

}

# ***************************************************************************
# PowerSupplyTestPerf
# ***************************************************************************
proc PowerSupplyTestPerf {} {
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
  foreach ps {1 2} {
    
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
      set models {FSF008-GS0G DPS-550AB-53 G1342-0550WRB} 
    } elseif {$psType eq "DC"} {
      set models {R1CD2551B-GS DPS-650AB-43 G1232-0550WRB}
    }  
    
    puts "MFR_MODEL:<$val> models:<$models>"
    #if {$model ne $val} {}
    if {[lsearch $models $val]=="-1"} {
      set gaSet(fail) "The MFR_MODEL is \'$val\'. Should be one of the \'$models\'"  
      return -1
    }
    
  } 
  return 0
}

# ***************************************************************************
# m_c29
# ***************************************************************************
proc m_c29 {} {
  global gaSet buffer
  puts "[MyTime] m_c29"; update
  set gaSet(fail) "Fail to set c2900000"
  set com  $gaSet(comDut)
  set ret [Send $com \r\r "\[boot \(debug-mode\)\]:" 2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "m c2900000\r" "0f0f-" 2]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "0a0a\r" "0f0f-" 2]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# VoltageTestPerf
# ***************************************************************************
proc VoltageTestPerf {} {
  global gaSet buffer buf
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  } 
  
  foreach {b r p d psType np up} [split $gaSet(dutFam) .] {}
  
  set com $gaSet(comDut)
  set gaSet(fail) "Logon fail"
  set ret [LogonDebug $com]
  
  set gaSet(fail) "Read Util Ps fail"
  set ret [Send $com "debug mea\r\r" FPGA]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea util ps\r" FPGA]
  if {$ret!=0} {return $ret}
  set ret [Send $com "vout\r" FPGA]
  if {$ret!=0} {return $ret}
  
  set res [regsub -all {\|} $buffer "" buf]
  if {$res==0} {
    set gaSet(fail) "Read Util Ps vout fail"
    return -1
  }
  
  set mP "MAIN"
  set mPtxt "MAIN (U68)"
  set min 3.135
  set max 3.465
  set shift 1
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccMIB(U113)"
  set mPtxt "VccMIB(U113)"
  set min 1.140
  set max 1.260
  set shift 0
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "SFP"
  set mPtxt "SFP (U108)"
  set min 3.135
  set max 3.465
  set shift 1
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccPT"
  set mPtxt "VccPT (U106)"
  set min 1.71
  set max 1.89
  set shift 1
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccRT"
  set mPtxt "VccRT (U110)"
  set min 0.855
  set max 0.945
  set shift 1
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccRAM(U100)"
  set mPtxt "VccRAM(U100)"
  set min 0.855
  set max 0.945
  set shift 0
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "S10"
  set mPtxt "S10 (U98)"
  set min 3.135
  set max 3.465
  set shift 1
  set ret [VerifyVoltageMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  
  set ret [Send $com "seq\r" FPGA]
  if {$ret!=0} {return $ret}
  set res [regsub -all {\|} $buffer "" buf]
  if {$res==0} {
    set gaSet(fail) "Read Util Ps seq fail"
    return -1
  }
  
  set mP "ViD"
  set mPtxt "ViD"
  set min 0.75
  set max 0.97
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccRAM"
  set mPtxt "VccRAM"
  set min 0.855
  set max 0.945
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccRT"
  set mPtxt "VccRT"
  set min 0.855
  set max 0.945
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccT"
  set mPtxt "VccT"
  set min 1.064
  set max 1.176
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccR"
  set mPtxt "VccR"
  set min 1.064
  set max 1.176
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccH"
  set mPtxt "VccH"
  set min 1.045
  set max 1.155
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccClk"
  set mPtxt "VccClk"
  set min 2.375
  set max 2.625
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccM"
  set mPtxt "VccM"
  set min 2.375
  set max 2.625
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccPT"
  set mPtxt "VccPT"
  set min 1.71
  set max 1.89
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  set mP "VccMIB"
  set mPtxt "VccMIB"
  set min 1.14
  set max 1.26
  set shift 0
  set ret [VerifySeqMP $mP $mPtxt $shift $min $max]
  if {$ret!=0} {return $ret}
  
  
  
#   set mpIndx [lsearch $buf $mP]
#   set vReq [lindex $buf [expr {$mpIndx+2}]]
#   set vRes [lindex $buf [expr {$mpIndx+3}]]
#   set iRes [lindex $buf [expr {$mpIndx+4}]]
#   AddToPairLog $gaSet(pair) "$mPtxt $vReq $vRes $iRes"
#   set val [string range $vRes 0 end-1]
#   set ret 0
#   if {$val<$min || $val>$max} {
#     set gaSet(fail) "$mPtxt is $vRes. Should be between $min and $max"
#     return -1
#   }
#   
#   set mP "VccMIB(U113)"
#   set mPtxt "VccMIB(U113)"
#   set mpIndx [lsearch $buf $mP]
#   set vReq [lindex $buf [expr {$mpIndx+1}]]
#   set vRes [lindex $buf [expr {$mpIndx+2}]]
#   set iRes [lindex $buf [expr {$mpIndx+3}]]
#   AddToPairLog $gaSet(pair) "$mPtxt $vReq $vRes $iRes"
#   set val [string range $vRes 0 end-1]
#   set min 1.140
#   set max 1.260
#   set ret 0
#   if {$val<$min || $val>$max} {
#     set gaSet(fail) "$mPtxt is $vRes. Should be between $min and $max"
#     return -1
#   }
#   

  
  
  return $ret
}
# ***************************************************************************
# 8SFPP_Config
# ***************************************************************************
proc 8SFPP_Config {mode} {
  global gaSet buffer
  Status "Config_8SFPP $mode"
  Power all on
  set ret [8SFPP_Login]
  if {$ret!=0} {
    #set ret [8SFPP_Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comAux)  
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "configure\r" config]
  if {$ret!=0} {return $ret}    
  set ret [Send $com "port\r" port]
  if {$ret!=0} {return $ret}  
  set ret [Send $com "ethernet 0/2\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "functional-mode user\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" port]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" config]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "flows\r" flows]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "no flow \"1_3\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"3_1\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"2_3\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"3_2\"\r" flows]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "no classifier-profile \"all\"\r" flows]
  if {$ret!=0} {return $ret}
  after 1000
  
  set ret [Send $com "classifier-profile \"all\" match-any\r" (all)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "match all\r" (all)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" flows]
  if {$ret!=0} {return $ret}
  
    
  if {$mode=="data"} {
    set flowName1 2_3
    set flow1ipo 0/2
    set flow1epo 0/3
    set flowName2 3_2
    set flow2ipo 0/3
    set flow2epo 0/2
  } elseif {$mode=="dg"} {
    set flowName1 1_3
    set flow1ipo 0/1
    set flow1epo 0/3
    set flowName2 3_1
    set flow2ipo 0/3
    set flow2epo 0/1
  }  
  set ret [Send $com "flow \"$flowName1\"\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "classifier \"all\"\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no policer\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ingress-port ethernet $flow1ipo\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "egress-port ethernet $flow1epo queue 0 block 0/1\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" $flowName1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" flows]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "flow \"$flowName2\"\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "classifier \"all\"\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no policer\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ingress-port ethernet $flow2ipo\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "egress-port ethernet $flow2epo queue 0 block 0/1\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" $flowName2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" flows]
  if {$ret!=0} {return $ret}

  return $ret 
}
# ***************************************************************************
# 8SFPP_Login
# ***************************************************************************
proc 8SFPP_Login {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
  set com $gaSet(comAux)
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set gaSet(prompt) "ETX-2i"
    set ret 0
  }
  puts "login lo:1 ret:<$ret>  buffer:<$buffer>" ; update
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
   append gaSet(loginBuffer) "$buffer"
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
    puts "login lo:2 ret:<$ret>" ; update
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r -2I
    append gaSet(loginBuffer) "$buffer"
    puts "login lo:3 ret:<$ret>" ; update
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r -2I
    puts "login lo:4 ret:<$ret>" ; update
  }
  if {[string match *-2I* $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    puts "login lo:5 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ETX-2i* $buffer]} {
    set gaSet(prompt) "ETX-2i"
    set ret 0
    puts "login lo:6 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ztp* $buffer]} {
    set ret 0
    set gaSet(prompt) "ztp"
    puts "login lo:7 ret:<$ret>" ; update
    return 0
  }
  if {[string match *CUST-LAB* $buffer]} {
    set ret 0
    set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
    puts "login lo:8 ret:<$ret>" ; update
    return 0
  }
  if {[string match *WallGarden_TYPE-5* $buffer]} {
    set ret 0
    set gaSet(prompt) "WallGarden_TYPE-5"
    puts "login lo:9 ret:<$ret>" ; update
    return 0
  }
  if {[string match *BOOTSTRAP-2I10G* $buffer]} {
    set ret 0
    set gaSet(prompt) "BOOTSTRAP-2I10G"
    puts "login lo:10 ret:<$ret>" ; update
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    puts "login lo:11 ret:<$ret>" ; update
    return 0
  } 
  if {[string match *user>* $buffer]} {
    Send $com su\r stam 1
    puts "login user1 prmpt:<$gaSet(prompt)> buffer:<$buffer>"
    set ret [Send $com 1234\r $gaSet(prompt)]
    if {[string match *ETX-2i* $buffer]} {
      set gaSet(prompt) "ETX-2i"
      set ret 0
      puts "login lo:12 ret:<$ret>" ; update
    }
    $gaSet(runTime) configure -text ""
    #set gaSet(prompt) "ETX-2I"
    puts "login user2 prmpt:<$gaSet(prompt)> ret:<$ret>"
    return $ret
  }
  if {$ret!=0} {
    #set ret [Wait "Wait for ETX up" 20 white]
    #if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 64} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2I"
    puts "Login into ETX-2I i:$i"; update
    $gaSet(runTime) configure -text $i; update
    Send $com \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX's up"  
        return -1
      } else {
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1 || [string match {*user>*} $buffer]==1 || \
        [string match {*-2i*} $buffer]==1) && ([string match {*Device*} $buffer]==0)} {      
      puts "if1 <$buffer>"
      set ret 0
      puts "login lo:13 ret:<$ret>" ; update
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
      append gaSet(loginBuffer) "$buffer"
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r -2I
      puts "login lo:14 0" ; update
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      puts "login lo:15 ret:<$ret>" ; update
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user>* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "2I" 3]
      if {[string match *220* $buffer]} {
        set gaSet(prompt) "ETX-220"
        set ret 0
        puts "login lo:16 ret:<$ret>" ; update
      }
      if {[string match *203* $buffer]} {
        set gaSet(prompt) "ETX-203"
        set ret 0
        puts "login lo:17 ret:<$ret>" ; update
      }
      if {[string match *ztp* $buffer]} {
        set gaSet(prompt) "ztp"
        set ret 0
        puts "login lo:18 ret:<$ret>" ; update
      }
      if {[string match *ETX-2I* $buffer]} {
        set gaSet(prompt) "ETX-2I"
        set ret 0
        puts "login lo:19 ret:<$ret>" ; update
      }
      if {[string match *CUST-LAB* $buffer]} {
        set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        set ret 0
        puts "login lo:20 ret:<$ret>" ; update
      }
      if {[string match *WallGarden_TYPE-5* $buffer]} {
        set gaSet(prompt) "WallGarden_TYPE-5"
        set ret 0
        puts "login lo:21 ret:<$ret>" ; update
      }
      if {[string match *BOOTSTRAP-2I10G* $buffer]} {
        set gaSet(prompt) "BOOTSTRAP-2I10G"
        set ret 0
        puts "login lo:22 ret:<$ret>" ; update
      } 
      if {[string match *ETX-2i* $buffer]} {
        set gaSet(prompt) "ETX-2i"
        set ret 0
        puts "login lo:23 ret:<$ret>" ; update
      }    
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2I Fail"
  }
  puts "login lo:24 ret:<$ret>" ; update
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}

# ***************************************************************************
# AdminReset
# ***************************************************************************
proc AdminReset {} {
  global gaSet buffer
  Status "Admin Reset"
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}

  set gaSet(fail) "Admin Reset fail"
  Send $com "exit all\r" stam 0.25 
  Status "Admin Reset"
  set ret [Send $com "admin reboot\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "System Boot" 30]
  if {$ret!=0} {return $ret}
 
  set ret [Login]
  return $ret
}
