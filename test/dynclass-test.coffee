#
# Copyright 2014 Carsten Klein
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and 
# limitations under the License.
#


vows = require 'vows'
assert = require 'assert'
util = require 'util'

require 'vibejs-subclassof/macros'

require '../src/dynclass'


# for debugging purposes
#console.debug = console.log
#dynclass.logger = console


# since we are unable to test some implementation details
# as they are internal and not exported, we resort to
# testing only what gets exported


# useful helpers


dynclassPublicPropertyTest = (propertyName) ->

    ->

        assert.isEnumerable dynclass, propertyName

        descriptor = Object.getOwnPropertyDescriptor dynclass, propertyName
        assert.isFalse descriptor.configurable
        assert.isFunction descriptor.get || descriptor.value


classFactoryFunctionTest = (topic) ->

    assert.isFunction topic
    assert.isEnumerable topic, 'flags'
    assert.isEnumerable topic, 'abstract'
    assert.isEnumerable topic, 'static'
    assert.isEnumerable topic, 'final'
    assert.isEnumerable topic, 'private'
    assert.isEnumerable topic, 'isAbstract'
    assert.isEnumerable topic, 'isPrivate'
    assert.isEnumerable topic, 'isStatic'
    assert.isEnumerable topic, 'isFinal'


testHelperFunctionTest = (topic) ->

    assert.isFunction topic

    # test against error handling

    # klass is null
    cb = ->

        topic null

    assert.throws cb, TypeError

    # klass is not a function 
    cb = ->

        topic {}

    assert.throws cb, TypeError

    # fieldName is not defined
    cb = ->

        topic dynclass(), 'undefined'

    assert.throws cb, TypeError

    # fieldName is not a string
    cb = ->

        topic dynclass(), {}

    assert.throws cb, TypeError


vows

    .describe 'dynclass'

    .addBatch

        'must have been exported to the global namespace' : ->

            assert.isDefined (window ? global).dynclass

        'is a function' : ->

            assert.isFunction dynclass

        'has a property "static"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'static'

            'that when accessed' :

                topic: ->

                    dynclass.static

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isStatic

        'has a property "final"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'final'

            'that when accessed' :

                topic: ->

                    dynclass.final

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isFinal

                'and when chained with "abstract" will raise an exception' : (topic) ->

                    cb = ->

                        topic.abstract

                    assert.throws cb, TypeError

        'has a property "private"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'private'

            'that when accessed' :

                topic: ->

                    dynclass.private

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isPrivate

        'has a property "abstract"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'abstract'

            'that when accessed' :

                topic: ->

                    dynclass.abstract

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isAbstract

                'and when chained with "final" will raise an exception' : (topic) ->

                    cb = ->

                        topic.final

                    assert.throws cb, TypeError

        'has a property "property"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'property'

            'that when accessed' :

                topic : ->

                    dynclass.property

        'has a property "method"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'method'

            'that when accessed' :

                topic : ->

                    dynclass.method

        'has a property "isStatic"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'isStatic'

            'that when accessed' :

                topic : ->

                    dynclass.isStatic

                'has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

            '(static) that when queried for' :

                topic : ->

                    dynclass.static

                        extend :

                            prop : dynclass.property.static.defaultValue null

                            meth : dynclass.method.static.impl ->

                'a static class will return true' : (topic) ->

                    assert.isTrue dynclass.isStatic topic

                'a static property will return true' : (topic) ->

                    assert.isTrue dynclass.isStatic topic, 'prop'

                'a static method will return true' : (topic) ->

                    assert.isTrue dynclass.isStatic topic, 'meth'

            '(non static) that when queried for' :

                topic : ->

                    dynclass

                        extend :

                            prop : dynclass.property.defaultValue null

                            meth : dynclass.method.impl ->

                'a non static class will return false' : (topic) ->

                    assert.isFalse dynclass.isStatic topic

                'a non static property will return false' : (topic) ->

                    assert.isFalse dynclass.isStatic topic, 'prop'

                'a non static method will return false' : (topic) ->

                    assert.isFalse dynclass.isStatic topic, 'meth'

        'has a property "isAbstract"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'isAbstract'

            'that when accessed' :

                topic : ->

                    dynclass.isAbstract

                'has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

            '(abstract) that when queried for' :

                topic : ->

                    dynclass.abstract

                        extend :

                            prop : dynclass.property.abstract

                            meth : dynclass.method.abstract.impl ->

                'an abstract class will return true' : (topic) ->

                    assert.isTrue dynclass.isAbstract topic

                'an abstract property will return true' : (topic) ->

                    assert.isTrue dynclass.isAbstract topic, 'prop'

                'an abstract method will return true' : (topic) ->

                    assert.isTrue dynclass.isAbstract topic, 'meth'

            '(non abstract) that when queried for' :

                topic : ->

                    dynclass

                        extend :

                            prop : dynclass.property.defaultValue null

                            meth : dynclass.method.impl ->

                'a non abstract class will return false' : (topic) ->

                    assert.isFalse dynclass.isAbstract topic

                'a non abstract property will return false' : (topic) ->

                    assert.isFalse dynclass.isAbstract topic, 'prop'

                'a non abstract method will return false' : (topic) ->

                    assert.isFalse dynclass.isAbstract topic, 'meth'

        'has a property "isPrivate"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'isPrivate'

            'that when accessed' :

                topic : ->

                    dynclass.isPrivate

                'has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

            '(private) that when queried for' :

                topic : ->

                    dynclass.private

                        extend :

                            prop : dynclass.property.private

                            meth : dynclass.method.private.impl ->

                'a private class will return true' : (topic) ->

                    assert.isTrue dynclass.isPrivate topic

                'a private property will return true' : (topic) ->

                    assert.isTrue dynclass.isPrivate topic, 'prop'

                'a private method will return true' : (topic) ->

                    assert.isTrue dynclass.isPrivate topic, 'meth'

            '(non private) that when queried for' :

                topic : ->

                    dynclass

                        extend :

                            prop : dynclass.property.defaultValue null

                            meth : dynclass.method.impl ->

                'a non private class will return false' : (topic) ->

                    assert.isFalse dynclass.isPrivate topic

                'a non private property will return false' : (topic) ->

                    assert.isFalse dynclass.isPrivate topic, 'prop'

                'a non private method will return false' : (topic) ->

                    assert.isFalse dynclass.isPrivate topic, 'meth'

        'has a property "isFinal"' :

            'that has a specified set of qualities' : dynclassPublicPropertyTest 'isFinal'

            'that when accessed' :

                topic : ->

                    dynclass.isFinal

                'has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

            '(final) that when queried for' :

                topic : ->

                    dynclass.final

                        extend :

                            prop : dynclass.property.final

                            meth : dynclass.method.final.impl ->

                'a final class will return true' : (topic) ->

                    assert.isTrue dynclass.isFinal topic

                'a final property will return true' : (topic) ->

                    assert.isTrue dynclass.isFinal topic, 'prop'

                'a final method will return true' : (topic) ->

                    assert.isTrue dynclass.isFinal topic, 'meth'

            '(non final) that when queried for' :

                topic : ->

                    dynclass

                        extend :

                            prop : dynclass.property.defaultValue null

                            meth : dynclass.method.impl ->

                'a non final class will return false' : (topic) ->

                    assert.isFalse dynclass.isFinal topic

                'a non final property will return false' : (topic) ->

                    assert.isFalse dynclass.isFinal topic, 'prop'

                'a non final method will return false' : (topic) ->

                    assert.isFalse dynclass.isFinal topic, 'meth'

        'has a property "isMethod"' :

            topic : ->

                dynclass.isMethod

            'that has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

        'has a property "isProperty"' :

            topic : ->

                dynclass.isProperty

            'that has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

        'has a property "isReadonly"' :

            topic : ->

                dynclass.isReadonly

            'that has a specified set of qualities and specific error handling behaviour' : testHelperFunctionTest

    .export module

###
        'when creating a class dynamically' :

            'the created class' :

                topic : ->

                    dynclass

                        name : 'testclass'

                'must be of type function' : (topic) ->

                    assert.isFunction topic

                'must have the expected name' : (topic) ->

                    assert.equal topic.name, 'testclass'

            'without a base class, the created class' :

                topic : ->

                    dynclass

                        name : 'testclass'

                'must not have a __super__ property' : (topic) ->

                    assert.isUndefined topic.__super__

            'with a base class, the created class' :

                topic : ->

                    result =

                        Base : class Base

                            Object.defineProperty @, '_PrivateStaticBaseProperty',

                                enumerable : false

                                value : 1

                            @StaticBaseProperty : 1

                            @StaticBaseMethod : ->

                            BaseMethod : ->

                            _InternalBaseProperty : 1

                            BaseProperty : 1

                        TestClass : dynclass

                            name : 'testclass'

                            base : Base

                            static :

                                _PrivateStaticProperty : 1

                                StaticProperty : 1

                                StaticMethod : ->

                            instance :

                                _InternalProperty : 1

                                Property : 1

                                Method : ->

                'must have a __super__.constructor property equal to the expected base' : (topic) ->

                    assert.strictEqual topic.TestClass.__super__.constructor, topic.Base

                'must inherit the base class\' non private static fields unaltered' : (topic) ->

                    assert.isEnumerable topic.TestClass, 'StaticBaseMethod'
                    assert.strictEqual topic.TestClass.StaticBaseMethod, topic.Base.StaticBaseMethod

                'must not inherit non enumerable (private) fields of base class' : (topic) ->

                    assert.isUndefined topic.TestClass._PrivateStaticBaseProperty

                'must have the expected non enumerable private static fields' : (topic) ->

                    assert.isNotEnumerable topic.TestClass, '_PrivateStaticProperty'
###


