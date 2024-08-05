package require http
package require tls
package require base64
package require json
::http::register https 8445 ::tls::socket

set ::debugWS 1

# console show
proc UpdateDB {barcode uutName hostDescription  date time status  failTestsList failDescription dealtByServer} {
  #***************************************************************************
  #** UpdateDB
  #***************************************************************************

  # convert some characters to ascii  for url address
  foreach f {uutName hostDescription failTestsList failDescription dealtByServer} {
    set url_$f [ConvertToUrl [set $f]]
  }
  puts "UpdateDB <$barcode> <$uutName> <$hostDescription> <$date> <$time> <$status> <$failTestsList> <$failDescription> <$dealtByServer>"
  #set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/add_row?barcode=DF123456789_4&uutName=uutName_4&hostDescription=hostDescription_4&date=date&time=time&status=status&failTestsList=failTestsList_1&failDescription=failDescription&dealtByServer=dealtByServer"
#   set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/add_row?barcode=$barcode&uutName=$url_uutName&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"
  set url "http://webservices03.rad.com:10211/ATE_WS/ws/tcc_rest/add_row?barcode=$barcode&uutName=$url_uutName&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"  
  puts "UpdateDB url:<$url>"
#   ::http::register https 8443 [list ::tls::socket -tls1 1]

  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    puts "Add line to DB successfully"
  }
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok

}
# ***************************************************************************
# UpdateDB2
# ***************************************************************************
proc UpdateDB2 {barcode uutName hostDescription  date time status  failTestsList failDescription dealtByServer traceID poNumber {data1 ""} {data2 ""} {data3 ""}} {
  set dbPath "//prod-svm1/tds/Temp/SQLiteDB/"
  set dbName "JerAteStats.db" 
  foreach f {uutName hostDescription failTestsList failDescription dealtByServer data1 data2 data3} {
    set url_$f [ConvertToUrl [set $f]]
  }
  puts "UpdateDB2 <$barcode> <$uutName> <$hostDescription> <$date> <$time> <$status> <$failTestsList> <$failDescription> \
  <$dealtByServer> <$traceID> <$poNumber> <$data1> <$data2> <$data3>"
  # set url "http://webservices-test:8080/ATE_WS/ws/tcc_rest/add_row2_with_db?barcode=$barcode&uutName=$url_uutName"
  set url "http://webservices03.rad.com:10211/ATE_WS/ws/tcc_rest/add_row2_with_db?barcode=$barcode&uutName=$url_uutName"
  append url "&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status"
  append url "&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"
  append url "&dbPath=$dbPath&dbName=$dbName&traceID=$traceID&poNumber=$poNumber&data1=$url_data1&data2=$url_data2&data3=$url_data3" 
  puts "UpdateDB url:<$url>"

  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    puts "Add line to DB successfully"
  }
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok

}

proc CopyToLocalDB {} {
  #***************************************************************************
  #** CopyToLocalDB
  #***************************************************************************
  set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/downloadFile"
  set myLocation "c:/Logs/demo.db"

  ::http::register https 8443 [list ::tls::socket -tls1 1]

  set idFile [open $myLocation wb]   
  set tok [http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"] -channel $idFile -binary 1]          
  close $idFile
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    puts "Downloaded successfully"
  }
  update
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok

}

proc ConvertToUrl {s} {
  #***************************************************************************
  #** ConvertToUrl
  # valid url char :  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=
  # space = %20
  # ""    = %22
  # {}    = %7b %7d
  # %     = %25
  # ^     = %5e
  # < >   = %3c %3e
  #***************************************************************************
  foreach i "20 22 25 3c 3e 5e 7b 7d" {
    set c [format %c 0x$i]
    lappend specialChars $c %$i
  }
  return [string map "$specialChars" $s]
}

# ***************************************************************************
# Get_SwVersions
#  Get_SwVersions DE1005790454 ; # no SW
#  Get_SwVersions DC1002287083 
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText contains list of SWxxxx and Versions
#  Get_SwVersions DC1002287083 returns
#      0 {SW3814 B1.0.3 SW3841 5.2.0.75.28}
#  Get_SwVersions DE1005790454 returns
#      0 {}
# ***************************************************************************
proc Get_SwVersions {id} {
  puts "\nGet_SwVersions $id"
  set barc [format %.11s $id]
  set url "http://ws-proxy01.rad.com:8081/ExtAppsWS/Proxy/Select"
  set query [::http::formatQuery queryName "qry.get.sw.for_idNumber_2" db inventory params $barc]
  append url "/?[set query]"
  set resLst [Retrive_WS $url $query "SW Versions for $id"]
  # foreach {res resTxt} $resLst {}
  # if {$res!=0} {
    # return $resLst 
  # }
  # if [llength $resTxt]==0 {
    # return [list -1 "No SW for $id"]
  # }
  return $resLst 
}

# ***************************************************************************
# Get_OI4Barcode
#  Get_OI4Barcode EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is DBR Assembly Name (located at resultText)
#   Get_OI4Barcode EA1004489579 will return
#       0 RIC-LC/8E1/UTP/ACDC
# ***************************************************************************
proc Get_OI4Barcode {id} {
  puts "\nGet_OI4Barcode $id"
  set barc [format %.11s $id]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param OperationItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [Retrive_WS $url "NA" "DBR Assembly Name for $id"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No DBR Assembly Name for $id"]
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "item"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_CSL
#  Get_CSL EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is CSL (located at resultText)
#   Get_CSL EA1004489579 will return
#       0 A 
# ***************************************************************************
proc Get_CSL {id} {
  puts "\Get_CSL $id"
  set barc [format %.11s $id]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param CSLByBarcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [Retrive_WS $url "NA" "CSL for $id"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No CSL for $id"]
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "CSL"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_MrktName
#  Get_MrktName EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is MKT Name (located at resultText)
#   Get_MrktName EA1004489579 will return
#       0 RIC-LC/8E1/4UTP/ETR/RAD   
# ***************************************************************************
proc Get_MrktName {id} {
  puts "\nGet_MrktName $id"
  set barc [format %.11s $id]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param MKTItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [Retrive_WS $url "NA" "Marketing Name for $id"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No Marketing Name for $id"]
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "MKT Item"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_MrktNumber
#  Get_MrktNumber ETX-1P/ACEX/1SFP1UTP/4UTP/WF
#  Get_MrktNumber ETX-2I-10G-B_ATT/19/DC/8SFPP
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is Marketing Number (located at resultText)
# ***************************************************************************
proc Get_MrktNumber {dbr_assm} {
  puts "\nGet_MrktNumber $dbr_assm"
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param MKTPDNByDBRAssembly\?dbrAssembly=$dbr_assm
  append url $param
  set resLst [Retrive_WS $url "NA" "Marketing Number for $dbr_assm"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No Marketing Number for $dbr_assm"]
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "MKT_PDN"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Disconnect_Barcode
#  Disconnect_Barcode EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
# ***************************************************************************
proc Disconnect_Barcode {id {mac ""}} {
  puts "\nDisconnect_Barcode $id $mac"
  set barc [format %.11s $id]
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param DisconnectBarcode\?mac=[set mac]&idNumber=[set barc]
  append url $param
  set resLst [Retrive_WS $url "NA" "Disconnect Barcode $id"]
  return $resLst
} 

# ***************************************************************************
# Get_PcbTraceIdData
#  Get_PcbTraceIdData 21181408 pcb
#  Get_PcbTraceIdData 21181408 {pcb product}
#  Get_PcbTraceIdData 21181408 {pcb product "po number"}
#  Get_PcbTraceIdData 21181408 {"po number" "pcb_pdn" "sub_po_number" "pdn" "product" "pcb_pdn" "pcb"}
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is PcbTraceId Data 
#   resultText is a list of required parametes/s and its value/s:
#   Get_PcbTraceIdData 21181408 {pcb product} will return
#       0 {pcb SF-1V/PS.REV0.3I product SF1P/PS12V/RG/PS3/TERNA/3PIN/R06}   
# ***************************************************************************
proc Get_PcbTraceIdData {id var_list} {
  puts "\nGet_PcbTraceIdData $id"
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param PCBTraceabilityIDData\?barcode=null\&traceabilityID=$id
  append url $param
  set resLst [Retrive_WS $url "NA" "Pcb TraceId Data for $id"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No Pcb TraceId Data for $id"]
  }
  foreach var $var_list {
    set var_indx [lsearch $resTxt $var]
    if {$var_indx=="-1"} {
      return [list -1 "No such parameter: $var"]
    }
    lappend value $var [lindex $resTxt [expr {1 + $var_indx} ] ]
  }
  #set value [lindex $resTxt [expr {1 + [lsearch $resTxt "po number"]} ] ]
  return [list $res $value] 
} 


# ***************************************************************************
# CheckMac
# CheckMac EA1004489579 112233445566
# CheckMac DE100579045 123456123456
# Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if ID and MAC are not connected or connected to each other
#                  1 if ID or MAC connected to something else
# ***************************************************************************
proc CheckMac {id mac} {
  set li [chk_connection_to_mac $mac]
  foreach {res connected_id} $li {}
  if {$res!=0} {
    return $connected_id
  }
  set short_id [format %.11s $id]
  set li [chk_connection_to_id $short_id]
  foreach {res connected_mac} $li {}
  if {$res!=0} {
    return $connected_mac
  }
  puts "CheckMac input_id:<$short_id>, to $mac connected id: <$connected_id>"
  puts "CheckMac input_mac:<$mac>, to $short_id connected mac: <$connected_mac>"
  
  if {$connected_id == $short_id && $connected_mac == $mac} {
    return [list 0 "$id->$mac"]
  }
  if {$connected_id == "" && $connected_mac == ""} {
    return [list 0 "NC, NC"]
  }
  if {$connected_id != "" && $connected_id != $short_id} {
    return [list 1 "$mac is already connected to $connected_id"]
  }
  if {$connected_mac != "" && $connected_mac != $mac} {
    return [list 1 "$id is already connected to $connected_mac"]
  }
  return "-100 None"
}

proc chk_connection_to_mac {{mac "112233445566"}} {
  set hostname "ws-proxy01.rad.com"
  set port 8445
  set path "/MacRegREST/MacRegExt/ws/"
  set url "https://[set hostname]:[set port][set path]q001_mac_extant_chack"
  #puts $url
  set query [::http::formatQuery macID $mac]
  foreach {res connected_id} [Retrive_WS $url $query "Connection to $mac"] {}
  set connected_id [lindex $connected_id [expr 1+ [lsearch $connected_id "id_number"] ] ]
  #puts "res:<$res> connected_id:<$connected_id>"
  return [list $res $connected_id]
}

proc chk_connection_to_id {{id "EA100448957"}} {
  set hostname "ws-proxy01.rad.com"
  set port 8445
  set path "/MacRegREST/MacRegExt/ws/"
  set url "https://[set hostname]:[set port][set path]q003_idnumber_extant_check"
  #puts $url
  
  set query [::http::formatQuery idNumber $id]
  foreach {res connected_mac} [Retrive_WS $url $query "Connection to $id"] {}
  set connected_mac [lindex $connected_mac [expr 1+ [lsearch $connected_mac "mac"] ] ]
  #puts "res:<$res> connected_mac:<$connected_mac>"
  return [list $res $connected_mac]
}

# ***************************************************************************
# Retrive_WS
# ***************************************************************************
proc Retrive_WS {url {query "NA"} paramName} {
  puts "Retrive_WS \"$url\" \"$query\" \"$paramName\""
  set res_val 0
  set res_txt [list]
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd {::http::geturl $url -headers $headers}
  if {[string range $query 0 3]=="file"} {
    set mode get_file
    set localUCF [string range $query 5 end]
  } elseif {[string range $query 0 1]=="NA"} {
    set mode no_query
  } else {
    set mode use_query
  }
  
  if {$mode=="get_file"} {
    catch {open $localUCF w+} f
    append cmd " -channel $f -binary 1"
  } elseif {$mode=="use_query"} {
    append cmd " -query $query"
  }
  
  if $::debugWS {puts "cmd:<$cmd>"}
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      set res_val -1
      set res_txt "Fail to get $paramName"
      catch {close $f}
      return [list $res_val $res_txt]
    }
  }
  catch {close $f}
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set res_val -1
    set res_txt "Fail to get $paramName"; # "http::status: <$st> http::ncode: <$nc>"
  }
  upvar #0 $tok state
  if $::debugWS {parray state}
  #puts "$state(body)"
  set body $state(body)
  if $::debugWS {set ::b $body}
  ::http::cleanup $tok
  
  if {$res_val==0} {
    if [string match {*DisconnectBarcode*} $url] {
      return [list 0 "Disconnected"]
    }
    if {$mode=="get_file" && $res_val==0} {
      if [catch {file size $localUCF} size] {
        set res_val -1
        set res_txt "Fail to get size of $localUCF"
      } else {
        set res_val 0
        set res_txt $size
      }
      return [list $res_val $res_txt]      
    }
    
    set asadict [::json::json2dict $body]
    if [string match {*qry.get.sw.for_idNumber_2*} $url] {
      foreach par $asadict {
        foreach {swF swV verF verV} $par {
          lappend res_txt $swV $verV
        }
      }
    } else {
      foreach {name whatis} $asadict {
        foreach {par val} [lindex $whatis 0] {
          # puts "<$par> <$val>"
          if {$val!="null"} {
            lappend res_txt $par $val
          }                 
        }
      }
    }
  }
  return [list $res_val $res_txt]
}

# ***************************************************************************
# Get_ConfigurationFile
#  Get_ConfigurationFile ETX-2I-100G_ATT/ACRF/4Q/16SFPP c:/temp/1.txt FAIL!!!
#  Get_ConfigurationFile ETX-2I-100G_FTR/DCRF/4Q/16SFPP/K10 c:/temp/1.txt
#  Get_ConfigurationFile ETX-2I-10G-B_ATT/19/DCR/8SFPP c:/temp/1.txt
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have a size of the downloaded file
#   Get_ConfigurationFile ETX-2I-100G_FTR/DCRF/4Q/16SFPP/K10 c:/temp/1.txt returns
#      0 42207
# ***************************************************************************
proc Get_ConfigurationFile {dbr_assm localUCF} {
  puts "\nGet_ConfigurationFile $dbr_assm $localUCF"
  
  if [file exists $localUCF] {
    catch {file delete -force $localUCF}
    after 500
  }
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/configDownload/ConfigFile?"
  set param "dbrAssembly=[set dbr_assm]"
  append url $param
  set resLst [Retrive_WS $url file_$localUCF "Get Configuration File for $dbr_assm"]
  return $resLst
}
# ***************************************************************************
# Get_File
#   Get_File //prod-svm1/tds/Install/ATEinstall/JATE_Team/LibUrl_WS/ LibUrl.tcl c:/temp/my_lib_url.tcl
#   Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have a size of the downloaded file
#   Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl returns
#      0 21377
# ***************************************************************************
proc Get_File {path file_name local_file} {
  puts "\nGet_File $path $file_name $local_file"
  
  # if [file exists $localUCF] {
    # catch {file delete -force $localUCF}
    # after 500
  # }
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/tcc_rest/downloadFile2?"
  set param "fullpath=[set path][set file_name]&filename=[set local_file]" 
  append url $param
  set resLst [Retrive_WS $url file_$local_file "Get $path/$file_name"]
  return $resLst
}

# ***************************************************************************
# Get_Mac
#  Get_Mac 0
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have first MAC
#   Get_Mac 1 will return
#     0 1806F5879CB6
# ***************************************************************************
proc Get_Mac {qty} {
  puts "\nGet_Mac $qty"
  set url "https://ws-proxy01.rad.com:8445/MacRegREST/MacRegExt/ws/sp001_mac_address_alloc"
  set query [::http::formatQuery p_mode 0 p_trace_id 0 p_serial 0 p_idnumber_id 0 p_alloc_qty $qty p_file_version 1]
  set resLst [Retrive_WS $url $query "Get $qty MACs"]
  set Error_indx [lsearch [lindex $resLst 1] "Error"]
  set Error_Val [lindex [lindex $resLst 1] [expr {1+$Error_indx}]]
  #puts "$resLst $Error_indx $Error_Val"
  if {[lindex $resLst 0]==0 && $Error_Val==0} {
    return [list 0 [lindex [lindex $resLst 1] end]]
  } else {
    return [list -1 [lindex $resLst 1]]
  }  
}

# ***************************************************************************
# Get_Pages
# Get_Pages IO3001960310 50190576 0 
# ***************************************************************************
proc Get_Pages {id {traceId ""} {macs_qty 10} } {
  puts "\nGet_Pages $id $traceId $macs_qty"
  
  set headers [list "content-type" "text/xml" "SOAPAction" ""]
  set data "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
  append data "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
  append data "xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
  append data "xmlns:mod=\"http://model.macregid.webservices.rad.com\">\n"
  append data "<soapenv:Header/>\n"
  append data "<soapenv:Body>\n"
  append data "<mod:get_Data_4_Dallas soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n"
  append data "<ParamStr1 xsi:type=\"xsd:string\">2</ParamStr1>\n"
  append data "<ParamStr2 xsi:type=\"xsd:string\">$id</ParamStr2>\n"
  append data "<ParamStr3 xsi:type=\"xsd:string\">0</ParamStr3>\n"
  append data "<ParamStr4 xsi:type=\"xsd:string\">$traceId</ParamStr4>\n"
  append data "</mod:get_Data_4_Dallas>\n"
  append data "</soapenv:Body>\n"
  append data "</soapenv:Envelope>\n"
  #puts $data
  
  set url "http://ws-proxy01.rad.com:10211/Pages96WS/services/MacWS"
  set cmd {::http::geturl $url -headers $headers -query $data}
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      set res_val -1
      set res_txt "Fail to get Pages for $id $traceId"
      return [list $res_val $res_txt]
    }
  }
  
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  set body  [::http::data $tok]
  if $::debugWS {puts "tok:<$tok> st:<$st> nc:<$nc> body:<$body>"}
  #upvar #0 $tok state
  ::http::cleanup $tok
  
  if $::debugWS {set ::b $body}
  regsub -all {[<>]} $body " " b1
  
  if [string match {*502 Proxy Error*} $b1] {
    set res_val -1
    set res_txt "Fail to get Pages for $id $traceId : 502 Proxy Error"
    return [list $res_val $res_txt]
  }
  if ![string match {*ns1:get_Data_4_DallasResponse*} $b1] {
    set res_val -1
    set res_txt "Fail to get Pages for $id $traceId"
    return [list $res_val $res_txt]
  }
  if [string match {*ERROR*} $b1] {
    set err ERROR
    regexp {(ERROR[\w\s\!]+)/} $b1 ma err
    set res_val -1
    set res_txt "Fail to get Pages for $id $traceId : $err"
    return [list $res_val $res_txt]
  }
  
  set res 0
  regexp {(Page 0 - [0-9A-F\s]+) /} $b1 ma page0
  regexp {(Page 1 - [0-9A-F\s]+) /} $b1 ma page1
  regexp {(Page 2 - [0-9A-F\s]+) /} $b1 ma page2
  regexp {(Page 3 - [0-9A-F\s]+) /} $b1 ma page3
  append resTxt $page0\n
  append resTxt $page1\n
  append resTxt $page2\n
  append resTxt $page3
   
  return [list $res $resTxt]
}

# ***************************************************************************
# Ping_WebServices03
# ***************************************************************************
proc Ping_WebServices03 {} {
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/Ping"
  puts "Ping_WebServices03 $url"
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd {::http::geturl $url -headers $headers}
  
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      return -1
    }
  }
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  upvar #0 $tok state
  
  if $::debugWS {parray state}
  #puts "$state(body)"
  set body $state(body)
  if $::debugWS {set ::b $body}
  
  ::http::cleanup $tok
  set asadict [::json::json2dict $body]
  foreach {name whatis} $asadict {
    foreach {par val} [lindex $whatis 0] {
      if {[regexp {Server ~~~  = webservices03} $val]} {
        set ret 0
        break
      }                 
    }
  }
  return $ret
}
# ***************************************************************************
# Ping_Pages
# ***************************************************************************
proc Ping_Pages {}  {
  puts "\nPing_Pages"
  
  set headers [list "content-type" "text/xml" "SOAPAction" ""]
  set data "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
  append data "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
  append data "xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
  append data "xmlns:mod=\"http://model.macregid.webservices.rad.com\">\n"
  #append data "xmlns:mod=\"http://model.chinaws.webservices.rad.com\">\n"
  append data "<soapenv:Header/>\n"
  append data "<soapenv:Body>\n"
  append data "<mod:ping soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"/>\n"
  append data "</soapenv:Body>\n"
  append data "</soapenv:Envelope>\n"
  #puts $data
  
  set url "https://ws-proxy01.rad.com:8445/Pages96WS/services/MacWS"
  set cmd {::http::geturl $url -headers $headers -query $data}
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      return -1
    }
  }
  
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  set body  [::http::data $tok]
  if $::debugWS {puts "tok:<$tok> st:<$st> nc:<$nc> body:<$body>"}
  #upvar #0 $tok state
  ::http::cleanup $tok
  
  if $::debugWS {set ::b $body}
  regsub -all {[<>]} $body " " b1
  return [regexp {Server ~~~  = WS-MAC-Pages} $b1]
}

# ***************************************************************************
# Get_TraceId
#  Get_TraceId DA200047522
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is TraceabilityID (located at resultText)
#   Get_TraceId DA200047522 will return
#       0 21146247C
# ***************************************************************************
proc Get_TraceId {id} {
  puts "\nGet_TraceId $id"
  set barc [format %.11s $id]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/traceability/"
  set param TraceabilityByBarcode\?barcode=[set barc]
  append url $param
  set resLst [Retrive_WS $url "NA" "Traceability for $id"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    return [list -1 "No Traceability for $id"]
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "pcb_barcode"]} ] ]
  return [list $res $value] 
} 


puts "Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl"
puts "CheckMac EA1004489579 112233445566"
puts "Get_PcbTraceIdData 21181408 {pcb product \"po number\"}"
puts "Get_MrktName EA1004489579"
puts "Get_MrktNumber ETX-1P/ACEX/1SFP1UTP/4UTP/W"
puts "Get_OI4Barcode EA1004489579"
puts "Get_SwVersions DC1002287083" 