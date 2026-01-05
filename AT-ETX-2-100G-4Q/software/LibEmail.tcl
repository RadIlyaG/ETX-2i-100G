puts "inside LibEmail.tcl File" ; update

#======================
# Comments:
# 1. Copy "ezsmtp1.0.0" package to : C:\Tcl\lib\ezsmtp1.0.0  (package for E-MAIL)
# 2. Copy "email24.jpg" to tester
# 3. Copy "LibEmail.tcl" to tester
# 4. Copy "InitEmail.tcl" to tester
# 5. source LibEmail.tcl
# 6. Gui>Tools>
#    - Email Setting
#    - Email Test
# 7. ButRun>
#    - fail SendEmail
#    - MesegeTestPass > SendEmail
# 8. update: gaSet(RackId) it is the index of the Rack !
#    there can be more then one rack with the same Tester.
# 9. update UUT Name via proc TestEmail!
#======================
          	      
# package require img::ico
# package require img::gif
# package require img::jpeg
# package require ezsmtp

set gaSet(EmailSum) 10
set gaSet(RackId) 1

# ***************************************************************************
# GuiEmail                                                Mail (1)
# ***************************************************************************
proc GuiEmail {base} {
  global gaSet gaGui
  
  if {[winfo exists $base]} {
    wm deiconify $base
    return
  }
  
  toplevel $base
  focus -force $base
  wm protocol $base WM_DELETE_WINDOW "wm attribute $base -topmost 0 ; destroy $base ; InitFileEmail"
  wm focusmodel $base passive
  wm overrideredirect $base 0
  wm resizable $base 0 0
  wm deiconify $base
  wm title $base "Send Results to..."
  wm attribute $base -topmost 1
    
  #set gaSet(EmailSum) 10  
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  } else {
    for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
      set gaSet(Email.$i) ""
      set gaSet(chbutEmail.$i) "0" 
    }
    InitFileEmail  
  } 
    
  set gaGui(labMail) [Label $base.labMail -text "Emails" -font {{} 10 {bold underline}}]
  pack $gaGui(labMail) -side top -pady 2 -padx 4 -anchor w
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    set gaGui(fraMail.$i) [frame $base.fraMail$i]
      set gaGui(entMail.$i) [Entry $gaGui(fraMail.$i).entMail$i \
      -width 23 -textvariable gaSet(Email.$i)]
      set gaGui(cbMail.$i) [checkbutton $gaGui(fraMail.$i).cbMail$i \
      -text ".$i" -variable gaSet(chbutEmail.$i) -command "ActivateMail"]      
      pack $gaGui(cbMail.$i) $gaGui(entMail.$i) -side right -padx 4 -pady 2
    pack $gaGui(fraMail.$i) -side top -pady 2 -padx 4 -anchor w
  }  
  ActivateMail
  focus -force $base
  grab $base    
}

# ***************************************************************************
# ActivateMail                                                Mail (2)
# ***************************************************************************
proc ActivateMail {} {
  global gaGui gaSet
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    if {[set gaSet(chbutEmail.$i)]==0} {
      [set gaGui(entMail.$i)] configure -state disabled
    } else {
      [set gaGui(entMail.$i)] configure -state normal
    }
  }
}

##***************************************************************************
##** InitFileEmail +                                           Mail (3)
##***************************************************************************
proc InitFileEmail {} {
  global gaSet 
  set fileId [open InitEmail.tcl w]
  seek $fileId 0 start
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    puts $fileId "set gaSet(Email.$i) \"$gaSet(Email.$i)\""
    puts $fileId "set gaSet(chbutEmail.$i) \"$gaSet(chbutEmail.$i)\""
  }  
  close $fileId
}
# ***************************************************************************
# SendEmail                                                Mail (4)
# ***************************************************************************
proc SendEmail {UutName msg} {
  global gaSet gaInfo gaGui
#  package require ezsmtp
  ezsmtp::config -mailhost radmail.rad.co.il -from "ATE-UUT210"
   

  # gaSet(RackId)
  if {[info exist gaSet(RackId)]==1} {
   # Exist:
     set RackId $gaSet(RackId)
  } else {
    #Not Exist:
    set RackId ""
  }
  
  # gaGui(Indx)
  if {[info exist gaGui(Indx)]==1} {
   # Exist:
     set RackIndx "#$gaGui(Indx)"
  } else {
    #Not Exist:
    set RackIndx ""
  }  
  
  #source InitEmail.tcl
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  } else {
    for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
      set gaSet(Email.$i) ""
      set gaSet(chbutEmail.$i) "0" 
    }
    InitFileEmail  
  }  
  
  
  
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {   
    if {$gaSet(chbutEmail.$i)==1} {
      if { [catch {ezsmtp::send -to "$gaSet(Email.$i)" \
      -subject "[string toupper [info host] ] : Message from Tester $gaSet(pair)" \
      -body "\n[string toupper [info host] ] : Message from Tester $gaSet(pair)\n\
       \n$msg " \
      -from "ate-j-r@rad.com"} res]} {
        puts stderr "Can't Send Email\n res:$res"
        return "Abort"
      }    
    }
  }
  return "Ok"
}

# ***************************************************************************
# TestEmail                                                Mail (5)
# ***************************************************************************
proc TestEmail {} {
  global gaSet

  set ret [SendEmail "UUT" "Demo check email ..."]
  if {$ret!="Ok"} {
   puts stderr "Email problem ..."
   return Abort 
  }
  puts "Email Test pass ... !" ; update
  return Ok
}


# ***************************************************************************
# SendMail
# ***************************************************************************
proc SendMail {emailL mess {sbj_txt "init/s changed"}} {
  
  if {[llength $emailL]>0} {
    ezsmtp::config -mailhost radmail.rad.co.il -from "[string toupper [info host] ]"
    catch {ezsmtp::send -to "[lindex $emailL 0]" -cclist [lrange $emailL 1 end] -subject "[string toupper [info host] ] : $sbj_txt" \
      -body "\n[string toupper [info host] ] : Message from Tester\n\
       \n$mess " \
      -from "$::env(USERNAME)@rad.com"} res
    puts "res:<$res>"  
  }    
}

package require smtp
# ***************************************************************************
# send_smtp_mail
# ***************************************************************************
proc send_smtp_mail {to args} {
  puts "args:<$args>"
 set procName [lindex [info level 0] 0]
  set mailhost radmail.rad.co.il
  set mailport 25
  set time_date [clock format [clock seconds] -format %T_%D]
  
  set from  [string toupper [info host]]
  set from_index [lsearch $args "-from"]
  if {$from_index>"-1"} {
    set from [lindex $args [expr {1 + $from_index}]]
  }
  
  set subject "ATE_reports_$time_date"
  set subj_index [lsearch $args "-subject"]
  if {$subj_index>"-1"} {
    set subject [lindex $args [expr {1 + $subj_index}]]
  }
  
  set body "Hello world!\n$time_date"
  set body_index [lsearch $args "-body"]
  if {$body_index>"-1"} {
    set body [lindex $args [expr {1 + $body_index}]]
  }
  
  set headers ""
  set headers_index [lsearch $args "-headers"]
  if {$headers_index>"-1"} {
    set headers [lindex $args [expr {1 + $headers_index}]]
  }
  
  set bcc ""
  set bcc_index [lsearch $args "-bcc"]
  if {$bcc_index>"-1"} {
    set bcc [lindex $args [expr {1 + $bcc_index}]]
  }
  
  set cc ""
  set cc_index [lsearch $args "-cc"]
  if {$cc_index>"-1"} {
    set cc [lindex $args [expr {1 + $cc_index}]]
  }
  
  set att ""
  set att_index [lsearch $args "-att"]
  if {$att_index>"-1"} {
    set att [lindex $args [expr {1 + $att_index}]]
    set opt_attcs_type -file
  }
  
  if [string length $att] {
    
      
    set parts  [mime::initialize -canonical text/plain -string $body]
    foreach att_obj $att {
      puts "$procName Processing: $att_obj File_exists: [file exists $att_obj]"
      update
      if {[file extension $att_obj]==".db"} {
        set imageT [mime::initialize -canonical "application/db; name=\"[file tail $att_obj]\"" -file $att_obj]
      } else {
        set imageT [mime::initialize -canonical "image/tif; name=\"[file tail $att_obj]\"" -file $att_obj]
      }
      lappend parts $imageT
    }
             
    
                        
    set messageT [::mime::initialize -canonical multipart/mixed -parts $parts]
  } else {
    set messageT [::mime::initialize -canonical text/plain -string $body]
    #set messageT [::mime::initialize -canonical text/html -string $body]
  }

  set command [list ::smtp::sendmessage $messageT -servers $mailhost -ports  $mailport]

  lappend command -header [list From $from]
  foreach to_obj $to {
    lappend command -header [list To $to_obj]
  }
  lappend command -header [list Subject $subject]

  if {[string length $cc]} {
    foreach cc_obj $cc {
      lappend command -header [list Cc $cc_obj]
    }  
  }
  
  if {[string length $bcc]} {
    foreach bcc_obj $bcc {
      lappend command -header [list Bcc $bcc_obj]
    }  
  }

  if {[string length $headers]} {
      foreach {key value} $headers {
          lappend command -header [list $key $value]
      }
  }

  puts "$procName cmd:<$command>"
  set err [catch { eval $command } result]
  #set err [catch  $command result]
  ::mime::finalize $messageT -subordinates all
  
  if {$err} {
    return [list -1 $result]
  } else {
    return [list 0 ""]
  }
}

