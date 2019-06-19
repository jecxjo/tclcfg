package require Tcl 8.2

namespace eval ::tclcfg {
  namespace export new
}

proc get_keys {obj_name} {
  upvar #0 $obj_name arr
  return [array name arr -glob *]
}

proc read_config {obj_name fname} {
  if { [string length $fname] } {
    if { [file exists $fname] } {
      upvar #0 $obj_name arr
      set fin [open $fname r]
      set items [split [string trim [read $fin]] "\n"]
      foreach item $items {
        if { [string index [string trim $item] 0] eq {#} } { continue }

        set tokenized [split $item {=}]
        set arr([string trim [lindex $tokenized 0]]) [string trim [lindex $tokenized 1]]
      }
    } else {
      puts "Config File does not exist: $fname"
    }
  } else {
    puts "wrong # args: should be \"$obj_name read FILENAME\""
  }
}

proc write_config {obj_name fname} {
  if { [string length $fname] } {
    upvar #0 $obj_name arr
    set fout [open $fname w]
    foreach key [get_keys $obj_name] {
      puts $fout "$key = $arr($key)"
    }
    close $fout
  } else {
    puts "wrong # args: should be \"$obj_name write FILENAME\""
  }
}

proc set_value {obj_name key val} {
  if { [string length $key] } {
    upvar #0 $obj_name arr
    set arr($key) $val
  } else {
    puts "wrong # args: should be \"$obj_name set KEY VALUE\""
  }
}

proc unset_value {obj_name key} {
  if { [string length $key] } {
    upvar #0 $obj_name arr
    if { [string length [array name arr -exact $key]] } {
      unset arr($key)
    } else {
      puts "key not found: $key"
    }
  } else {
    puts "wrong # args: should be \"$obj_name unset KEY\""
  }
}

proc get_value {obj_name key} {
  if { [string length $key] } {
    upvar #0 $obj_name arr
    if { [string length [array name arr -exact $key]] } {
      return $arr($key)
    } else {
      puts "key not found: $key"
    }
  } else {
    puts "wrong # args: should be \"$obj_name get KEY\""
  }
}

proc close_config {obj_name} {
  upvar #0 $obj_name arr
  if { [array exists arr] } { unset arr }
  rename $obj_name {}
}

proc dispatch {obj_name command args} {
  switch $command {
    {read}  { read_config $obj_name [lindex $args 0] }
    {get}   { return [get_value $obj_name [lindex $args 0]] }
    {set}   { set_value $obj_name [lindex $args 0] [lindex $args 1] }
    {unset} { return [unset_value $obj_name [lindex $args 0]] }
    {close} { close_config $obj_name }
    {keys}  { return [get_keys $obj_name] }
    {write} { write_config $obj_name [lindex $args 0] }
    default { puts "Error: Unknown command $command" }
  }
}

proc ::tclcfg::new {obj_name {args}} {
  set def_args [dict create {-defaults} {}]
  foreach {key value} $args {
    if {![dict exists $def_args $key]} {error "bad option '$key'"}
    dict set def_args $key $value
  }

  upvar #0 $obj_name arr
  dict for {key value} [dict create {*}[dict get $def_args {-defaults}]] {
    set arr($key) $value
  }

  proc ::$obj_name {command args} \
    "return \[eval dispatch $obj_name \$command \$args\]"
  puts $obj_name
}

package provide tclcfg 0.1
