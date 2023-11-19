# ***************************************************************************
# DeleteOldApp
# ***************************************************************************
proc DeleteOldApp {} {
  foreach fol [glob -nocomplain -type d c:/download/sw/*] {
    if {[string match -nocase {6.5.1(0.24)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    } 
    if {[string match -nocase {6.8.1(0.52)_OFK} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.1(0.59)_BYT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.58)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.1(0.59)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(2.76)_ATT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(2.59)_ATT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(3.75)_ATT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    
  }
}

# ***************************************************************************
# DeleteOldUserDef
# ***************************************************************************
proc DeleteOldUserDef {} {
  foreach userDef [glob -nocomplain -type f C:/AT-ETX-2-100G-4Q/ConfFiles/Default_conf/*.txt] {
    puts "userDef:<$userDef>"
    if {[string match -nocase {CONNECT_SFR_BOOTSTRAP_2i10G_V1_Rev2.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
      update
    }
    if {[string match -nocase {RAD_EXT-2i-100G_ZTP_Config_rev1.1.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
      update
    }
    
  }
}

