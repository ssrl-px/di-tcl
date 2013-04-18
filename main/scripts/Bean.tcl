#
# Loads config from files
#
package provide DependencyInjector 3.0
package require Itcl

itcl::class DI::Bean {

    public variable beanName 
    public variable WORKSPACE "."

    public method afterPropertiesSet {} {}

    public method assertPropertyNotEmpty {propertyName {possibleValues ""} } {
        upvar 1 $propertyName property 
        set val $property

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
        upvar 1 $propertyName property 
        set val $property

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
        upvar 1 $propertyName property
        set val $property

        foreach member $val {
            if { [catch {assertPropertyIsaClass member $possibleClasses} err ] } {
                puts $err
                error "$member in '${beanName}.${propertyName}' must be instantiated from one of : $possibleClasses"
            }
        }
    }

}

