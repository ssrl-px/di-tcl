#!/usr/bin/tclsh
#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#
package require Itcl
namespace import ::itcl::*
package require DependencyInjector 3.0
package require tcltest


class Person {
    inherit DI::Bean 
    public variable person_id
    public variable slac_id
    public variable safetyTalk
    public variable first_name
    public variable last_name
    public variable middle_name
    public variable email_address
    public variable citizenship
    public variable safetyAgreementDate

    public variable address
    public variable userAgreement

    public method afterPropertiesSet {} {
        assertPropertyIsaClass address Address
        assertPropertyNotEmpty last_name
    }
}

class Address {
    inherit DI::Bean
    public variable address1
    public variable address2
    public variable city
    public variable state
    public variable zipcode
    public variable country
    public variable institution
    public method afterPropertiesSet {} {
    }
}

class Institution {
    inherit DI::Bean 
    public variable name
    public variable insti_id
    public method afterPropertiesSet {} {}
}


class Team {
    inherit DI::Bean 
    public variable people
    public method afterPropertiesSet {} {
        assertEachListMemberIsaClass people Person
    }
}

class Car {
    inherit DI::Bean
    public variable make
    public variable year
}

variable SETUP {
    set filename ../resources/DependencyInjectionData.config
    set __di [DI::DependencyInjector #auto]
    $__di load $filename
}

variable CLEANUP {
    delete object $__di
    delete object $obj1
}

    #beamline is the first argument when starting the program
tcltest::test createObjectFromDependencyInjection {normal return} \
    -setup $SETUP -cleanup $CLEANUP \
    -body {
    set obj1 [$__di createObjectByName joe]
    return [$obj1 cget -last_name]
} -result johnson


tcltest::test createObjectFromDependencyInjection2 {normal return} \
    -setup $SETUP -cleanup $CLEANUP \
    -body {
    set obj1 [$__di createObjectByName joe]
    set address [$obj1 cget -address]
    return [$address cget -city]
} -result "Los Angeles"


tcltest::test createObjectFromDependencyInjectionWithEquals {normal return} \
    -setup $SETUP -cleanup $CLEANUP \
    -body {
    set obj1 [$__di createObjectByName joe]
    set address [$obj1 cget -address]
    return [$address cget -address1]
} -result "University of California = Los Angeles"


tcltest::test createObjectFromDependencyInjection3 {normal return} \
    -setup $SETUP -cleanup $CLEANUP \
    -body {
        set obj1 [$__di createObjectByName team]
        set people [$obj1 cget -people]

        set names [list]
        foreach person $people {
            lappend names [$person cget -last_name]
        }
        return $names
    } -result [list johnson Peterson johnson]

tcltest::test testAssertFromDependency {failed assert test} \
    -setup $SETUP \
    -body {
        if { [catch {$__di createObjectByName badteam} err]} {
            if { [string first "must be instantiated from one of : Person" $err] == -1} {
                return fail
            }
            return pass
        }
        puts "should have had an error in the assert"
        return fail
    } -result pass

tcltest::test trimFirst {normal return} {
    DI::StringUtil::trimFirst HelloThere Hello
} There

#Test BeanFactory
tcltest::test createObjectFromFactory {normal return} \
    -setup $SETUP -cleanup $CLEANUP \
    -body {
    set carFactory [$__di createObjectByName hondaFactory]
    set obj1 [$carFactory create]
    
    delete object $carFactory

    return [$obj1 cget -make]    
} -result civic


#    set filename [lindex $argv 0]
#    set di [DCS::DependencyInjector #auto]
#    $di load $filename
#    set obj1 [$di createObjectByName joe]
#    set obj2 [$di createObjectByName joe]
#    puts [$obj1 cget -last_name]
#    puts [[$obj1 cget -address] cget -city]
#    puts "$obj1 $obj2"

#    set team [$di createObjectByName team]
#    puts "number of team members: [llength [$team cget -people]]"

#    foreach person [$team cget -people] {
#        puts [$person cget -last_name]
#    }


