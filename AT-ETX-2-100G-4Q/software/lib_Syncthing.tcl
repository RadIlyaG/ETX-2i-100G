package require http
package require json

# ***************************************************************************
# CheckSyncthingLocalAdditions
# path="c:\temp\TDS_AutomaticTesters_2i"
if 0 {

set d1 [file normalize  C:/AT-ETX-2i]
set d2 [file normalize  C:/download]
set emailL {ilya_g@rad.com}
set r_temp //prod-svm1/temp/IlyaG/[file tail [file dirname [pwd]]]
foreach {ret resTxt} [CheckSyncthingLocalAdditions [list $d1 $d2] $emailL $r_temp] {}
puts "SyTh ret:<$ret>"
puts "SyTh resTxt:<$resTxt>"

}
# ***************************************************************************
proc CheckSyncthingLocalAdditions {folders emailL r_temp} {
  global changed_count changed_list conflict_fs_count conflict_fs_list api_url when_changed_list
  set sync_port "8384"
  set sync_host "127.0.0.1"
  set api_url "http://${sync_host}:${sync_port}/rest"

  set target_paths [string tolower $folders] ; #[list "c:/download" "c:/Tester/software" ]
  
  set api_key ""
  set folder_map [dict create]
  set changed_count 0
  set changed_list {}
  set conflict_fs_count 0
  set conflict_fs_list {}
  set return_list ""
  set when_changed_list {}
  
  if {[catch {find_and_parse_config $target_paths} result]} {
    puts "\n--- SCRIPT COLLISION ---"
    #puts $result
    return [list -1 $result]
  } else {
    puts "res of find_and_parse_config: <$result>"
  }
  
  foreach {ret resTxt} [check_api_changes] {}
  #puts "res of check_api_changes: <$ret> resTxt:<$resTxt>"
  if {$ret!=0} {
    return [list $ret $resTxt]
  }
  
  foreach {ret resTxt} [check_fs_conflicts $target_paths]  {}
  #puts "res of check_fs_conflicts: <$ret>"
  if {$ret!=0} {
    return [list $ret $resTxt]
  }
  
  if {$changed_count==0 && $conflict_fs_count==0} {
    return [list 0 ""]
  } else {
    if {$changed_count>0} {
      if {$changed_count==1} {
        set file_s "file"
        set is_are "is"
      } else {
        set file_s "files"
        set is_are "are"
      }
      append return_list "Tester $file_s $is_are newer than server $file_s:\n"
      foreach fil $changed_list when $when_changed_list {
        append return_list "${fil}   ${when}\n"
      }
    }
     if {$conflict_fs_count>0} {
      append return_list "\nResolved conflict/s:\n"
      foreach fil $conflict_fs_list {
        append return_list $fil\n
      }
    }
    append return_list "\r\nfile://$r_temp\r"
  }
  if {[llength $emailL]>0} {
    #SendMail $emailL $return_list "Message from Tester"
    send_smtp_mail $emailL -subject "Message from Tester" -body $return_list -cc ilya_g@rad.com; # -att $changed_list
  }
  
  if [string length $r_temp] {
    if ![file exists $r_temp] {
      file mkdir $r_temp
    }
    #set msg "A message regarding\n\n"
    foreach fi $changed_list {
      catch {file copy -force $fi $r_temp } res
      puts "file:<$fi>, res of copy:<$res>"
    }
  }
  return [list 0 [concat $changed_list $conflict_fs_list]]
}

# ***************************************************************************
# find_and_parse_config
#  finds API Key and Folder ID, needed for API
# ***************************************************************************
proc find_and_parse_config {target_paths} {
  global env api_key folder_map

  if {![info exists env(LOCALAPPDATA)]} {
    puts stderr "Error: Enviroment Variable LOCALAPPDATA not found."
    return -code error "NO_LOCAL_APPDATA"
  }

  set config_dir [file join $env(LOCALAPPDATA) "Syncthing"]
  set config_file [file join $config_dir "config.xml"]

  if {![file exists $config_file]} {
    puts stderr "Error: Configuration file Syncthing not found at path: $config_file"
    return -code error "CONFIG_NOT_FOUND"
  }
  #puts "config_file:<$config_file>"

  # set config_content [catch {
      # set f [open $config_file r]
      # set content [read $f]
      # close $f
      # return $content
  # } errMsg]
  
  catch {
    set f [open $config_file r]
    set config_content [read $f]
    close $f       
  } errMsg]

  if {[string length $config_content] == 0} {
    puts stderr "Error: Error: Failed to read config.xml."
    return -code error "READ_FAILED"
  }
  #puts "config_content:<$config_content>"
  set ::cc $config_content

  # a) Retrive API Key
  if {[regexp {<apikey>([^<]+)</apikey>} $config_content all_match api_key]} {
    puts "Success: API Key found."
  } else {
    puts stderr "Error: API Key not found in config.xml."
    return -code error "API_KEY_NOT_FOUND"
  }

  # b) Retrive Folder ID for folders
  set folder_regexp {<folder[ ]+id="([^"]+)"[^>]*path="([^"]+)"[^>]*>}
  #puts "folder_regexp:$folder_regexp"
  
  set content_left $config_content
  while {[regexp -indices $folder_regexp $content_left all_idx id_idx path_idx]} {
    #puts "all_idx:$all_idx id_idx:$id_idx path_idx:$path_idx"
    
    set folder_id [string range $content_left [lindex $id_idx 0] [lindex $id_idx 1]]
    set folder_path [string range $content_left [lindex $path_idx 0] [lindex $path_idx 1]]
    puts "folder_id:$folder_id folder_path:$folder_path"
    
    set normalized_path [string tolower [string map {\\ /} $folder_path]]
    
    #puts "[lsearch -exact $target_paths $normalized_path] target_paths:<$target_paths> normalized_path:<$normalized_path> "
    
    if {[lsearch -exact $target_paths $normalized_path] != -1} {
        dict set folder_map $normalized_path $folder_id
        #puts 00
    } else {
        #puts 11
    }
    
    set content_left [string range $content_left [lindex $all_idx 1] end]
  }
  
  if {[dict size $folder_map] == 0} {
    puts stderr "Error: Folder ID for folders [join $target_paths ", "] not found."
    return -code error "FOLDER_ID_NOT_FOUND"
  }
  
  return [list $api_key $folder_map]
}


# ***************************************************************************
# check_api_changes
# ***************************************************************************
proc check_api_changes {} {
  global api_key folder_map api_url changed_count changed_list when_changed_list

  foreach {path folder_id} [dict get $folder_map] {
    puts "\n\[1/2\] Checking folder $path for active local changes (API)..."
    
    set api_endpoint "db/localchanged?folder=${folder_id}"
    set url "${api_url}/${api_endpoint}"
    
    # Making an HTTP GET request
    if [catch {http::geturl $url -headers [list "X-API-Key" $api_key]} token] {
      return [list -1 $token]
    }
    set status [http::status $token]
    set response_body [http::data $token]
    set ::rb $response_body
    http::cleanup $token
    #puts "check_api_changes status:$status response_body:<$response_body>"

    if {$status eq "ok"} {
      #set json_data [catch {::json::json2dict $response_body} errMsg]
      
      set errMsg ""
      if [catch {::json::json2dict $response_body} json_data] {
        set errMsg $json_data
      } 
       
      #puts "check_api_changes json_data:<$json_data>"
      set json_data [lindex $json_data 1 ]
      puts "check_api_changes json_data:<$json_data>"
      #puts "check_api_changes errMsg:<$errMsg>"
      
      if {[string length $errMsg] == 0 && [llength $json_data] > 0} {
        puts "  --> API: Found [llength $json_data] active changes ('Out of Sync')."
        foreach item $json_data {
          if [catch {dict get $item "name"} filename] {
           puts kuku
          } else {
            #set filename [dict get $item "name"]
            puts "filename:$filename"
            if [string match {*ssss-sync-conflict*}  $filename] {
              ## don't report about conflict
            } else {
              set full_path [file join $path $filename]
              lappend changed_list $full_path
              incr changed_count
            }
          }
          if [catch {dict get $item "modified"} wh_mod] {
           puts kuku2
          } else {
            #set filename [dict get $item "name"]
            set when_modified [join [lindex [split [split $wh_mod T] .] 0] _]
            puts "when_modified:$when_modified"
            lappend when_changed_list $when_modified
          }
        }
      } elseif {[llength $json_data] == 0} {
        puts "  --> API: No active changes found."
      }
    } else {
      puts stderr "  --> HTTP request error (code $status). Please check if Syncthing is running."
    }
  }
  return [list 0 ""]
}



# ***************************************************************************
# check_fs_conflicts
# ***************************************************************************
proc check_fs_conflicts {target_paths} {
  global conflict_fs_count conflict_fs_list
  
  puts "\n\[2/2\] Checking the file system for already resolved conflicts..."
  
  foreach folder $target_paths {
    puts "check_fs_conflicts folder $folder"
    # searching for the *.sync-conflict-* template in all subfolders (recursively)
    set all_conflicts [glob_recursive  $folder  "*.sync-conflict-*"]
    
    if {[llength $all_conflicts] > 0} {
      foreach confl $all_conflicts {
        file copy -force  $confl c:/temp
        after 200
        file delete -force  $confl
      }
      # puts "  --> FS: Found [llength $all_conflicts] resolved conflicts in $folder."
      # incr conflict_fs_count [llength $all_conflicts]
      # set conflict_fs_list [concat $conflict_fs_list $all_conflicts]
    }
  }
  
  if {$conflict_fs_count == 0} {
    puts "  --> FS: No resolved conflicts found."
  }
  return [list 0 ""]
}

# ***************************************************************************
# glob_recursive
# ***************************************************************************
proc glob_recursive {dir pattern} {
  set result {}
  foreach file [glob -nocomplain -directory $dir *] {
    if {[file isdirectory $file]} {
      lappend result {*}[glob_recursive $file $pattern ]
    }
    if {[string match $pattern [file tail $file]]} {
      lappend result $file
    }
  }
  return $result
}


# ***************************************************************************
# RetriveApiKey
# ***************************************************************************
proc neRetriveApiKey {} {
  set id [open $::env(LOCALAPPDATA)/Syncthing/config.xml r]
  set lines [read $id]
  close $id
  if [regexp {<apikey>([a-zA-Z0-9]+)</apikey>} $lines ma api] {
    return $api
  } else {
    return -1   
  }
}

# ***************************************************************************
# GetLocalChanged
# ***************************************************************************
proc neGetLocalChanged {apikey folders} {  
  set lines ""
  set folderIds [list]
  foreach folder $folders {
    set id [open [glob $folder/.stfolder/sync*.txt] r]
    append lines [read $id]
    close $id
  }  
  foreach line [split $lines \n] {
    if [regexp {folderID:\s+([a-zA-Z0-9\-]+)} $line ma id]  {
      lappend folderIds $id
    }
  }
    
  #foreach folderId {a6jk5-emmy9 mumed-uy9fu} {}
  foreach folderId $folderIds {
    catch {exec curl -s -H "X-API-Key: $apikey" http://localhost:8384/rest/db/localchanged?folder=$folderId} res
    #puts "$folderId <$res>"
    append ret "$res"
  }  
  set files ""; #[list]
  foreach line [split $ret ,] {
    if [regexp {\"name\"\:\s+\"([^\"]+)\"} $line ma fi] {
      append files "$fi "
      #lappend files $fi
    
    }
  }
  return $files 
  
}

