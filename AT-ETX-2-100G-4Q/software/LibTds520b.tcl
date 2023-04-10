proc GpibOpen {} {
  #***************************************************************************
  #** GpibOpen
  #***************************************************************************
  global gaSet
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Open $id 
  } else {
    set com $gaSet(gpibId)
    RLCom::Open $com 9600 8 NONE 1
  }
}

proc GpibClose {} {
  #***************************************************************************
  #** GpibClose
  #***************************************************************************
  global gaSet
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Close $id 
  } else {
    set com $gaSet(gpibId)
    RLCom::Close $com
  }
}


proc GpibSet {cmd} {
  #***************************************************************************
  #** GpibSet
  #***************************************************************************
  global gaSet
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Set $id "$cmd"
  } else {
    set com $gaSet(gpibId)
    RLCom::Send $com "$cmd\r"
    puts "send:$cmd"; update
    delaymSec 500 
  } 
}

proc GpibGet {cmd res} {
  #***************************************************************************
  #** GpibGet
  #***************************************************************************
  global gaSet
  if {[string match "*buffer*" $res]==1} {
    set d 4
  } else {
    set d 1
  }
  upvar $res buffer
  if {$gaSet(gpibMode)=="gpib"} {
    set id $gaSet(gpibId)
    RLGpib::Set $id "$cmd"
    RLGpib::Get $id buffer
  } else {
    set com $gaSet(gpibId)
    RLCom::Send $com "$cmd\r" buffer ">>>" $d 
    #puts "send:$cmd, recieve:$buffer"
    #delaymSec 500 
  }
}


proc ExistTds520B {id} {
  #***************************************************************************
  #** ExistTds520B
  #***************************************************************************
  catch {GpibGet "*idn?" buffer} err
  if {[string match "*TDS 520*" $buffer]==0} {
    UpdateAllOutputs "Fail: Wrong identification - $buffer (expected TDS 520)" tag(fail)
    CreateErrFile 2 ; return "abort"
  }
  return "ok"
}


proc DefaultTds520b {id} {
  #***************************************************************************
  #** DefaultTds520b
  #***************************************************************************
  GpibSet "autoset execute"
  delayn 6
  GpibSet "horizontal:trigger:position 50"
  GpibSet "trigger force"
}




proc ClearTds520b {id} {
  #***************************************************************************
  #** ClearTds520b
  #***************************************************************************
  GpibSet "clearmenu"
  GpibSet "measurement:meas1:state off"
  GpibSet "measurement:meas2:state off"
  GpibSet "measurement:meas3:state off"
  GpibSet "measurement:meas4:state off"
  GpibSet "select:ch1 off"
  GpibSet "select:ch2 off"
  GpibSet "select:ch3 off"
  GpibSet "select:ch4 off"
  GpibSet "ch1:impedance meg"
  GpibSet "ch2:impedance meg"
}


proc SetRippleTds520b {id divSec} {
  #***************************************************************************
  #** SetRippleTds520b
  #***************************************************************************
  UpdateAllOutputs "Set Scope : ripple test"
  ClearTds520b $id
  GpibSet "select:ch1 on"
  GpibSet "select:control ch1"
  GpibSet "data:source CH1"
  GpibSet "horizontal:secdiv $divSec"
  #GpibSet "horizontal:position 50"
  GpibSet "ch1:volts 2.0E-3"
  GpibSet "ch1:coupling ac"
  GpibSet "ch1:bandwidth twenty"
  GpibSet "ch1:position 0"
  GpibSet "trigger:main:mode auto"
  GpibSet "trigger:main:level 0"
  GpibSet "trigger:main:edge:coupling ac"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ac"
  #delayn 1
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  #delayn 1
  GpibSet "measurement:meas1:type pk2pk"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:state on"
}


proc GetRippleTds520b {id} {
  #***************************************************************************
  #** GetRippleTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : ripple test"
  GpibGet "curve?" buffer1
  set buffer2 [split [lindex $buffer1 1] ,]
  set len [llength $buffer2]
  set max 0
  for {set i 1} {$i<=3} {incr i} {
    GpibSet "measurement:meas1:type pk2pk"
    GpibSet "measurement:meas1:state on"
    delayn 1
    GpibGet "measurement:meas1:value?" ptp
    set ptp [expr [lindex $ptp 1]]
    puts ptp=$ptp
    if {$ptp>$max} {set max $ptp}
  }
  set res $max
  puts res=$res
  # if no signal
  if {$res<0.001} {
    UpdateConsole "pk2pk sample : $res"
    CreateErrFile 2 ; return 999
  }
  set res [expr [format %.4f $res]*1000]
  UpdateAllOutputs "The measured ripple is $res\mV"
  return $res
}



proc SetRippleAuxTds520b {id divSec} {
  #***************************************************************************
  #** SetRippleTds520b in aux1 channel
  #***************************************************************************
  UpdateAllOutputs "Set Scope aux : ripple test"
  ClearTds520b $id
  GpibSet  "select:ch3 on"
  GpibSet  "select:control ch3"
  GpibSet  "data:source CH3"
  GpibSet  "horizontal:secdiv $divSec"
  GpibSet  "ch3:volts 1.0E-2"
  GpibSet  "ch3:coupling ac"
  GpibSet  "ch3:bandwidth twenty"
  GpibSet  "ch3:position 0"
  GpibSet  "trigger:main:mode auto"
  GpibSet  "trigger:main:level 0"
  GpibSet  "trigger:main:edge:coupling ac"
  GpibSet  "trigger:main:edge:slope fall"
  GpibSet  "trigger:main:edge:source ac"

  GpibSet  "data:encdg ascii"
  GpibSet  "data:width 1"
  GpibSet  "data:start 1"
  GpibSet  "data:stop 500"

  GpibSet  "measurement:meas1:type pk2pk"
  GpibSet  "measurement:meas1:source1 ch3"
  GpibSet  "measurement:meas1:state on"
}



proc SetPowerFailure70-80 {id secDiv volt trig} {
  #***************************************************************************
  #** SetPowerFailure70-80
  #***************************************************************************
  UpdateAllOutputs "Set Scope : Power Failure test (70vAc & 80vAc)"
  ClearTds520b $id
  GpibSet "select:control ch2"
  GpibSet "select:ch2 on"
  GpibSet "data:source CH2"
  GpibSet "horizontal:secdiv $secDiv"
  GpibSet "ch1:volts $volt"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:bandwidth twenty"
  GpibSet "ch1:position 0"
  #delayn 1
  GpibSet "trigger:main:mode auto"
  GpibSet "trigger:main:level $trig"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch2"
}

proc GetPowerFailure70-80 {id state} {
  #***************************************************************************
  #** GetGetPowerFailure70-8 
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Power Failure test (70vAc & 80vAc)"
  GpibSet "data:source CH2"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  for {set i 1} {$i<=5} {incr i} {
    GpibGet "curve?" buffer1
    set buffer2 [split [lindex $buffer1 1] ,]
    set len [llength $buffer2]
    set max [expr round([::math::statistics::max "$buffer2"])]
    set min [expr round([::math::statistics::min "$buffer2"])]
    set res [expr $max-$min]
    puts buffer2=$buffer2
    puts "max,min: $max,$min"
    if {$state=="off"} {
      if {$max>100 || $min<60 || $len<400} {
        puts buffer2=$buffer2
        UpdateConsole "number of sample : $len"
        UpdateConsole "max sample : $max"
        UpdateConsole "min sample : $min"
        CreateErrFile 1 ; return "abort"
      } else {
        break
      }
    } else {
      if {$res<20 || $len<400} {
        puts buffer2=$buffer2
        UpdateConsole "number of sample : $len"
        UpdateConsole "max sample : $max"
        UpdateConsole "min sample : $min"
        if {$i==5} {
          CreateErrFile 2 ; return "abort"
        }
      } else {
        break
      }
    }
    delaymSec 400
  }
  GpibSet "measurement:meas1:source1 ch2"
  GpibSet "measurement:meas1:type maximum"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" maxRes
  GpibSet "measurement:meas2:source1 ch2"
  GpibSet "measurement:meas2:type minimum"
  GpibSet "measurement:meas2:state on"
  delayn 1
  GpibGet "measurement:meas2:value?" minRes
  set maxRes [expr [lindex $maxRes 1]]
  set minRes [expr [lindex $minRes 1]]
  puts "max:$maxRes , min:$minRes"
  UpdateAllOutputs "The measured pixels between the max and min is $res"
  UpdateAllOutputs "The measured voltage between the max and min is [expr $maxRes-$minRes] V"
  return $res
}



proc SetLimitProtectionTds520b {id secDiv volt trig} {
  #***************************************************************************
  #** SetLimitProtectionTds520b
  #***************************************************************************
  UpdateAllOutputs "Set Scope : current limit test"
  ClearTds520b $id
  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "data:source CH1"
  GpibSet "horizontal:secdiv $secDiv"
  GpibSet "ch1:volts $volt"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:bandwidth twenty"
  GpibSet "ch1:position 0"
  #delayn 1
  GpibSet "trigger:main:mode auto"
  GpibSet "trigger:main:level $trig"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch1"
}

proc SetTriggerNormalTds520b {id} {
  #***************************************************************************
  #** SetTriggerNormalTds520b
  #***************************************************************************
  GpibSet "trigger:main:mode normal"
}


proc GetLimitProtectionTds520b {id state {hicup on}} {
  #***************************************************************************
  #** GetLimitProtectionTds520b
  #***************************************************************************
  global gaGui
  UpdateAllOutputs "Get Scope : current limit test"
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  for {set i 1} {$i<=80} {incr i} {
    GpibGet "curve?" buffer1
    set buffer2 [split [lindex $buffer1 1] ,]
    set len [llength $buffer2]
    set max [expr round([::math::statistics::max "$buffer2"])]
    set min [expr round([::math::statistics::min "$buffer2"])]
    set res [expr $max-$min]
    puts buffer2=$buffer2
    puts "max,min: $max,$min"
    if {$state=="off"} {
      if {$max>90 || $min<45 || $len<400} {
        puts buffer2=$buffer2
        UpdateConsole "number of sample : $len"
        UpdateConsole "max sample : $max"
        UpdateConsole "min sample : $min"
        CreateErrFile 1 ; return "abort"
      } else {
        break
      }
    } else {
      if {$hicup=="off"} {
        if {$min>35 && $res<10} {
          puts buffer2=$buffer2
          UpdateConsole "max sample : $max"
          UpdateConsole "min sample : $min"
          if {$i==5} {
            CreateErrFile 2 ; return "abort"
          }
        } else {
          break
        }
      } elseif {$res<17 || $len<400} {
        puts buffer2=$buffer2
        UpdateConsole "number of sample : $len"
        UpdateConsole "max sample : $max"
        UpdateConsole "min sample : $min"
        if {$i==80} {
          CreateErrFile 3 ; return "abort"
        }
      } else {
        break
      }
    }
    delaymSec 400
  }
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:type maximum"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" maxRes
  GpibSet "measurement:meas2:source1 ch1"
  GpibSet "measurement:meas2:type minimum"
  GpibSet "measurement:meas2:state on"
  delayn 1
  GpibGet "measurement:meas2:value?" minRes
  set maxRes [expr [lindex $maxRes 1]]
  set minRes [expr [lindex $minRes 1]]
  UpdateAllOutputs "The measured pixels between the max and min is $res"
  UpdateAllOutputs "The measured voltage between the max and min is [expr $maxRes-$minRes] V"
  return $res
}


proc GetPeriodTds520b {id} {
  #***************************************************************************
  #** GetPeriodTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Check the width of the hikup"
  #GpibGet "curve?" buffer1
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:type pwidth"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" pwidth
  set pwidth [expr [lindex $pwidth 1]]
  puts "pwidth : $pwidth"
  if {$pwidth<0.001 || $pwidth>1} {
    UpdateAllOutputs "Fail: width of hikup out of range" tag(fail) 
    CreateErrFile 1 ; return "abort"
  }
}


proc SetOverVoltageProtectionTds520b {id} {
  #***************************************************************************
  #** SetOverVoltageProtectionTds520b
  #***************************************************************************
  UpdateAllOutputs "Set Scope : Set Over Voltage Protection test"

  ClearTds520b $id
  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "data:source CH1"
  GpibSet "ch1:coupling dc"
  delayn 4
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  #delayn 1
  GpibSet "trigger:main:mode normal"
  GpibSet "trigger:main:level 5.00"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope rise"
  GpibSet "trigger:main:edge:source ch1"
  GpibSet "ch1:volts 2.0"
  GpibSet "ch1:position 0"
  GpibSet "horizontal:secdiv 1.0E-2"

}

proc GetOverVoltageProtectionTds520b {id} {
  #***************************************************************************
  #** SetOverVoltageProtectionTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Get Over Voltage Protection test"
  delayn 2
  GpibSet "trigger force"
  delayn 2
  GpibSet "measurement:meas1:type maximum"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" maxRes1
  set maxRes1 [expr [lindex $maxRes1 1]]
  puts maxRes=$maxRes1
  delayn 2
  GpibSet "trigger:main:level 2.0"
  delayn 5
 # GpibGet "curve?" buffer1
 # set buf1 [split [lindex $buffer1 1] ,]
  GpibSet "measurement:meas1:type maximum"
  delayn 1
  GpibGet "measurement:meas1:value?" maxRes
  set maxRes [expr [lindex $maxRes 1]]
  UpdateConsole "max result2 : $maxRes"
  GpibSet "measurement:meas1:type minimum"
  delayn 1
  GpibGet "measurement:meas1:value?" minRes
  set minRes [expr [lindex $minRes 1]]
  UpdateConsole "min result2 : $minRes"
  if {$maxRes>4.1} {
    UpdateAllOutputs "Fail: Output voltage > 4.1v" tag(fail) 
    CreateErrFile 1 ; return "$maxRes"
  }
  if {$maxRes<2 || $minRes>1} {
    UpdateAllOutputs "Fail: Voltage does not attempt to raise" tag(fail) 
    CreateErrFile 2 ; return "$maxRes"
  }
  UpdateAllOutputs ""
  return "ok"
}


proc SetPowerFailureTds520b {id} {
  #***************************************************************************
  #** SetPowerFailureTds520b
  #***************************************************************************
#  global high
  UpdateAllOutputs "Set Scope : Power failure test"

  ClearTds520b $id
  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "select:ch2 on"
  GpibSet "data:source CH1"
  GpibSet "ch1:volts 1"
  GpibSet "trigger:main:mode auto"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:position 0"
  GpibSet "ch2:coupling dc"
  GpibSet "ch2:position 0"
  #delayn 1
  GpibSet "trigger:main:mode normal"
  GpibSet "trigger:main:level 2.1"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch2"
  GpibSet "ch1:volts 1"
  GpibSet "ch2:volts 1"
  GpibSet "horizontal:secdiv 5.0E-2"
  GpibSet "trigger force"
}


proc SetPowerFailure100Tds520b {id} {
  #***************************************************************************
  #** SetPowerFailure10Tds520b
  #***************************************************************************
#  global high
  UpdateAllOutputs "Set Scope : Power failure test"

  ClearTds520b $id
  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "select:ch2 on"
  GpibSet "data:source CH1"
  GpibSet "ch1:volts 1"
  GpibSet "trigger:main:mode auto"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:position 0"
  GpibSet "ch2:coupling dc"
  GpibSet "ch2:position 0"
  #delayn 1
  GpibSet "trigger:main:mode normal"
  GpibSet "trigger:main:level 2.1"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch2"
  GpibSet "ch1:volts 5"
  GpibSet "ch2:volts 5"
  GpibSet "horizontal:secdiv 2.0E-2"
  GpibSet "trigger force"
}




proc GetMaxMinTds520b {id min max} {
  #***************************************************************************
  #** GetMaxMinTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Voltage test"
  ClearTds520b $id
  delayn 8
  GpibSet "select:ch2 on"
  GpibSet "select:control ch2"
  GpibSet "data:source CH2"
  GpibSet "ch2:coupling dc"
  GpibSet "ch2:position 0"
  GpibSet "ch2:volts 1"
  GpibSet "trigger:main:mode auto"
  GpibSet "horizontal:secdiv 5.0E-2"
  GpibSet "ch1:volts 1"
  GpibSet "ch1:coupling dc"
  GpibSet "ch1:position 0"
  #delayn 1
  GpibSet "measurement:meas1:type high"
  GpibSet "measurement:meas1:source1 ch2"
  GpibSet "measurement:meas1:state on"
  GpibSet "measurement:meas2:type low"
  GpibSet "measurement:meas2:source1 ch2"
  GpibSet "measurement:meas2:state on"
  delayn 5
  GpibGet "measurement:meas1:value?" maxRes
  GpibGet "measurement:meas2:value?" minRes
  set maxRes [expr [lindex $maxRes 1]]
  set minRes [expr [lindex $minRes 1]]
  set res [expr ($maxRes+$minRes)/2.0]
  if {$res<$min || $res>$max || $minRes>$maxRes} {
    CreateErrFile 1 ; return "$res"
  }
  UpdateAllOutputs "The measured voltage is $res\V"
  return "ok"
}



proc GetPowerFailureTds520b {id t} {
  #***************************************************************************
  #** GetPowerFailureTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Power failure test"
  GpibSet "data:source CH1"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:type high"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" high
  set high [lindex $high 1]
  GpibSet "data:source CH1"
  GpibSet "measurement:meas2:source1 ch1"
  GpibSet "measurement:meas2:type maximum"
  GpibSet "measurement:meas2:state on"
  delayn 1
  GpibGet "measurement:meas2:value?" maxVolt
  set maxVolt [lindex $maxVolt 1]
  if {$high<2 || $maxVolt<2} {
    UpdateAllOutputs "Fail : Can't measure Ch-1 in the scope" tag(fail)
    puts "high=$high"
    puts "maxVolt=$maxVolt"
    CreateErrFile 1 ; return "999"
  }
  GpibSet "data:source CH2"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer1
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer2

  set secDiv "5.0E-2"
  set buf1 [split [lindex $buffer1 1] ,]
  set buf2 [split [lindex $buffer2 1] ,]
  set len1 [llength $buf1]
  set len2 [llength $buf2]
  UpdateConsole "len1=$len1,len2=$len2"
  set i 0
  while {[lindex $buf1 [expr $i+1]]>[expr [lindex $buf1 $i]/2.0]} {
    #puts "[lindex $buf1 [expr $i+1]]>[expr [lindex $buf1 $i]/2.0]"
    incr i
  }
  set r 0
  while {[lindex $buf2 [expr $r+3]]>[expr [lindex $buf2 $r]/1.20]} {
    incr r
  }
  if {$r>=499 || $r<=2} {
    UpdateAllOutputs "Fail : Ch-2 did not fall at all" tag(fail)
    puts "buf2=$buf2"
    puts "r:$r"
    CreateErrFile 1 ; return "999"
  }
  set fall $i
  set spp [expr ($len2/(10*$secDiv*1000))]
  set maxPixel [expr round([::math::statistics::max "$buf2"])]
  puts maxPixel=$maxPixel
  puts "fall_point: [expr int($fall+($t*$spp))]"
  set resThresholdPixel [lindex $buf2 [expr int($fall+($t*$spp))]]
  puts resThresholdPixel=$resThresholdPixel
  if {![info exists resThresholdPixel] || $resThresholdPixel==""} {
    UpdateAllOutputs "Fail : Ch-2 did not fall at all..." tag(fail)
    CreateErrFile 2 ; return "999"
  }
  set resThresholdVolt [format %.3f [expr ($maxVolt*$resThresholdPixel)/$maxPixel]]
  set thresholdVolt [expr $high-0.15]

  if {$resThresholdVolt>$maxVolt} {
    UpdateAllOutputs "Fail : Can't measure voltage (got $resThresholdVolt volt)" tag(fail)
    CreateErrFile 3 ; return "$resThresholdVolt"
  }
  if {$resThresholdVolt<=$thresholdVolt} {
    UpdateAllOutputs "Fail : The measured voltage after $t mSec is $resThresholdVolt (should be > $thresholdVolt )" tag(fail)
    CreateErrFile 4 ; return "$resThresholdVolt"
  }
  UpdateAllOutputs "The measured voltage after $t mSec is $resThresholdVolt"
  return "ok"
}


proc GetPowerFailure100Tds520b {id t} {
  #***************************************************************************
  #** GetPowerFailure100Tds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Power failure test"
  GpibSet "data:source CH1"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:type high"
  GpibSet "measurement:meas1:state on"
  delayn 1
  GpibGet "measurement:meas1:value?" high
  set high [lindex $high 1]
  GpibSet "data:source CH1"
  GpibSet "measurement:meas2:source1 ch1"
  GpibSet "measurement:meas2:type maximum"
  GpibSet "measurement:meas2:state on"
  delayn 1
  GpibGet "measurement:meas2:value?" maxVolt
  set maxVolt [lindex $maxVolt 1]
  if {$high<2 || $maxVolt<2} {
    UpdateAllOutputs "Fail : Can't measure Ch-1 in the scope" tag(fail)
    puts "high=$high"
    puts "maxVolt=$maxVolt"
    CreateErrFile 1 ; return "999"
  }
  GpibSet "data:source CH2"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer1
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer2

  set secDiv "2.0E-2"
  set buf1 [split [lindex $buffer1 1] ,]
  set buf2 [split [lindex $buffer2 1] ,]
  set len1 [llength $buf1]
  set len2 [llength $buf2]
  UpdateConsole "len1=$len1,len2=$len2"
  #puts ch-1=$buffer2
  #puts ch-2=$buffer1
  set i 0
  while {$i<499 && ([lindex $buf1 [expr $i+1]]<10 || [lindex $buf1 [expr $i+1]]<[expr [lindex $buf1 $i]*2.0])} {
    #puts "[lindex $buf1 [expr $i+1]]<[expr [lindex $buf1 $i]*2.0]"
    incr i
  }
  set r 0
  while {[lindex $buf2 [expr $r+3]]>[expr [lindex $buf2 $r]/1.20]} {
    incr r
  }
  if {$r>=499 || $r<=2} {
    UpdateAllOutputs "Fail : Ch-2 did not fall at all" tag(fail)
    puts "buf2=$buf2"
    puts "r:$r"
    CreateErrFile 1 ; return "999"
  }
  set rise $i
  puts rise_point_ch_2=$rise
  puts fall_point_ch_1=$r
  set spp [expr ($len2/(10*$secDiv*1000))]
  set maxPixel [expr round([::math::statistics::max "$buf2"])]
  puts maxPixel=$maxPixel
  puts "fall_point_threshold: [expr int($rise+($t*$spp))]"
  set resThresholdPixel [lindex $buf2 [expr int($rise+($t*$spp))]]
  puts resThresholdPixel=$resThresholdPixel
  if {![info exists resThresholdPixel] || $resThresholdPixel==""} {
    UpdateAllOutputs "Fail : Ch-2 did not rise at all..." tag(fail)
    CreateErrFile 2 ; return "999"
  }
  set resThresholdVolt [format %.3f [expr ($maxVolt*$resThresholdPixel)/$maxPixel]]
  set thresholdVolt [expr $high-0.35]

  if {$resThresholdVolt>$maxVolt} {
    UpdateAllOutputs "Fail : Can't measure voltage (got $resThresholdVolt volt)" tag(fail)
    CreateErrFile 3 ; return "$resThresholdVolt"
  }
  if {$resThresholdVolt<=$thresholdVolt} {
    UpdateAllOutputs "Fail : The measured voltage after $t mSec is $resThresholdVolt (should be > $thresholdVolt )" tag(fail)
    CreateErrFile 4 ; return "$resThresholdVolt"
  }
  UpdateAllOutputs "The measured voltage after $t mSec is $resThresholdVolt"
  return "ok"
}



proc SetHotSwapTds520b {id} {
  #***************************************************************************
  #** SetHotSwapTds520
  #***************************************************************************
  UpdateAllOutputs "Set Scope : Hot Swap test"

  ClearTds520b $id

  GpibSet "select:control ch1"
  GpibSet "select:ch1 on"
  GpibSet "data:source CH1"
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  #delayn 1
  GpibSet "ch1:coupling ac"
  GpibSet "ch1:volts 5.0E-2"
  GpibSet "ch1:position 0"
  GpibSet "horizontal:secdiv 1.0E-2"
  delayn 2
  GpibSet "trigger:main:mode normal"
  GpibSet "trigger:main:level 0"
  GpibSet "trigger:main:edge:coupling dc"
  GpibSet "trigger:main:edge:slope fall"
  GpibSet "trigger:main:edge:source ch1"
  GpibSet "trigger force"
}

proc ChangeHotSwapTds520b {id} {
  #***************************************************************************
  #** ChangeHotSwapTds520
  #***************************************************************************
  UpdateAllOutputs "Set Scope : Change Hot Swap test"
  GpibSet "trigger:main:mode auto"
  delayn 1
  GpibSet "trigger:main:mode normal"
  GpibSet "trigger force"
}


proc SetTriggerTds520b {id t} {
  #***************************************************************************
  #** SetTriggerTds520b
  #***************************************************************************
  GpibSet "trigger:main:level $t"
  delayn 1
} 


proc GetHotSwapTds520b {id} {
  #***************************************************************************
  #** GetHotSwapTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Hot Swap test"
  #GpibSet "trigger:main:level -0.15"
  #delayn 3
  GpibGet "curve?" buffer1
  #puts buffer1=$buffer1

  set buf1 [split [lindex $buffer1 1] ,]
  set len1 [llength $buf1]
  set i 0
  set j 0
  for {set i 0} {$i<=[expr $len1-1]} {incr i} {
    if {[lindex $buf1 $i]<-30} {
      incr j
      if {$j>10} {
        CreateErrFile 1 ; return "abort"
      }
    } else {
      if {$j<10} {
        set j 0
      } else {
        CreateErrFile 2 ; return "abort"
      }  
    }
  }
  return "ok"
}


proc GetChangeHotSwapTds520b {id} {
  #***************************************************************************
  #** GetChangeHotSwapTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Hot Swap test"
  #GpibSet "trigger:main:level -0.15"
  #delayn 3
  GpibGet "curve?" buffer1
  #puts buffer1=$buffer1

#  set secDiv "5.0E-2"
  set buf1 [split [lindex $buffer1 1] ,]
puts buf1=$buf1
  set len1 [llength $buf1]
  set i 0
  set j 0
  for {set i 0} {$i<=[expr $len1-1]} {incr i} {
    #puts j=$j
    if {[lindex $buf1 $i]<-30} {
      CreateErrFile 1 ; return "abort"
    }
  }
  return "ok"
}



proc GetHotSwapThresholdTds520b {id} {
  #***************************************************************************
  #** GetHotSwaThresholdpTds520b
  #***************************************************************************
  UpdateAllOutputs "Get Scope : Hot Swap test"
  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 1000"

  GpibGet "curve?" buffer1
  #puts buffer1=$buffer1
  set buf1 [split [lindex $buffer1 1] ,]
  puts buf1=$buf1
  set len1 [llength $buf1]
  set i 0
  set j 0
  for {set i 0} {$i<=[expr $len1-1]} {incr i} {
    #for secDiv 100mVolt the limit is 150
    #for secDiv 50mVolt the limit is 75
    if {[lindex $buf1 $i]<-75} {
        CreateErrFile 1 ; return "abort"
    }
  }
  return "ok"
}


proc CheckPowerFailureSignal {} {
  #***************************************************************************
  #** CheckPowerFailureSignal
  #***************************************************************************
  UpdateAllOutputs "Check Power Failure Signal"
  GpibSet "data:source CH2"
  GpibSet "measurement:meas3:source1 ch2"
  GpibSet "measurement:meas3:state on"
  GpibSet "measurement:meas3:type maximum"
  delayn 2
  GpibGet "measurement:meas3:value?" ch2maxVolt
  set ch2maxVolt [lindex $ch2maxVolt 1]
  if {$ch2maxVolt>2} {
    UpdateAllOutputs "Fail : power failure signal has an offset voltage of $ch2maxVolt v (should be 0v)" tag(fail)
    CreateErrFile 1 ; return "abort"
  }
  return "ok" 
}



proc GetScope {} {
  #***************************************************************************
  #** GetScope
  #***************************************************************************
  global gScope
  GpibSet "select:ch1 on"
  GpibSet "select:ch2 on"
  GpibGet "ch1:volts?" gScope(ch1)
  set gScope(ch1) [lindex $gScope(ch1) 1]
  set gScope(ch1) [ShowUnits $gScope(ch1) v]
  GpibGet "ch2:volts?" gScope(ch2)
  set gScope(ch2) [lindex $gScope(ch2) 1]
  set gScope(ch2) [ShowUnits $gScope(ch2) v]
  GpibGet "ch3:volts?" gScope(aux)
  set gScope(aux) [lindex $gScope(aux) 1]
  set gScope(aux) [ShowUnits $gScope(aux) v]
  GpibGet "horizontal:secdiv?" gScope(secdiv)
  set gScope(secdiv) [lindex $gScope(secdiv) 1]
  set gScope(secdiv) [ShowUnits $gScope(secdiv) sec]

  GpibSet "data:source CH1"
  GpibSet "measurement:meas1:type minimum"
  GpibSet "measurement:meas1:source1 ch1"
  GpibSet "measurement:meas1:state on"
  GpibSet "measurement:meas2:type maximum"
  GpibSet "measurement:meas2:source1 ch1"
  GpibSet "measurement:meas2:state on"

  GpibSet "data:source CH2"
  GpibSet "measurement:meas3:type minimum"
  GpibSet "measurement:meas3:source1 ch2"
  GpibSet "measurement:meas3:state on"
  GpibSet "measurement:meas4:type maximum"
  GpibSet "measurement:meas4:source1 ch2"
  GpibSet "measurement:meas4:state on"
  delayn 1

  GpibGet "measurement:meas1:value?" gScope(ch1Min)
  set gScope(ch1Min) [lindex $gScope(ch1Min) 1]
  set gScope(ch1Min) [ShowUnits $gScope(ch1Min) v]
  GpibGet "measurement:meas2:value?" gScope(ch1Max)
  set gScope(ch1Max) [lindex $gScope(ch1Max) 1]
  set gScope(ch1Max) [ShowUnits $gScope(ch1Max) v]

  GpibGet "measurement:meas3:value?" gScope(ch2Min)
  set gScope(ch2Min) [lindex $gScope(ch2Min) 1]
  set gScope(ch2Min) [ShowUnits $gScope(ch2Min) v]
  GpibGet "measurement:meas4:value?" gScope(ch2Max)
  set gScope(ch2Max) [lindex $gScope(ch2Max) 1]
  set gScope(ch2Max) [ShowUnits $gScope(ch2Max) v]

  GpibSet "data:source CH2"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer1
  set gScope(bufCh2) [split [lindex $buffer1 1] ,]


  GpibSet "data:source CH1"
  GpibSet "data:encdg ascii"
  GpibSet "data:width 1"
  GpibSet "data:start 1"
  GpibSet "data:stop 500"
  delayn 1
  GpibGet "curve?" buffer2
  set gScope(bufCh1) [split [lindex $buffer2 1] ,]


#  GpibSet "data:source CH3"
#  GpibSet "data:encdg ascii"
#  GpibSet "data:width 1"
#  GpibSet "data:start 1"
#  GpibSet "data:stop 500"
#  delayn 1
#  GpibGet "curve?" buffer3
#  set gScope(bufCh3) [split [lindex $buffer3 1] ,]


}


