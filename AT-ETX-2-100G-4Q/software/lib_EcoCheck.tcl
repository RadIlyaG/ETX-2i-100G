# ***************************************************************************
# MainEcoCheck
# MainEcoCheck ETX-2-100G-4QSFP-16SFPP-GB-M
# ***************************************************************************
proc MainEcoCheck {unit} {
  set ::db_file \\\\prod-svm1\\tds\\Temp\\SQLiteDB\\EcoCheck.db
  set ret [DbFileExists]
  if {$ret!=0} {return $ret}
  
  set ret [CheckDB $unit]
  if {$ret!=0} {
    foreach item $ret {
      append lis  "$item, "
    }
    set lis [string trimright $lis " ,"]
    if {[llength $lis]==1} {
      set verb "is"
    } else {
      set verb "are"
    }
    # set txt "The following change/s for \'$unit\' $verb released:\n\n$lis\n\nConsult with your team Leader"
    set txt "There $verb unapproved ECO/NPI/NOI for the tested option:\n\n$lis\n\n
    The ATE is locked. Contact your Team Leader"
    # tk_messageBox -message $txt -type ok -icon error -title "Unapproved changes"
    set ret $txt
  } 
  return $ret  
}
# ***************************************************************************
# DbFileExists
# ***************************************************************************
proc DbFileExists {} {
  if [file exists $::db_file] {
    return 0
  } else {
    return "The [file tail $::db_file] file doesn't exist at [file dirname $::db_file]"
  }
}

# ***************************************************************************
# CheckDB
# ***************************************************************************
proc CheckDB {unit} {
  sqlite3 dataBase $::db_file
  dataBase timeout 5000
  
  set res [lsort -unique [dataBase eval "Select ECO from ReleasedNotApproved where Unit = \'$unit\'"]]
  #puts "res:<$res>"
  if {$res==""} {
    set res 0
  }

  dataBase close
  return $res
}

if {[lindex $argv 0]=="Run"} {
  console show
  package require sqlite3
  set ret [MainEcoCheck ETX-2-100G-4QSFP-16SFPP-GB-M]
  if {$ret!=0} {
    tk_messageBox -message $ret -type ok -icon error -title "Unapproved changes"
  }
  # puts "MainEcoCheck ETX-2-100G-4QSFP-16SFPP-GB-M"
  #exit
}  
#console show



