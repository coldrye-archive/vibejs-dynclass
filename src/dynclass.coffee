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
    _extend = (obj, extensions, logger) ->

        for key, value of extensions

            if __hasOwnProperty.call extensions, key

                logger?.debug "dynclass:extending class by #{key} = #{value}"

                obj[key] = value

        undefined

    # default ctor mixin
    defaultCtorMixin = ->

    # counter used for creating unique anonymous class names
    # in case that the user fails to provide a custom name
    anonClassCount = 0

    # The function dynclass models a factory for dynamically creating
    # new classes.
    #
    # @param Object decl declaration options
    # @option decl Object logger optional logger used for debugging purposes (must have a debug() method)
    # @option decl Object base base class
    # @option decl String name name of the dynamically created class
    # @option decl Boolean chainSuper chain call to super on instantiation, default: true 
    # @option decl Function ctor mixin to be applied on instantiation
    # @option decl Object|Function extend instance methods and properties
    # @option decl Object|Function static static methods and properties
    # TODO:@option decl Boolean freeze true whether the resulting class should be frozen, default: false
    exports.dynclass = (decl = {}) ->

        result = null

        logger = decl.logger ? null

        if logger and typeof logger.debug != 'function'

            throw new Error 'the specified logger does not have a debug method.'

        name = decl.name
        if not name

            name = "AnonClass_#{anonClassCount}"
            anonClassCount++

        logger?.debug "dynclass:creating class #{name}"

        ctorMixin = decl.ctor || defaultCtorMixin

        if ctorMixin != defaultCtorMixin

            logger?.debug 'dynclass:using custom ctor mixin'

        chainSuper = if decl.chainSuper is false then false else true

        base = decl.base

        if base and chainSuper is true

            logger?.debug "dynclass:chaining super on instantiation"

            eval "result = function #{name}() {" +
                 "    #{name}.__super__.constructor.apply(" +
                 "        this, arguments" +
                 "    );" +
                 "    ctorMixin.apply(this, arguments);" +
                 "};"

        else

            logger?.debug "dynclass:not chaining super on instantiation"

            eval "result = function #{name}() {" +
                 "    ctorMixin.apply(this, arguments);" +
                 "}"

        if base

            logger?.debug "dynclass:extending specified base class #{base.name}"

            eval("__extends(result, base)")

        if decl.static

            logger?.debug "dynclass:mixing in specified static properties"

            if typeof decl.static is 'function'

                decl.static result

            else

                _extend result, decl.static

        if decl.extend

            logger?.debug "dynclass:mixing in specified instance properties"

            if typeof decl.extend is 'function'

                decl.extend result

            else

                _extend result.prototype, decl.extend, logger

        if decl.freeze

            Object.freeze result

        result

