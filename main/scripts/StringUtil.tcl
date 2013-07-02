#
package provide DependencyInjector 3.3
package require Itcl

itcl::class DI::StringUtil {

    proc endsWith { str ending } {
        if {$ending == "" } {return true}
        set strLen [string length $str]
        set endLen [string length $ending]
        if {$strLen < $endLen } {return false}
        
        if { [string range $str [expr $strLen - $endLen] end] == "$ending" } {return true}
        return false
    }


    proc trimEnd { str ending } {
        if { ! [endsWith $str $ending] } {
            return $str
        }

        set strLen [string length $str]
        set endLen [string length $ending]

        return [string range $str  0 [expr $strLen - $endLen - 1]]
    }


    proc trimFirst { str startStr } {
        if { ! [string match "${startStr}*" $str] } {
            return $str
        }

        return [string range $str [string length $startStr] end]
    }
}

