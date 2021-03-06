#
package provide DependencyInjector 3.3
package require Itcl

# ===================================================
#
# ===================================================
itcl::class DI::DependencyInjector {
    public variable WORKSPACE "."

    private variable CLASS_PROP (class)
    private variable PARENT_PROP (parent)
    private variable SINGLETON_PROP (singleton)
    private variable REF_PROP (ref)
    private variable REF_LIST (list)
    private variable REF_MAP (map)

    private variable _singletonArray
    private variable _propArray
    private variable _importArray

    constructor { } {
        array set _singletonArray {}
        array set _propArray {}
        array set _importArray {}
    }

    public method load { filename } {

        set in [open $filename r]
        set raw [read $in]
        close $in

        #clean raw data & make array
        foreach line [split $raw "\n"] {
            #guard blank lines and comments
            set trimLine [string trim $line]
            if { $trimLine == "" } continue

            #ignore comments
            set firstChar [string index $trimLine 0]
            if { $firstChar == "#" || $firstChar == "!" } continue;

            foreach {rawProp rawValue} [splitProperty $trimLine] {}
            #foreach {rawProp rawValue} [split $trimLine =] {}
            set prop [string trim $rawProp]
            set val [string trim $rawValue]

            if {$prop == "@import"} {
                set dir [file dirname $filename]
                set importFile [file join $dir $val]
                #guard against self recursive imports
                if { [info exists _importArray($importFile)] } {
                    continue;
                }
                set _importArray($importFile) loaded
                load $importFile
            } else {
                set _propArray($prop) $val
            }
            #lappend clean $trimLine
        }    

        #puts [array names _propArray]

    }



    #splits a string into a property and value
    private method splitProperty { str {char "="} } {

        set tokenIndex [string first $char $str]
        if {$tokenIndex == -1} { return [list $str ""] }

        set prop [string range $str 0 [expr $tokenIndex -1]]
        set value [string range $str [expr $tokenIndex +1] end]

        return [list $prop $value]
    }


    private method propBase { property } {
        return [string range $property  0 [expr [string first "." $property] -1]]
    }

    private method trimBase { property} {
        return [string range $property [expr [string first "." $property] +1] end]
    }

    private method checkRef { property} {
        return [string match "*${REF_PROP}" $property]
    }

    private method checkList { property} {
        return [string match "*${REF_LIST}" $property]
    }

    private method checkMap { property} {
        return [string match "*${REF_MAP}" $property]
    }

    private method addItem { name className  } {
        set _singletonArray($name) [ItemStub #auto $className]
    }

    public method createObjectByName { name_ } {
        if { [string index $name_ 0] == "&" } {
            #trim off starting ampersand which is used to request actual bean factory
            set requestFactoryBean true
            set name [string range $name_ 1 end]
        } else { 
            set requestFactoryBean false
            set name $name_
        }

        #return singleton if exists
        if { [info exists _singletonArray($name) ] } {
            set obj $_singletonArray($name)
            if { [$obj isa DI::FactoryBean] && ! $requestFactoryBean } {
                return [$obj getObject]
            }
            return $obj
        }


        set obj [onlyCreateObjectByName $name]

        set singletonProp [array names _propArray -exact ${name}.$SINGLETON_PROP ]
        if { $_propArray($singletonProp) } {
            set _singletonArray($name) $obj
        }
        configureAllProp $obj $name

        #Bean Factories return the object they create, unless
        #the user prepends the beanFactory name with an ampersand, in which case they return themselves
        if { [$obj isa DI::FactoryBean] && ! $requestFactoryBean } {
            #always set Bean Factories in the singleton array?
            set _singletonArray($name) $obj
            return [$obj getObject]
        }

        return $obj
    }


    private method onlyCreateObjectByName { name } {

        set classProp [array names _propArray -exact ${name}.$CLASS_PROP ]
        set parentProp [array names _propArray -exact ${name}.$PARENT_PROP ]
        set singletonProp [array names _propArray -exact ${name}.$SINGLETON_PROP ]
        if {$singletonProp == "" } {
            #default is singleton
            set singletonProp "${name}.$SINGLETON_PROP"
            set _propArray($singletonProp) true
        }

        if { $classProp == "" } {
            if {$parentProp == ""} {
                return -code error "no class defined for $name"
            }
            set obj [onlyCreateObjectByName $_propArray($parentProp) ]
        } else {
            set obj [namespace current]::[$_propArray($classProp) #auto]
            #puts $obj
        }

        return $obj
    }
    
    private method configureAllProp {obj name {isParent false}} {

        set parentProp [array names _propArray -exact ${name}.$PARENT_PROP ]

        if {$parentProp != "" } {
            configureAllProp $obj $_propArray($parentProp) true
        }

        set propList [array names _propArray $name.*]
        #puts $propList

        foreach propName $propList {
            set prop [trimBase $propName]
            if {$prop == $CLASS_PROP } continue
            if {$prop == $PARENT_PROP } {
                continue
            }

            if {$prop == $SINGLETON_PROP } continue
            if { [checkRef $prop] } {
                set ref [createObjectByName $_propArray($propName)]
                $obj configure -[DI::StringUtil::trimEnd $prop $REF_PROP] $ref
                continue
            }

            if { [checkList $prop] } {
                set propOnly [DI::StringUtil::trimEnd $prop $REF_LIST] 
                set l [list]
                foreach val [eval list $_propArray($propName)] { 
                    lappend l [getRefOrValue $val]
                }
                $obj configure -$propOnly $l 
                continue
            }

            if { [checkMap $prop] } {
                #set propOnly [DI::StringUtil::trimEnd $prop $REF_MAP] 
                #set a 
                #foreach {name val} [eval list $_propArray($propName)] { 
                #    set a($name) [getRefOrValue $val]
                #}
                #$obj configure -$propOnly $a 
                #continue
            }

            configureProp $obj $prop [getRefOrValue $_propArray($propName)] 
        }
        
        if {[$obj isa DI::FactoryBean]} {
            $obj configure -FACTORY $this 
        }
        if {[$obj isa DI::Bean]} {
            #puts "BEAN $name"
            $obj configure -beanName $name
            $obj configure -WORKSPACE $WORKSPACE
            if { ! $isParent } {
                if { [catch {
                    $obj afterPropertiesSet
                    } err ] } {
                    #clean up
                    delete object $obj
                    error $err
                }
            }
        } 
    }

    private method getRefOrValue { val_ } {
        if { [string match "${REF_PROP}*" $val_] } {
            set o [createObjectByName [DI::StringUtil::trimFirst $val_ $REF_PROP]]
        } else {
            set o $val_
        }
        return $o
    }

    private method configureProp {obj prop value} {
        $obj configure -$prop $value
    }

}

