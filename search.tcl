#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
         exec tclsh "$0" ${1+"$@"}

        if { $argc < 1} {
            error "search text"
        }
        set text [lindex $argv 0]
        puts "searching for $text"
        #puts [exec find . -name DataProcessing-P.yaml]
        #set cmd [list find . -name "*" -exec grep -H $text '\{\}' \;]
        set cmd [list find main -name "*" -exec grep -H $text \{\} \;]
        set result [eval exec $cmd]
        foreach line [split $result "\n"] {
            foreach file [string range $line 0 [string first ":" $line]] {
                set exclude false
                foreach element [file split $file] {
                    if {$element == ".svn"} {
                        set exclude true
                        break;
                    }
                }
                if {$exclude} continue;
                puts $line
            }
        }

