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


# since we are unable to test some implementation details
# as they are internal and not exported, we resort to
# testing only what gets exported


# useful helpers

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

            'that is enumerable' : ->

                assert.isEnumerable dynclass, 'static'

            'that when accessed' :

                topic: ->

                    dynclass.static

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isStatic

        'has a property "final"' :

            'that is enumerable' : ->

                assert.isEnumerable dynclass, 'final'

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

            'that is enumerable' : ->

                assert.isEnumerable dynclass, 'private'

            'that when accessed' :

                topic: ->

                    dynclass.private

                'has a specified set of qualities' : classFactoryFunctionTest

                'and called with the proper set of options will return the requested class' : (topic) ->

                    klass = topic()

                    assert.isFunction klass
                    assert.isTrue topic.isPrivate

        'has a property "abstract"' :

            'that is enumerable' : ->

                assert.isEnumerable dynclass, 'abstract'

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

        'has a helper "isStatic"' :

            topic : ->

                dynclass.isStatic

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


