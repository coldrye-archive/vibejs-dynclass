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


# we export most of this to the global namespace
exports = window ? global


# guard preventing us from exporting twice
unless exports.dynclass?

    # dummy class used for making coffee compile in 
    # the latest version of __extends
    class _JustForTheExtends extends Object

    __hasOwnProperty = Object.hasOwnProperty

    # Custom extend function so we do not have to
    # depend on underscore
    _extend = (obj, extensions, configurable, debug) ->

        for key, value of extensions

            if __hasOwnProperty.call extensions, key

                debug "dynclass:extending class by #{key} = #{value}"

                enumerable = true

                if key.charAt(0) == '_'

                    debug "dynclass:making #{key} non enumerable"

                    enumerable = false

                Object.defineProperty obj, key,

                    enumerable : enumerable

                    configurable : configurable

                    value : value

        undefined


    _extenderPartial = (obj, configurable, debug) ->

        (extensions) ->

            _extend obj, extensions, configurable, debug

    # no op function
    noopfun = ->

    # counter used for creating unique anonymous class names
    # in case that the user fails to provide a custom name
    anonClassCount = 0

    # The function dynclass models a factory for dynamically creating
    # new classes.
    #
    # @param Object options optionsaration options
    # @option options Object logger optional logger used for debugging purposes (must have a debug() method)
    # @option options Object base base class
    # @option options String name name of the dynamically created class
    # @option options Boolean chainSuper chain call to super on instantiation, default: true
    # @option options Function ctor mixin to be applied on instantiation
    # @option options Object|Function extend instance methods and properties or callback
    # @option options Object|Function static static methods and properties or callback
    # @option options Boolean configurable false whether the members of the class should be non configurable, default: true
    # TODO:@option options Boolean freeze true whether the resulting class should be frozen, default: false
    exports.dynclass = (options = {}) ->

        result = null

        logger = options.logger ? null

        if logger and typeof logger.debug != 'function'

            throw new Error 'the specified logger does not have a debug method.'

        debug = if logger then logger.debug else noopfun

        name = options.name
        if not name

            name = "AnonClass_#{anonClassCount}"
            anonClassCount++

        debug "dynclass:creating class #{name}"

        ctorMixin = options.ctor || noopfun

        if ctorMixin != noopfun

            debug 'dynclass:using custom ctor mixin'

        chainSuper = if options.chainSuper is false then false else true
        configurable = if options.configurable is false then false else true

        base = options.base

        if base and chainSuper is true

            debug 'dynclass:chaining super on instantiation'

            eval "result = function #{name}() {" +
                 "    #{name}.__super__.constructor.apply(" +
                 "        this, arguments" +
                 "    );" +
                 "    ctorMixin.apply(this, arguments);" +
                 "};"

        else

            debug 'dynclass:not chaining super on instantiation'

            eval "result = function #{name}() {" +
                 "    ctorMixin.apply(this, arguments);" +
                 "}"

        if base

            debug 'dynclass:inheriting from specified base class #{base.name}'

            eval("__extends(result, base)")

        extender = _extenderPartial result, configurable, debug

        if options.static

            debug 'dynclass:mixing in specified static properties'

            if typeof options.static is 'function'

                debug 'dynclass:calling user defined callback'

                options.static result, extender, logger 

            else

                extender options.static

        if options.extend

            debug 'dynclass:mixing in specified instance properties'

            if typeof options.extend is 'function'

                debug 'dynclass:calling user defined callback'

                options.extend result, extender, logger

            else

                extender options.extend

        if options.freeze

            debug 'dynclass:freezing created class'

            Object.freeze result

        result

