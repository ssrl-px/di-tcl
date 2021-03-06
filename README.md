
di-tcl
===========

Spring inspired dependency injection for Incr Tcl.


###Dependency Injection Engine ('Bean Factory' in Spring terminology)

## Public methods
* load _propertiesFile_:  Loads a plain text properties file to define all of the spring-like beans
* createObjectByName _objectName_: Creates an Incr tcl object from the bean definition

## Example Usage

```tcl
package require DependencyInjector 3.1
#instantiate the Dependency Injector
set di [DI::DependencyInjector #auto ]
#load the properties file
$di load myObjects.properties
set myClock [$di createObjectByName clock]
```

### Testing install

```
>cd test/scripts
>tclsh ./all.tcl
Tests ended at Mon Jul 01 05:36:23 PM PDT 2013
all.tcl:        Total   9       Passed  9       Skipped 0       Failed  0
Sourced 2 Test Files.
```


###Defining an Incr-tcl bean

The following two example Incr tcl classes both inherit from the Dhs::DependencyInjectionBean class.  This class type will allow the DI engine to call the afterPrope
rtiesSet method once the object has been constructed (this is similar to the InitializingBean in Spring).  All public variables on the classes can be set from the co
nfiguration file.
 
```tcl
class Dhs::Clock {
 
    inherit DCS::DependencyInjectionBean
    public variable tickPeriodMs 200
    public variable listeners
    private variable totalSleepTimeMs 0
    private variable initialTime 0
    public method afterPropertiesSet {} {
        set initialTime [clock seconds]
        monitor
    }
    public method monitor {} {
        foreach listener $listeners {
            if { [catch {
                $listener tick $totalSleepTimeMs [expr [clock seconds] - $initialTime]
            } err ]} {
                global errorInfo
                puts $errorInfo
            }
        }
        incr totalSleepTimeMs $tickPeriodMs
        after [expr $tickPeriodMs] [list $this monitor]
    }
}
class Dhs::ClockLogger {
    inherit DCS::DependencyInjectionBean
    public variable period 5000
   
    public method tick {sleepTimeMs totalElapsedTimeS} {
        if { [expr $sleepTimeMs % $period ] == 0 } {
            puts "ElapsedTime: $totalElapsedTimeS s"
        }
    }
}
```

##Defining objects (beans) in the config file.
 
Within the configuration file, classes are instantiated and public variables are configured using the following syntax:

```
beanName.propertyName=value
```
 
 
Some fixed properties are enclosed in ().  They include:
 
* (class): The value contains the name of the class for the DI engine to instantiate from. 
* (parent): The value contains the name of a different bean.  The DI engine apply all of the properties from the parent bean onto this bean.  Properties set on this bean will override the properties set by the parent.
* (singleton): value can be either true or false and indicates whether a new bean is created for each reference to this bean (false), or if the same object should be shared between many other beans references (true).
* (ref) modifier preceeding a value: instructs the DI engine to first create another object defined in the config file and then use this object as the property value.
* (list) modifier appended to property value: instructs the DI engine that the property values will be a space separated list of values, which can be (ref) objects.
 
In the following configuration file, two objects are defined: a clock and a clockLogger.  The name of the object is defined by the author of the configuration file.  Properties are set using the following syntax: beanName.propertyName=value

```
clock.(class)=Dhs::Clock
clock.tickPeriodMs=100
clock.listeners(list)=(ref)clockLoggerSlow (ref)clockLoggerFast
clockLoggerSlow.(class)=Dhs::ClockLogger
clockLoggerSlow.period=60000
clockLoggerFast.(class)=Dhs::ClockLogger
clockLoggerFast.period=1000
```

##Asserting value types on properties
 
It is possible to assert that the values on a property are set with the correct type be checking the values in the afterPropertiesSet method.  There are three methods in the DependencyInjectionBean for value and type-checking.
 
* assertPropertyNotEmpty [optional list of valid values]
* ssertPropertyIsaClass propertyName className
* assertEachListMemberIsaClass propertyName {className className ..}
 
Example:

```Tcl
    public method afterPropertiesSet {} {
 
        assertPropertyIsaClass motor1 Dhs::MotorBase
        assertPropertyIsaClass motor2 Dhs::MotorBase
        assertPropertyIsaClass translation Dhs::MotorBase
        assertPropertyNotEmpty MT [list -2.5 2.5 -2.0 2.0]
    }
```



###Factory Bean

A bean defined in the properties file with a (class) property of DI::BeanFactory will be populated with
a bean returned by the BeanFactory's getObject method (not the BeanFactory object itself). The base DI::BeanFactory
class takes a property, 'bean', which refers to another bean in the configuration file to be instantiated instead
of the BeanFactory. 

If a bean in the configuration file needs the BeanFactory object itself, then
preceed the bean name of the factory with an ampersand.  In this case, from the application code, call the 'getObject' method on the BeanFactory
to generate new instances of beans without having access or knowledge of the configuration file. 

The following is an example configuration from the test directory:

```
#factory bean tests
hondaFactory.(class)=DI::FactoryBean
hondaFactory.bean=honda

honda.(class)=Car
honda.(singleton)=false
honda.make=civic
honda.year=2013


mazdaFactory.(class)=DI::FactoryBean
mazdaFactory.bean=mazda3

mazda3.(class)=Car
mazda3.(singleton)=false
mazda3.make=mazda
mazda3.year=
```

## Importing files

Use the property '@import=filename.properties' to load additional properties from other
files into the bean factory. The properties are loaded in the order that they appear
in the file. Imported files may also import their own files which are loaded before
the top import is completed. Files that have been previously imported are not imported
again, which prevents endless recursive imports. Conflicts on properties are always
resolved by allowing the latest property definition to overwrite previous definitions. It
is strongly recommended to put all of the imports at the top of a property file.


Example:

```
@import=application.properties
@import=scripts.properties
@import=galil.properties
@import=standard-devices.properties
@import=microspec.properties
```

## License

                           Copyright 2010
                                 by
                    The Board of Trustees of the 
                  Leland Stanford Junior University
                         All rights reserved.
    
    
                          Disclaimer Notice
    
        The items furnished herewith were developed under the sponsorship
    of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
    Leland Stanford Junior University, nor their employees, makes any war-
    ranty, express or implied, or assumes any liability or responsibility
    for accuracy, completeness or usefulness of any information, apparatus,
    product or process disclosed, or represents that its use will not in-
    fringe privately-owned rights.  Mention of any product, its manufactur-
    er, or suppliers shall not, nor is it intended to, imply approval, dis-
    approval, or fitness for any particular use.  The U.S. and the Univer-
    sity at all times retain the right to use and disseminate the furnished
    items for any purpose whatsoever.                       Notice 91 02 01
    
      Work supported by the U.S. Department of Energy under contract
      DE-AC02-76SF00515; and the National Institutes of Health, National
      Center for Research Resources, grant P41RR001209. 
    
    
                          Permission Notice
    
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
    BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
    EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
    THE USE OR OTHER DEALINGS IN THE SOFTWARE.


