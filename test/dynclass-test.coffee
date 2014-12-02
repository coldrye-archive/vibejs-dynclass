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


vows

    .describe 'dynclass'

    .addBatch

        'dynclass must have been exported to the global namespace' : ->

            assert.isDefined (window ? global).dynclass
            assert.isFunction dynclass

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

    .export module

