# ***************************************************************************
# MainEcoCheck
# MainEcoCheck DF1002650119 ETX-2-100G-4QSFP-16SFPP-GB-M
# ***************************************************************************
proc MainEcoCheck {barcode} {
  package require sqlite3
  package require json
  package require tls
  package require base64
  ::http::register https 8445 ::tls::socket
  ::http::register https 8443 ::tls::socket

  #global gaSet
  set ::db_file \\\\prod-svm1\\tds\\Temp\\SQLiteDB\\EcoCheck.db
  set ret [DbFileExists]
  if {$ret!=0} {return $ret}
  
  set di [Retrive_OperationItem4Barcode $barcode]
  puts "MainEcoCheck OperationItem4Barcode di:<$di>"
  if {[dict get $di "ret"]=="-1"} {
    return [dict get $di "fail"]
  } else {
    set dbr_asmbl_unit [dict get $di "item"]
  }
  set di [Retrive_MktPdn $dbr_asmbl_unit]
  puts "MainEcoCheck MktPdn di:<$di>"
  if {[dict get $di "ret"]=="-1"} {
    return [dict get $di "fail"]
  } else {
    set mkt_pdn_num [dict get $di "MKT_PDN"]
  }
  set unit $mkt_pdn_num
  set ret [CheckDB $unit]
  puts "\nMainEcoCheck unit:<$mkt_pdn_num> ret:<$ret>"

  if {$ret!=0} {
    foreach item $ret {
      append lis  "$item, "
    }
    set lis [string trimright $lis " ,"]
    if {[llength $lis]==1} {
      set verb "is an"
    } else {
      set verb "are"
    }
    # set txt "The following change/s for \'$unit\' $verb released:\n\n$lis\n\nConsult with your team Leader"
    set txt "There $verb unapproved ECO/NPI/NOI for the tested option:\n$lis\n
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
# ***************************************************************************
# Retrive_MktPdn
# ***************************************************************************
proc Retrive_MktPdn {dbr_asmbl_unit} {
  puts "\nRetrive_MktPdn $dbr_asmbl_unit"
  #set barc [format %.11s $barcode]
  #set url "http://webservices03:8080/ATE_WS/ws/rest/MKTPDNByBarcode?barcode=[set barc]"  
  
  set url "http://webservices03:8080/ATE_WS/ws/rest/MKTPDNByDBRAssembly?dbrAssembly=[set dbr_asmbl_unit]"
  #puts "url:<$url>"
  return [Retrive_WS $url]
} 
# ***************************************************************************
# Retrive_OperationItem4Barcode
# ***************************************************************************
proc Retrive_OperationItem4Barcode {barcode} {
  puts "\nRetrive_OperationItem4Barcode $barcode"
  set barc [format %.11s $barcode]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param OperationItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  #puts "url:<$url>"
  return [Retrive_WS $url]
} 

# ***************************************************************************
# Retrive_WS
# ***************************************************************************
proc Retrive_WS {url} {
  puts "\nRetrive_WS $url"
  dict set di ret 0
  dict set di fail ""
  if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
    after 2000
    if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
       dict set di fail "Fail to get OperationItem4Barcode for $barc"
       dict set di ret -1
       return $di
    }
  }
  
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  
  
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    dict set di ret -1
    dict set di fail "http::status: <$st> http::ncode: <$nc>"
    #set gaSet(fail) "http::status: <$st> http::ncode: <$nc>"; return -1
  }
  upvar #0 $tok state
  #parray state
  #puts "$state(body)"
  set body $state(body)
  ::http::cleanup $tok
  
  set asadict [::json::json2dict $body]
  foreach {name whatis} $asadict {
    foreach {par val} [lindex $whatis 0] {
      puts "<$par> <$val>"
      if {$val!="null"} {
        dict set di $par $val
      }  
    }
  }
  # if [info exist di] {
    # return $di ; #[dict get $di $retPar]
  # } else {
    # return -1
  # }
  return $di
}



if {[lindex $argv 0]=="Run"} {
  console show
  
  set ret [MainEcoCheck DF1002650119 ] ; #ETX-2-100G-4QSFP-16SFPP-GB-M
  if {$ret!=0} {
    tk_messageBox -message $ret -type ok -icon error -title "Unapproved changes"
  }
  # puts "MainEcoCheck ETX-2-100G-4QSFP-16SFPP-GB-M"
  #exit
}  
#console show



