# ***************************************************************************
# GpibOpen
# ***************************************************************************
proc GpibOpen {} {
  return [ViOpen]
}
# ***************************************************************************
# ViOpen 
# ***************************************************************************
proc ViOpen {} {
  global gaSet
  set ret -1
  package require tclvisa
  # #set visaAddr [visa::find $rm "USB0?*"]
  if 1 {
  foreach field3 [list 6023 6023 6023 6023 6023 6023 6023 903 903 903 6023 903 903] \
      DSOX1102ASerNumber [list CN58064160 CN57344642 CN56404126 CN58064279 \
      CN56404116 CN58174246 CN59014296 CN60182123 CN60182353 CN61022152\
      CN59284320 CN61482385 CN61482293] {
    puts "field3:$field3 DSOX1102ASerNumber:$DSOX1102ASerNumber"
    set visaAddr "USB0::10893::[set field3]::[set DSOX1102ASerNumber]::INSTR"
    if [catch { set rm [visa::open-default-rm] } rc] {
    # puts "Error opening default resource manager\n$rc"
    }
  
    if [catch { set gaSet(vi) [visa::open $rm $visaAddr] } rc] {
      close $rm
      puts "Error opening instrument `$visaAddr`\n$rc"
      set ret -1
    } else {
      set ret 0
      puts "OK"
      set ::DsScope A
      break
    }
  }
  if {$ret=="-1"} {
    foreach DSOX1102BSerNumber [list CN54030447 ] {
      puts "DSOX1102BSerNumber:$DSOX1102BSerNumber"
      set visaAddr "USB0::2391::1416::[set DSOX1102BSerNumber]::0"
      if [catch { set rm [visa::open-default-rm] } rc] {
        puts "Error opening default resource manager\n$rc"
      }
    
      if [catch { set gaSet(vi) [visa::open $rm $visaAddr] } rc] {
        close $rm
        puts "Error opening instrument `$visaAddr`\n$rc"
        set ret -1
      } else {
        set ret 0
        puts "OK"
        set ::DsScope B
        break
      }
    }
  }
  }
  
  if 0 {
  set ret 0
  if [catch {set rm [visa::open-default-rm]} rc] {
    puts "Error opening default resource manager\n$rc"
    set ret -1
  }
  if {$ret==0} {
    set visaAddr [visa::find $rm "USB0?*"]
    if {$visaAddr==""} {
      puts "Error, can't find scope"
      set ret -1
      close $rm
    } else {
      if [catch { set gaSet(vi) [visa::open $rm $visaAddr] } rc] {
        close $rm
        puts "Error opening instrument `$visaAddr`\n$rc"
        set ret -1
      } else {
        if [string match *USB0::0x2A8D* $visaAddr] {
          set ::DsScope A
        } elseif [string match *USB0::0x0957* $visaAddr] {
          set ::DsScope B
        } else {
          close $rm
          set ret -1
          puts "Error, unknown instrument [lindex  [split $::visaAddr ":"] 2]"
        }
        if {$ret==0} {
          puts "OK, visaAddr:<$visaAddr> <DsScope:$::DsScope>"               
        }
      }
    }
  }
  }
  #puts ""; update  
  
  if {$ret=="-1"} {
    return -1
  } 
  
  set gaSet(rm) $rm
  ViSet "*cls"
  return 0
}

# ***************************************************************************
# GpibClose
# ***************************************************************************
proc GpibClose {} {
  return [ViClose]
}
# ***************************************************************************
# ViClose
# ***************************************************************************
proc ViClose {} {
  global gaSet
  close $gaSet(vi)
  close $gaSet(rm)
  unset  gaSet(vi)
  unset  gaSet(rm)
}


# ***************************************************************************
# ViSet
# ***************************************************************************
proc ViSet {cmd} {
  global gaSet
  puts $gaSet(vi) "$cmd" 
}

# ***************************************************************************
# ViGet
# ***************************************************************************
proc ViGet {cmd res} {
  global gaSet buffer
  upvar $res buff
  ViSet $cmd
  set buff [gets $gaSet(vi)]
}
# ***************************************************************************
# ExistTds520B
# ***************************************************************************
proc ExistTds520B {} {
  return [ExistDSOX1102A]
}
# ***************************************************************************
# ExistDSOX1102A
# ***************************************************************************
proc ExistDSOX1102A {} {
  global gaSet 
  catch {ViGet "*idn?" buffer} err
  if {[string match "*DSO-X 1102A*" $buffer]==0} {
    set gaSet(fail) "Wrong scope identification - $buffer (expected DSO-X 1102A)"
    #return -1
  }
  return 0
}
proc DefaultTds520b {} {
  return [DefaultDSOX1102A]
}
# ***************************************************************************
# DefaultDSOX1102A
# ***************************************************************************
proc DefaultDSOX1102A {} {
  global gaSet
  Status "Set the DSOX1102A to default"
  ViSet "*cls"
  ClearDSOX1102A
  fconfigure $gaSet(vi) -timeout 500
  ViSet ":aut"  
  return {}
}
# ***************************************************************************
# ClearDSOX1102A
# ***************************************************************************
proc ClearDSOX1102A {} {
  Status "Clear DSOX1102A"
  ViSet :disp:cle
  ViSet ":chan1:disp 0"
  ViSet ":chan2:disp 0"
}


# ***************************************************************************
# SetLockClkTds
# ***************************************************************************
proc SetLockClkTds {} {
  puts "Set Scope : Lock Clock test"
  
  #GpibSet "select:control ch1"
  ViSet ":chan1:disp 1"
  ViSet ":chan2:disp 1"
  
  ViSet ":trig:mode edge"
  ViSet ":trig:edge:source chan1"
  ViSet ":trig:edge:lev 15" ; # 1.5
  ViSet ":trig:edge:coup dc"
#   ViSet ":trig:edge:slope neg" ; #21/11/2018 13:49:28
  ViSet ":trig:edge:slope pos"
  ViSet ":trig:force"
#   GpibSet "data:source CH1"
  ViSet ":chan1:prob 10"
  ViSet ":chan2:prob 10"
  #ViSet ":chan2:range 200V"
  ViSet ":chan1:coup dc"
#   ViSet ":chan1:offs 25V"
  ViSet ":chan2:coup dc"
#   ViSet ":chan2:offs -25V"
  ViSet ":tim:scal 1E-7" ; #2.5E-7
  after 1000
ViSet ":acq:type norm"
}

# ***************************************************************************
# ChkLockClkTds
# ***************************************************************************
proc ChkLockClkTds {} {
  global gaSet
  puts "Get Scope : Lock clock test"
  set gaSet(fail) ""
#   GpibSet "select:ch1 on"
#   GpibSet "select:control ch1"
  Status "Check freq at CH1"
  ViSet ":meas:freq chan1"
#   GpibSet "measurement:meas1:state on"
   after 100
  ViGet ":meas:freq?" freq1
  puts "freq1:<$freq1>" ; update
  if {[expr $freq1]>2060000 || [expr $freq1]<2030000} {
    set gaSet(fail) "Ch-1 is not 2.048MHz frequency (found [expr $freq1])"
    return -1
  }
  
  Status "Check freq at CH2"
#   GpibSet "select:ch2 on"
#   GpibSet "select:control ch2"
  ViSet ":meas:freq chan2"
#   GpibSet "measurement:meas2:state on"
   after 100
  ViGet ":meas:freq?" freq2
  puts "freq2:<$freq2>" ; update
  if {[expr $freq2]>2060000 || [expr $freq2]<2030000} {
    set gaSet(fail) "Ch-2 is not 2.048MHz frequency (found [expr $freq2])"
    return -1
  }
  
  ViSet ":tim:scal 5E-8"
  after 1000
  Status "Check edges"
  set checks 100
  set maxTry 3 
  
  if {$::DsScope=="A"} {
    for {set try 1} {$try <= $maxTry} {incr try} {
      puts "\n [MyTime] Try:$try"; update
      set ret -1
      set minch1 [set maxch1 [ViGet ":meas:tedge? +1, chan1" te]]
      set minch2 [set maxch2 [ViGet ":meas:tedge? +1, chan2" te]]
      ViSet ":meas:del chan1,chan2"
      set mindel [set maxdel 0]
      for {set i 1} {$i<=$checks} {incr i} {
        ## example p374
        foreach ch {1 2} {
          ViGet ":meas:tedge? +1, chan$ch" te
          if {$te<[set minch$ch] && $te!=""} {
            set minch[set ch] $te
          }
          if {$te>[set maxch$ch] && $te!=""} {
            set maxch[set ch] $te
          }
          set de [expr {[set maxch$ch] - [set minch$ch]}]
          #puts "try:$try i:$i minch$ch:[set minch$ch] maxch$ch:[set maxch$ch] de:$de" ; update
          after 50
        } 
      }
      puts "try:$try minch1:$minch1 maxch1:$maxch1 minch2:$minch2 maxch2:$maxch2"
      
      set ret 0
      foreach ch {2 1} {
        if {$ret ne "0"} {break}
        set de [expr {[set maxch$ch] - [set minch$ch]}]
        set delta [2nano [expr {[set maxch$ch] - [set minch$ch]}]]
        puts "[MyTime] try:$try ch-$ch delta:$delta nSec de:$de"
        if {$delta>100} {
          set ret -1
          set gaSet(fail) "The CH-$ch is not stable"
          if {$try eq $maxTry} {
            return -1
          }  
          continue
        } else {
          set ret 0
        }
        if {$ret eq "0"} {
          if {$delta>30} {
            set ret -1
            set gaSet(fail) "The Jitter at CH-$ch more then 30nSec ($delta nSec)"
            if {$try eq $maxTry} {
              return -1
            }
            continue
          } else {
            set ret 0
            break
          }
        }
      }
      if {$ret==0} {break}
    }
    puts "[MyTime] After Try:$try ret:$ret"
  } elseif {$::DsScope=="B"} {
    for {set i 1} {$i<=7} {incr i} {
      ViGet ":MEASure:PDELay? ch1,ch2" te
      regsub -all {<} $te "" te
      if {$te!="9.9e+037"} {
        set minPdly [set maxPdly $te]
        break
      }
      after 250  
    }
    puts "i:$i"
      
    after 100
    
    ViSet ":meas:del chan1,chan2"
    after 100
    for {set i 1} {$i<=$checks} {incr i} {
      ViGet ":MEASure:PDELay? ch1,ch2" te
      regsub -all {<} $te "" te
      #puts $te
      if {($te<$minPdly) && ($te!="") && ($te!="9.9e+037") } {
        set minPdly $te
      }
      if {($te>$maxPdly) && ($te!="") && ($te!="9.9e+037")} {
        set maxPdly $te
      }
      if {($i==10)||($i==20)||($i==30)||($i==40)||($i==50)||\
            ($i==60)||($i==70)||($i==80)||($i==90)||($i==100)} {
          puts "Delta Meas($i): \t Min--> $minPdly \t Max--> $maxPdly" ; update
      }
      after 50
    }
  
    # Jitter Result:
    set delta [2nano [expr {$maxPdly - $minPdly}]]
    puts "[MyTime] Jitter:  $delta nSec"
    if {$delta>100} {
      puts stderr "CH-2 Signal not stable"
      set gaSet(fail) "CH-2 Signal not stable" ; update
      return -1
    }
    if {$delta>30} {
      set gaSet(fail) "The Jitter at CH-2 more then 30nSec ($delta nSec)"
      puts stderr "CH2 Jitter is  more then 30nSec"
      set gaSet(fail) "CH2 Jitter is  more then 30nSec" ; update
      return -1
    }
    set ret 0
  }
  update 
  
  return $ret
}

# ***************************************************************************
# 2nano
# ***************************************************************************
proc 2nano {tim} {
  #puts "2nano $tim"
  #foreach {b ex} [split [string toupper $tim] E] {}
  foreach {b ex} [split [string toupper [format %E $tim ]] E] {}
  switch -exact -- $ex {
    -002 - -02 - -2 {set m 10000000}
    -003 - -03 - -3 {set m 1000000}
    -004 - -04 - -4 {set m 100000}
    -005 - -05 - -5 {set m 10000}
    -006 - -06 - -6 {set m 1000}
    -007 - -07 - -7 {set m 100}
    -008 - -08 - -8 {set m 10}
    -009 - -09 - -9 {set m 1}
    -010 - -10 {set m 0.1}
    -011 - -11 {set m 0.01}
    -012 - -12 {set m 0.001}
    default    {set m $ex}
  }
  set ret [expr {$b*$m}]
  puts "2nano $tim $ret"
  return $ret
}

# ***************************************************************************
# CheckJitter
# ***************************************************************************
proc CheckJitter {stam} {
  ## performed by ChkLockClkTds
  return 0
}