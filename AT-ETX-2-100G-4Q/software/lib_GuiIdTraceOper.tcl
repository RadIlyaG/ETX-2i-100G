# ***************************************************************************
# GuiAddTraceId
# ***************************************************************************
proc GuiAddTraceId {{gui_id ""}} {
  global gaSet gaGui gaDBox
  set ret -1
  while 1 {
    set ret [DialogBox -title "Add TraceID $gui_id" -text "Scan the following:" -ent1focus 1\
          -type "Ok Cancel" -entQty 3 -entPerRow 1 -entLab [list "ID" "TraceID" "Operator"] -icon /images/uut48.ico] 
    if {$ret=="Cancel"} {
      return -1
    }
    set id $gaDBox(entVal1)
    set traceid $gaDBox(entVal2)
    set operid $gaDBox(entVal3)
    set chkId [CheckId $id]
    set chkTrace [CheckTraceId $traceid]
    set chkOper [CheckOper $operid]
    puts "$id <$chkId>, $traceid <$chkTrace>, $operid <$chkOper>"
    if {$chkId && $chkTrace && $chkOper!=0} {
      set ret 0
      break
    } elseif !$chkId {
      DialogBox -title "Wrong ID $gui_id" -text "Supplied ID $id is wrong" -type OK
    } elseif !$chkTrace {
      DialogBox -title "Wrong Trace ID $gui_id" -text "Supplied Trace ID $traceid is wrong" -type OK
    } elseif $chkOper==0 {
      DialogBox -title "Wrong Operator ID $gui_id" -text "Supplied Operator ID $operid is wrong" -type OK
    }
  }
  
  if {$ret==0} {
    set ret [AddLineIdTraceOper $id $traceid $chkOper]
  }
  
}

# ***************************************************************************
# proc
# ***************************************************************************
proc CheckId {id} {
  if {[string length $id]==11 || [string length $id]==12} {
    return 1
  } else {
    return 0
  }
}
# ***************************************************************************
# CheckTraceId
# ***************************************************************************
proc CheckTraceId {traceid} {
  puts "set traceid $traceid"
  if {[string length $traceid]>=8 && [string length $traceid]<12  && [string is integer [string trimleft $traceid "0"]]} {
    return 1
  } else {
    return 0
  }    
}
# ***************************************************************************
# CheckOper
# ***************************************************************************
proc CheckOper {operid} {
  if [string is integer $operid] {
    set empName [CheckOperInDB $operid]
    if {$empName!=""} {
      return $empName
    }
    if [file exists ./GetEmpName.exe] {
      set gn [pwd]
    } else {
      if [info exists ::RadAppsPath] {
        set gn $::RadAppsPath
      } else {
        set gn C:/RadApps
      }
    }
    set empName [GetOperRad $gn $operid]
    if {[regexp {Not[\s\w]+\!} $empName]} {
      return 0 
    } else {
      AddOperDB $operid $empName
      set gaSet(operatorID) $operid
      return $empName
    }    
  } else {
    return 0
  }
}
# ***************************************************************************
# AddLineIdTraceOper
# ***************************************************************************
proc AddLineIdTraceOper {barcode traceid operator} {
  global gaSet
  puts "\nAddLineIdTraceOper $barcode $traceid $operator"
  foreach {date tim} [split [clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"] " "] {break}
  set date "2024.06.30"
  for {set tr 1} {$tr <= 6} {incr tr} {
    if [catch {::RLWS::UpdateDB2 $barcode "" $gaSet(hostDescription) $date $tim Info traceid "" $operator $traceid "" "" "" ""} res] {
      set res "Try${tr}_fail.$res"
      puts "Web DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
      after [expr {int(rand()*3000+60)}] 
    } else {
      puts "Web DataBase is updated well!"
      set res "Try $tr passed"
      break
    }
  }
  
  return 0
}
