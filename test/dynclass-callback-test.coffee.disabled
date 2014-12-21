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


vows

    .describe 'dynclass with callbacks'

    .addBatch

        'when providing a callback for static' :

            'dynclass must call the callback' :

                'with the correct (number of) parameters' : ->

                    dynclass 

                        name : 'testclass'

                        static : (klass, extender, logger) ->

                            assert.equal arguments.length, 3
                            assert.isFunction klass
                            assert.equal klass.name, 'testclass'
                            assert.isFunction extender
                            assert.isNull logger

                'with the provided logger' : ->

                    dummylogger =

                        debug : ->

                    dynclass 

                        name : 'testclass'

                        logger : dummylogger

                        static : (klass, extender, logger) ->

                            assert.strictEqual logger, dummylogger

            'calling back the extender must extend the class as expected' : ->

                testclass = dynclass

                    name : 'testclass'

                    static : (klass, extender, logger) ->

                        extender

                            _NonEnumerable : 1

                            Enumerable : 2

                            EnumerableMethod : ->

                assert.isNotEnumerable testclass, '_NonEnumerable'
                assert.isEnumerable testclass, 'Enumerable'
                assert.isEnumerable testclass, 'EnumerableMethod'
                assert.equal testclass._NonEnumerable, 1
                assert.equal testclass.Enumerable, 2
                assert.isFunction testclass.EnumerableMethod

        'when providing a callback for instance' :

            'dynclass must call the callback' :

                'with the correct (number of) parameters' : ->

                    dynclass 

                        name : 'testclass'

                        static : (klass, extender, logger) ->

                            assert.equal arguments.length, 3
                            assert.isFunction klass
                            assert.equal klass.name, 'testclass'
                            assert.isFunction extender
                            assert.isNull logger

                'with the provided logger' : ->

                    dummylogger =

                        debug : ->

                    dynclass 

                        name : 'testclass'

                        logger : dummylogger

                        static : (klass, extender, logger) ->

                            assert.strictEqual logger, dummylogger

            'calling back the extender must extend the class as expected' : ->

                testclass = dynclass

                    name : 'testclass'

                    static : (klass, extender, logger) ->

                        extender

                            _NonEnumerable : 1

                            Enumerable : 2

                            EnumerableMethod : ->

                assert.isNotEnumerable testclass, '_NonEnumerable'
                assert.isEnumerable testclass, 'Enumerable'
                assert.isEnumerable testclass, 'EnumerableMethod'
                assert.equal testclass._NonEnumerable, 1
                assert.equal testclass.Enumerable, 2
                assert.isFunction testclass.EnumerableMethod

    .export module

