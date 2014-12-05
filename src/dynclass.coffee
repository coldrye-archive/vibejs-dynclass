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
    _extend = (klass, base, extensions, debug) ->

        for name, field of extensions

            field.name = name

            debug "dynclass:adding field #{field}"

            field.validate base

            field.applyTo klass, base, debug

        undefined


    _extenderPartial = (klass, base, debug) ->

        (extensions) ->

            _extend klass, base, extensions, debug


    # no op function used as the default ctor mixin
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

        extender = _extenderPartial result, base, debug

        if options.extend

            debug 'dynclass:defining fields'

            if typeof options.extend is 'function'

                debug 'dynclass:calling user defined callback'

                options.static result, extender, logger 

            else

                extender options.extend

        if options.seal

            debug 'dynclass:sealing created class'

            Object.seal result
            Object.seal result.prototype

        if options.freeze

            debug 'dynclass:freezing created class'

            Object.freeze result
            Object.freeze result.prototype

        result


    determineApplicant = (klass, field) ->

        if field.isStatic then klass else klass.prototype


    class AbstractField

        @MODIFIER_ABSTRACT = 1
        @MODIFIER_FINAL = 2
        @MODIFIER_PRIVATE = 4
        @MODIFIER_STATIC = 8

        @FIELD_PROPERTY = 128
        @FIELD_METHOD = 256

        constructor : (type) ->

            @name = null
            @flags = 0
            @set type

            Object.defineProperty @, 'abstract',

                enumerable : true

                get : ->

                    if @isPrivate

                        throw new Error 'private fields cannot be declared abstract'

                    if @isFinal

                        throw new Error 'final fields cannot be declared abstract'

                    @set AbstractField.MODIFIER_ABSTRACT

            Object.defineProperty @, 'final',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new Error 'abstract fields cannot be declared final'

                    @set AbstractField.MODIFIER_FINAL

            Object.defineProperty @, 'private',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new Error 'abstract fields cannot be declared private'

                    @set AbstractField.MODIFIER_PRIVATE

            Object.defineProperty @, 'static',

                enumerable : true

                get : ->

                    @set AbstractField.MODIFIER_STATIC

            Object.defineProperty @, 'isStatic',

                enumerable : true

                get : ->

                    @isset AbstractField.MODIFIER_STATIC

            Object.defineProperty @, 'isAbstract',

                enumerable : true

                get : ->

                    @isset AbstractField.MODIFIER_ABSTRACT

            Object.defineProperty @, 'isFinal',

                enumerable : true

                get : ->

                    @isset AbstractField.MODIFIER_FINAL

            Object.defineProperty @, 'isPrivate',

                enumerable : true

                get : ->

                    @isset AbstractField.MODIFIER_PRIVATE

        isset : (flag) ->

            (@flags & flag) != 0

        set: (flag) ->

            @flags |= flag

            @

        validate : (base) ->

            if base

                baseApplicant = determineApplicant base, @

                if __hasOwnProperty.call baseApplicant, @name

                    descriptor = Object.getOwnPropertyDescriptor baseApplicant, @name

                    if not descriptor.configurable and descriptor.enumerable

                        throw new Error "public final field #{base.name}##{@name} cannot be overridden"

        applyTo : (klass, base, debug) ->

            throw new Error 'derived classes must implement this.'

        toString : ->

            components = []
            components.push 'private' if @isPrivate
            components.push 'abstract' if @isAbstract
            components.push 'final' if @isFinal
            components.push 'readonly' if @isReadonly
            components.push 'property' if @isset AbstractField.FIELD_PROPERTY
            components.push 'method' if @isset AbstractField.FIELD_METHOD
            components.push @name

            "[Field #{components.join ' '}]"


    class PropertyField extends AbstractField

        constructor : ->

            super AbstractField.FIELD_PROPERTY

            @_getter = null
            @_setter = null
            @_readonly = false
            @_defaultValue = null

            Object.defineProperty @, 'defaultValue',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new Error 'abstract properties cannot have a default value'

                    (defaultValue) =>

                        @_defaultValue = defaultValue

                        @

            Object.defineProperty @, 'readonly',

                enumerable : true

                get : ->

                    if @_setter

                        throw new Error 'readonly properties cannot have a setter'
                    @_readonly = true

                    @

            Object.defineProperty @, 'getter',

                enumerable : true

                get : ->

                    (getter) =>

                        @_getter = getter

                        @

            Object.defineProperty @, 'setter',

                enumerable : true

                get : ->

                    if @isReadonly

                        throw new Error 'readonly properties cannot have a setter'

                    (setter) =>

                        @_setter = setter

                        @

            Object.defineProperty @, 'isReadonly',

                enumerable : true

                get : ->

                    @_readonly

        validate : (base) ->

            super base

            if @name is null

                throw new Error 'name was not set'

            if @_getter and typeof @_getter != 'function'

                throw new Error "getter for #{@name} is not a function"

            if @_setter and typeof @_setter != 'function'

                throw new Error "setter for #{@name} is not a function"

        applyTo : (klass, base, debug) ->

            applicant = determineApplicant klass, @

            # TODO:cleanup

            name = @name

            descriptor =

                enumerable : not @isPrivate

                configurable : not @isFinal

            hasUserDefinedGetter = true
            internalPropertyName = "_#{name}"

            if @_getter is null

                hasUserDefinedGetter = false

                if @isAbstract

                    @_getter = ->

                        throw new Error "abstract property #{klass.name}##{name} must be implemented"

                else

                    @_getter = ->

                        @[internalPropertyName]

            descriptor['get'] = @_getter

            if not @isReadonly

                if @_setter is null

                    if @isAbstract

                        @_setter = ->

                            throw new Error "abstract property #{klass.name}##{name} must be implemented"

                    else

                        @_setter = (value) ->

                            @[internalPropertyName] = value

                            undefined
            else

                # make sure that readonly properties cannot be set
                @_setter = ->

                    throw new Error "property #{klass.name}##{name} is readonly"

            descriptor['set'] = @_setter

            Object.defineProperty applicant, name, descriptor

            # define internal property
            if not hasUserDefinedGetter

                Object.defineProperty applicant, internalPropertyName,

                    enumerable : false

                    writable : true

                    configurable : false

                    value : @_defaultValue


    class MethodField extends AbstractField

        constructor : ->

            super AbstractField.FIELD_METHOD

            @_impl = null

            Object.defineProperty @, 'impl',

                enumerable : true

                get : ->

                    (impl) =>

                        @_impl = impl

                        @

        validate : (base) ->

            super base

            if @name is null

                throw new Error 'name was not set'

            if @_impl and typeof @_impl != 'function'

                throw new Error 'impl for method #{@name} is not a function'

            if not @_impl and (@isFinal or not @isAbstract)

                throw new Error "non abstract method #{@name} must have an impl"

        applyTo : (klass, base, debug) ->

            applicant = determineApplicant klass, @

            name = @name

            impl = @_impl

            if @isAbstract and not impl

                impl = ->

                    throw new Error "derived classes must implement #{klass.name}.#{name}"

            Object.defineProperty applicant, @name,

                enumerable : not @isPrivate

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

