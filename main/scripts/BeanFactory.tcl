#
# Loads config from files
#
package provide DependencyInjector 3.0
package require Itcl

itcl::class DI::BeanFactory {

    inherit DI::Bean

    public variable bean
    public variable FACTORY

    public method afterPropertiesSet {} {
        assertPropertyNotEmpty bean
    }

    public method create {} {
        return [$FACTORY createObjectByName $bean]
    }

}

