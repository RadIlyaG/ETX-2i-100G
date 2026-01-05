wm iconify . ; update

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
set jav [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment" CurrentVersion]
set gaSet(javaLocation) [file normalize [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment\\$jav" JavaHome]/bin]

## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
  if {$fi=="bootErrors.txt" || $fi=="sfpList.txt" || $fi=="NoTrace.txt"} {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER 
}
source lib_DeleteOldApp.tcl
DeleteOldApp
DeleteOldUserDef
source lib_Syncthing.tcl

set host_name  [info host]
if {[string match *ilya_g* $host_name] || [string match *avraham-bi* $host_name] || [string match *david-ya* $host_name] || [string match *ofer-m-* $host_name]} {
  set ::repairMode 1
} else {
  set ::repairMode 0
}

after 1000
set ::RadAppsPath c:/RadApps

if 1 {
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
  if {$gaSet(radNet)} {
    if 0 {
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
      set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
      puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
      if {$mTimeTds>$mTimeRL} {
        puts "$mTimeTds>$mTimeRL"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
        after 2000
      }
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
      set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
      puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
      if {$mTimeTds>$mTimeRL} {
        puts "$mTimeTds>$mTimeRL"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
        after 2000
      }
    }
    if 1 {
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/LibUrl_WS/LibUrl.tcl]
      set mTimePwd  [file mtime [pwd]/LibUrl.tcl]
      puts "mTimeTds:$mTimeTds mTimePwd:$mTimePwd"
      if {$mTimeTds>$mTimePwd} {
        puts "$mTimeTds>$mTimePwd"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/LibUrl_WS/LibUrl.tcl ./
        after 2000
      }
    }
    update
  }
  
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2-100G/AT-ETX-2-100G-4Q]
  set d1 [file normalize  C:/AT-ETX-2-100G-4Q]
  set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2-100G/download]
  set d2 [file normalize  C:/download]
  
  
  if {$gaSet(radNet)} {
    if {$::repairMode  || [string match *ilya-g* [info host]]} {
      set emailL [list]
    } else {
      set emailL {{yehoshafat_r@rad.com} {} {}}
    }
  } else {
    set emailL [list]
  }
  
  if 1 {
    set r_temp //prod-svm1/temp/IlyaG/[file tail [file dirname [pwd]]]
    source LibEmail.tcl
    foreach {ret resTxt} [CheckSyncthingLocalAdditions [list $d1 $d2] $emailL $r_temp] {} 
    puts "SyTh ret:<$ret>"
    puts "SyTh resTxt:<$resTxt>"
    set return_list "ret:<$ret>\nresTxt:<$resTxt>"
    if {$ret=="-1"} {
      send_smtp_mail ilya_g@rad.com -subject "Message from Tester [string toupper [info host]]" \
        -body $return_list
      if 0 {
        set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
        -message "The AutoSync process did not perform successfully.\n\n\
        Do you want to continue? "]
        if {$res=="no"} {
          exit
        }
      }
    }
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1 $s2 $d2" -noCheckFiles {init*.tcl skipped.txt *.db .stignore} \
      -jarLocation $::RadAppsPath -javaLocation $gaSet(javaLocation) -emailL $emailL \
      -putsCmd 1 -radNet $gaSet(radNet) -noCheckDirs {temp tmpFiles OLD old .stfolder} ]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      exit
    }
  }
  
  # 08:20 09/12/2025 if {$gaSet(radNet)} {}
  if 0 {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Macreg.2* Macreg-i* DP* *.prd}]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    if {$ret=="-1"} {
      set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
      -message "The AutoSync process did not perform successfully.\n\n\
      Do you want to continue? "]
      if {$res=="no"} {
        SQliteClose
        exit
      }
    }
  }
  
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
# package require RL10GbGen; #RLEtxGen
package require RLUsbPio
package require RLUsbMmux
package require RLSound  
package require RLCom
RLSound::Open ; # [list failbeep fail.wav passbeep pass.wav beep warning.wav]
#package require RLScotty ; #RLTcp
package require ezsmtp
package require http
package require sqlite3
package require RLAutoUpdate
package require twapi

source Gui_Etx2-100G.tcl
source Main_Etx2-100G.tcl
source Lib_Put_Etx2-100G.tcl
source Lib_Gen_Etx2-100G.tcl
source Lib_Ds280e01_Etx2iB.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source Lib_FindConsole.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source Lib_Etx204_220.tcl
#source Lib_Tds340.tcl ;  ## done by ButRun according to gaSet(scopeModel)
if [file exists uutInits/$gaSet(DutInitName)] {
  source uutInits/$gaSet(DutInitName)
} else {
  source [lindex [glob uutInits/ETX*.tcl] 0]
}
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl
source lib_DeleteOldApp.tcl
source Lib_Ramzor.tcl
source lib_EcoCheck.tcl
source lib_GuiIdTraceOper.tcl

source lib_PS_Etx2-100G.tcl

source Lib_DSOX1102A.tcl

DeleteOldApp
DeleteOldUserDef
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
  if {$fi=="bootErrors.txt" || $fi=="sfpList.txt" || $fi=="NoTrace.txt"} {
    file delete -force $fi
  }  
}

set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0

set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0
#set gaSet(1.barcode1) CE100025622

set gaSet(gpibMode) com
set gaSet(relDebMode) Release

set gaSet(1.useTraceId) 1

if {![info exists gaSet(rbTestMode)]} {
  set gaSet(rbTestMode) "Full"
}

set ::loginLoopsQty 64

set ::models_AC {FSF008-GS0G  DPS-550AB-53 G1342-0550WRB G1342-0550WRC}
set ::models_DC {R1CD2551B-GS DPS-650AB-43 G1232-0550WRB G1232-0550WRC} 

GUI
#BuildTests
update

wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"
#ToggleTestMode