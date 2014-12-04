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

    __hasOwnProperty = {}.hasOwnProperty

    # Custom extend function so we do not have to
    # depend on underscore
    _extend = (klass, extensions, debug) ->

        for key, field of extensions

            if __hasOwnProperty.call extensions, key

                debug "dynclass:extending class by #{key} = #{field}"

                field.validate()

                field.applyTo klass, key

        undefined


    _extenderPartial = (klass, debug) ->

        (extensions) ->

            _extend klass, extensions, debug

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

        extender = _extenderPartial result, debug

        if options.extend

            debug 'dynclass:defining fields'

            if typeof options.extend is 'function'

                debug 'dynclass:calling user defined callback'

                options.static result, extender, logger 

            else

                extender options.extend

        if options.freeze

            debug 'dynclass:freezing created class'

            Object.freeze result

        result


    class AbstractField

        @MODIFIER_ABSTRACT = 1
        @MODIFIER_FINAL = 2
        @MODIFIER_PRIVATE = 4
        @MODIFIER_STATIC = 8

        @FIELD_PROPERTY = 128
        @FIELD_METHOD = 256

        constructor : (type) ->

            @flags = type

            Object.defineProperty @, 'abstract',

                enumerable : true

                get : ->

                    if @isPrivate

                        throw new Error 'private fields cannot be declared abstract'

                    if @isFinal

                        throw new Error 'final fields cannot be declared abstract'

                    @flags |= AbstractField.MODIFIER_ABSTRACT

                    @

            Object.defineProperty @, 'final',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new Error 'abstract fields cannot be declared final'

                    @flags |= AbstractField.MODIFIER_FINAL

                    @

            Object.defineProperty @, 'private',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new Error 'abstract fields cannot be declared private'

                    @flags |= AbstractField.MODIFIER_PRIVATE

                    @

            Object.defineProperty @, 'static',

                enumerable : true

                get : ->

                    @flags |= AbstractField.MODIFIER_STATIC

                    @

            Object.defineProperty @, 'isStatic',

                enumerable : true

                get : ->

                    (@flags & AbstractField.MODIFIER_STATIC) != 0

            Object.defineProperty @, 'isAbstract',

                enumerable : true

                get : ->

                    (@flags & AbstractField.MODIFIER_ABSTRACT) != 0

            Object.defineProperty @, 'isFinal',

                enumerable : true

                get : ->

                    (@flags & AbstractField.MODIFIER_FINAL) != 0

            Object.defineProperty @, 'isPrivate',

                enumerable : true

                get : ->

                    (@flags & AbstractField.MODIFIER_PRIVATE) != 0

        validate : ->

            throw new Error 'derived classes must implement this.'

        applyTo : (klass, name) ->

            throw new Error 'derived classes must implement this.'


    determineApplicant = (klass, field) ->

        if field.isStatic then klass else klass.prototype


    class PropertyField extends AbstractField

        constructor : ->

            super AbstractField.FIELD_PROPERTY

            Object.defineProperty @, 'getter',

                enumerable : true

                get : ->

                    (getter) ->

                        @getter = getter

                        @

            Object.defineProperty @, 'setter',

                enumerable : true

                get : ->

                    (setter) ->

                        @setter = setter

                        @

            Object.defineProperty @, 'isReadonly',

                enumerable : true

                get : ->

                    not @setter

        validate : (name) ->

            if @getter and typeof @getter != 'function'

                throw new Error "getter for #{name} is not a function"

            if @setter and typeof @setter != 'function'

                throw new Error "setter for #{name} is not a function"

            throw new Error 'not implemented yet'

        applyTo : (klass, name) ->

            applicant = determineApplicant klass, @

            Object.defineProperty applicant, name,

                enumerable : not @isPrivate

                configurable : not @isFinal

                get : @getter

                set : @setter


    class MethodField extends AbstractField

        constructor : ->

            super AbstractField.FIELD_METHOD

            Object.defineProperty @, 'impl',

                enumerable : true

                get : ->

                    (impl) =>

                        @impl = impl

                        @

        validate : (name) ->

            if @impl and typeof @impl != 'function'

                throw new Error 'impl is not a function'

            if not @impl and @isFinal or not @isAbstract

                throw new Error "non abstract method #{name} must have an impl"

        applyTo : (klass, name) ->

            applicant = determineApplicant klass, @

            # provide default implementation when available
            impl = @impl
            if @isAbstract and not impl

                impl = ->

                    throw new Error "derived classes must implement #{klass.name}##{name}"

            Object.defineProperty applicant, name,

                enumerable : not @isPublic

                # @isAbstract or not @isFinal
                configurable : not @isFinal 

                value : impl


    Object.defineProperty exports.dynclass, 'property',

        enumerable : true

        get : ->

            new PropertyField()


    Object.defineProperty exports.dynclass, 'method',

        enumerable : true

        get : ->

            new MethodField()

