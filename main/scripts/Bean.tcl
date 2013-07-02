#
# Loads config from files
#
package provide DependencyInjector 3.3
package require Itcl

itcl::class DI::Bean {

    public variable beanName 
    public variable WORKSPACE "."

    public method afterPropertiesSet {} {}

    public method assertPropertyNotEmpty {propertyName {possibleValues ""} } {
        if {[catch {
            set val [cget -$propertyName]
        } err] } {
            error "'$propertyName' is not defined in $beanName"
        }

        if { $val == "" } {
            if { [llength $possibleValues] == 0 } {
                error "'${beanName}.${propertyName}' must be set"
            } else {
                error "'${beanName}.${propertyName}' must be set to one of: $possibleValues"
            }
        } 
    
        if { [llength $possibleValues] != 0 } {
            if { [lsearch $possibleValues $val] == -1 } {
                error "'${beanName}.${propertyName}' must be set to one of: $possibleValues"
            }
        }
    }

    public method assertPropertyIsaClass {propertyName possibleClasses } {
        if {[catch {
            set val [cget -$propertyName]
        } err] } {
            error "'$propertyName' is not defined in $beanName : $err"
        }

        if { $val == "" } {
            if { [llength $possibleClasses] == 0 } {
                error "'${beanName}.${propertyName}' must be set"
            } else {
                error "'${beanName}.${propertyName}' must be instantiated from one of : $possibleClasses"
            }
        } 
    
        foreach className $possibleClasses {
            if { [$val isa $className] } return
        }

        error "'${beanName}.${property}' must be instantiated from one of : $possibleClasses"
    }


    public method assertEachListMemberIsaClass {propertyName possibleClasses } {
        if {[catch {
            set val [cget -$propertyName]
        } err] } {
            error "'$propertyName' is not defined in $beanName"
        }

        foreach member $val {
            set valid false
            foreach className $possibleClasses {
                if { [ $member isa $className] } {set valid true}
            }
            if { ! $valid} {
                error "$member in '${beanName}.${propertyName}' must be instantiated from one of : $possibleClasses"
            }
        }
    }

}

