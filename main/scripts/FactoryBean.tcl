#
# Loads config from files
#
package provide DependencyInjector 3.3
package require Itcl

itcl::class DI::FactoryBean {

    inherit DI::Bean

    public variable bean
    public variable FACTORY

    public method afterPropertiesSet {} {
        assertPropertyNotEmpty bean
    }

    public method getObject {} {
        return [$FACTORY createObjectByName $bean]
    }

}

