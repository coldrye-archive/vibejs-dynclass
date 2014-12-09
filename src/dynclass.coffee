#PI Documentation|API Documentation]]
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


# TODO:cleanup
# TODO:document


# we export most of this to the global namespace
exports = window ? global


# guard preventing us from exporting twice
unless exports.dynclass?


    # dummy class used for making coffee compile in 
    # the latest version of __extends
    class _JustForTheExtends extends Object


    __hasOwnProperty = {}.hasOwnProperty


    # Helper function used by ClassFactory to be able to
    # chain modifiers with optional parameters
    _extendFunction = (func, extensions) ->

        for name in Object.keys extensions

            if name in ['name', '__super__', '_super', '__dynclass_flags__']

                continue

            defineProperty = (name) ->

                Object.defineProperty func, name,

                    enumerable : true

                    get : ->

                        extensions[name]

            defineProperty name

        func

    # Custom extend function so we do not have to
    # depend on underscore
    _extend = (klass, base, extensions) ->

        for name, field of extensions

            if not (field instanceof AbstractField)

                if field.__dynclass_flags__ is undefined

                    throw new Error "field #{name} is not of the expected type, use either dynclass.method or dynclass.property or pass in a dynclass as its value"

                else

                    innerClass = field

# TODO:implement

                    field = new InnerClassField innerClass

            field.name = name

            if dynclass.logger
                dynclass.logger.debug "dynclass:validating field #{field} with flags #{field.flags}"

            field.validate base

            if dynclass.logger
                dynclass.logger.debug "dynclass:declaring field #{field}"

            field.applyTo klass, base

        undefined


    _extenderPartial = (klass, base) ->

        (extensions) ->

            _extend klass, base, extensions


    # no op function used as the default ctor mixin
    noopfun = ->


    # counter used for creating unique anonymous class names
    # in case that the user fails to provide a custom name
    anonClassCount = 0


    # The function dynclass models a factory for dynamically creating
    # new classes.
    #
    # @param Object options declaration options
    # @option options Object base base class
    # @option options String name name of the dynamically created class
    # @option options Boolean chainSuper chain call to super on instantiation, default: true
    # @option options Function constructor mixin to be applied on instantiation
    # @option options Object|Function extend instance methods and properties or callback
    exports.dynclass = (options = {}) ->

        result = null

        name = options.name
        if not name

            name = "AnonClass_#{anonClassCount}"
            anonClassCount++

        logger = dynclass.logger

        if logger
            logger.debug "dynclass:creating class #{name} with flags #{options.__dynclass_flags__ || 0}"

        ctorMixin = options.ctor || noopfun

        if ctorMixin != noopfun

            if logger
                logger.debug 'dynclass:using custom ctor mixin'

        chainSuper = if options.chainSuper is false then false else true

        base = options.base

        if base and chainSuper is true

            if logger
                logger.debug 'dynclass:chaining super on instantiation'

            eval "result = function #{name}() {" +
                 "    #{name}.__super__.constructor.apply(" +
                 "        this, arguments" +
                 "    );" +
                 "    ctorMixin.apply(this, arguments);" +
                 "};"

        else

            if logger
                logger.debug 'dynclass:not chaining super on instantiation'

            eval "result = function #{name}() {" +
                 "    ctorMixin.apply(this, arguments);" +
                 "}"

        if base

            if logger
                logger.debug 'dynclass:inheriting from specified base class #{base.name}'

            eval("__extends(result, base)")

        # set __dynclass_flags__ so that both the helper functions such as isAbstract
        # and the extender may recognize this for being a class 
        flags = options.__dynclass_flags__ ? 0
        Object.defineProperty result, '__dynclass_flags__',

            enumerable : false

            configurable : false

            writable : false

            value : flags

        extender = _extenderPartial result, base

        if options.extend

            if typeof options.extend is 'function'

                if logger
                    logger.debug 'dynclass:calling user defined extend callback'

                options.extend result, extender, logger 

            else

                extender options.extend

        if flags & AbstractFlagged.MODIFIER_FINAL

            if logger
                logger.debug 'dynclass:sealing and freezing final class'

            Object.seal result
            Object.seal result.prototype
            Object.freeze result
            Object.freeze result.prototype

        result


    determineApplicant = (klass, field) ->

        if field.isStatic then klass else klass.prototype


    class AbstractFlagged

        @MODIFIER_ABSTRACT = 1
        @MODIFIER_FINAL = 2
        @MODIFIER_PRIVATE = 4
        @MODIFIER_STATIC = 8

        @FIELD_PROPERTY = 128
        @FIELD_METHOD = 256

        constructor : (@flags) ->

            Object.defineProperty @, 'isStatic',

                enumerable : true

                get : ->

                    @isset AbstractFlagged.MODIFIER_STATIC

            Object.defineProperty @, 'isAbstract',

                enumerable : true

                get : ->

                    @isset AbstractFlagged.MODIFIER_ABSTRACT

            Object.defineProperty @, 'isFinal',

                enumerable : true

                get : ->

                    @isset AbstractFlagged.MODIFIER_FINAL

            Object.defineProperty @, 'isPrivate',

                enumerable : true

                get : ->

                    @isset AbstractFlagged.MODIFIER_PRIVATE

        isset : (flag) ->

            (@flags & flag) != 0

        set: (flag) ->

            @flags |= flag

            @


    class AbstractField extends AbstractFlagged

        constructor : (type) ->

            super type

            @name = null

            Object.defineProperty @, 'abstract',

                enumerable : true

                get : ->

                    if @isPrivate

                        throw new TypeError 'private fields cannot be declared abstract'

                    if @isFinal

                        throw new TypeError 'final fields cannot be declared abstract'

                    @set AbstractFlagged.MODIFIER_ABSTRACT

            Object.defineProperty @, 'final',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new TypeError 'abstract fields cannot be declared final'

                    @set AbstractFlagged.MODIFIER_FINAL

            Object.defineProperty @, 'private',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new TypeError 'abstract fields cannot be declared private'

                    @set AbstractFlagged.MODIFIER_PRIVATE

            Object.defineProperty @, 'static',

                enumerable : true

                get : ->

                    @set AbstractFlagged.MODIFIER_STATIC

        validate : (base) ->

            if base

                baseApplicant = determineApplicant base, @

                if __hasOwnProperty.call baseApplicant, @name

                    descriptor = Object.getOwnPropertyDescriptor baseApplicant, @name

                    if not descriptor.configurable and descriptor.enumerable

                        throw new TypeError "public final field #{base.name}##{@name} cannot be overridden"

        applyTo : (klass, base) ->

            throw new Error 'derived classes must implement this.'

        toString : ->

            components = []
            components.push 'private' if @isPrivate
            components.push 'abstract' if @isAbstract
            components.push 'final' if @isFinal
            components.push 'readonly' if @isReadonly
            components.push 'property' if @isset AbstractFlagged.FIELD_PROPERTY
            components.push 'method' if @isset AbstractFlagged.FIELD_METHOD
            components.push @name

            "[Field #{components.join ' '}]"


    class PropertyField extends AbstractField

        constructor : ->

            super AbstractFlagged.FIELD_PROPERTY

            @_getter = null
            @_setter = null
            @_readonly = false
            @_defaultValue = null

            Object.defineProperty @, 'defaultValue',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new TypeError 'abstract properties cannot have a default value'

                    (defaultValue) =>

                        @_defaultValue = defaultValue

                        @

            Object.defineProperty @, 'readonly',

                enumerable : true

                get : ->

                    if @_setter

                        throw new TypeError 'readonly properties cannot have a setter'

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

                        throw new TypeError 'readonly properties cannot have a setter'

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

                throw new TypeError "getter for #{@name} is not a function"

            if @_setter and typeof @_setter != 'function'

                throw new TypeError "setter for #{@name} is not a function"

        applyTo : (klass, base) ->

            applicant = determineApplicant klass, @

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

                        throw new TypeError "abstract property #{klass.name}##{name} must be implemented"

                else

                    @_getter = ->

                        @[internalPropertyName]

            impl = @_getter
            getter = =>

                impl.apply @, arguments

            getter.__dynclass_flags__ = @flags

            descriptor['get'] = getter

            if not @isReadonly

                if @_setter is null

                    if @isAbstract

                        @_setter = ->

                            throw new TypeError "abstract property #{klass.name}##{name} must be implemented"

                    else

                        @_setter = (value) ->

                            @[internalPropertyName] = value

                            undefined
            else

                # make sure that readonly properties cannot be set
                @_setter = ->

                    throw new Error "property #{klass.name}##{name} is readonly"

            impl = @_setter
            setter = =>

                impl.apply @, arguments

            descriptor['set'] = setter

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

            super AbstractFlagged.FIELD_METHOD

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

                throw new TypeError 'impl for method #{@name} is not a function'

            if not @_impl and (@isFinal or not @isAbstract)

                throw new TypeError "non abstract method #{@name} must have an impl"

        applyTo : (klass, base) ->

            applicant = determineApplicant klass, @

            name = @name

            if @isAbstract and not @_impl

                @_impl = ->

                    throw new TypeError "derived classes must implement #{klass.name}.#{name}"

            impl = @_impl
            getter = =>

               impl.apply this, arguments
 
            getter.__dynclass_flags__ = @flags

            Object.defineProperty applicant, @name,

                enumerable : not @isPrivate

                configurable : not @isFinal 

                get : getter


    class ClassFactory extends AbstractFlagged

        constructor : ->

            super()

            Object.defineProperty @, 'abstract',

                enumerable : true

                get : ->

                    if @isFinal

                        throw new TypeError 'final classes cannot be declared abstract'

                    @set AbstractFlagged.MODIFIER_ABSTRACT

                    result = (options = {}) =>

                        options.__dynclass_flags__ = @flags

                        dynclass options

                    _extendFunction result, @

            Object.defineProperty @, 'final',

                enumerable : true

                get : ->

                    if @isAbstract

                        throw new TypeError 'abstract classes cannot be declared final'

                    @set AbstractFlagged.MODIFIER_FINAL

                    result = (options = {}) =>

                        options.__dynclass_flags__ = @flags

                        dynclass options

                    _extendFunction result, @

            Object.defineProperty @, 'private',

                enumerable : true

                get : ->

                    @set AbstractFlagged.MODIFIER_PRIVATE

                    result = (options = {}) =>

                        options.__dynclass_flags__ = @flags

                        dynclass options

                    _extendFunction result, @

            Object.defineProperty @, 'static',

                enumerable : true

                get : ->

                    @set AbstractFlagged.MODIFIER_STATIC

                    if dynclass.logger
                        dynclass.logger.debug "dynclass:ClassFactory:static:flags: #{@flags}"

                    result = (options = {}) =>

                        options.__dynclass_flags__ = @flags

                        dynclass options

                    _extendFunction result, @


    Object.defineProperty exports.dynclass, 'property',

        enumerable : true

        get : ->

            new PropertyField()


    Object.defineProperty exports.dynclass, 'method',

        enumerable : true

        get : ->

            new MethodField()


    Object.defineProperty exports.dynclass, 'abstract',

        enumerable : true

        get : ->

            (new ClassFactory()).abstract


    Object.defineProperty exports.dynclass, 'private',

        enumerable : true

        get : ->

            (new ClassFactory()).private


    Object.defineProperty exports.dynclass, 'final',

        enumerable : true

        get : ->

            (new ClassFactory()).final


    Object.defineProperty exports.dynclass, 'static',

        enumerable : true

        get : ->

            (new ClassFactory()).static


    testFlag = (flag, testee) ->

        # TODO:remove
        if dynclass.logger
            dynclass.logger.debug "dynclass:testFlag:flag = #{flag}, testee = #{testee}, testee flags = #{testee.__dynclass_flags__}"

        ((testee.__dynclass_flags__ ? 0) & flag) != 0


    resolveTestee = (klass, fieldName) ->

        result = klass

        if fieldName

            descriptor = getFieldDescriptor klass, fieldName

            result = descriptor.get

        result


    getFieldDescriptor = (klass, fieldName) ->

        result = null

        if dynclass.isStatic klass, fieldName

            result = Object.getOwnPropertyDescriptor klass, fieldName

        else

            result = Object.getOwnPropertyDescriptor klass.prototype, fieldName

        result


    Object.defineProperty exports.dynclass, 'isStatic',

        enumerable : true

        value : (klass, fieldName) ->

            result = false

            if not klass

                throw new TypeError 'klass is undefined'

            if fieldName

                result = klass.hasOwnProperty fieldName

            else

                result = testFlag AbstractFlagged.MODIFIER_STATIC, klass

            result


    Object.defineProperty exports.dynclass, 'isFinal',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            testFlag AbstractFlagged.MODIFIER_FINAL, resolveTestee klass, fieldName


    Object.defineProperty exports.dynclass, 'isPrivate',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            testFlag AbstractFlagged.MODIFIER_PRIVATE, resolveTestee klass, fieldName


    Object.defineProperty exports.dynclass, 'isAbstract',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            testFlag AbstractFlagged.MODIFIER_ABSTRACT, resolveTestee klass, fieldName


    Object.defineProperty exports.dynclass, 'isMethod',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            if not fieldName

                throw new TypeError 'fieldName is undefined'

            testFlag AbstractFlagged.FIELD_METHOD, resolveTestee klass, fieldName


    Object.defineProperty exports.dynclass, 'isProperty',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            if not fieldName

                throw new TypeError 'fieldName is undefined'

            testFlag AbstractFlagged.FIELD_PROPERTY, resolveTestee klass, fieldName


    Object.defineProperty exports.dynclass, 'isReadonly',

        enumerable : true

        value : (klass, fieldName) ->

            if not klass

                throw new TypeError 'klass is undefined'

            if not fieldName

                throw new TypeError 'fieldName is undefined'

            testFlag AbstractFlagged.MODIFIER_READONLY, resolveTestee klass, fieldName


    # TODO:API change, logger now set on dynclass instead of being an
    # option to dynclass on call
    Object.defineProperty exports.dynclass, '_logger',

        enumerable : false

        configurable : false

        writable : true

        value : null


    Object.defineProperty exports.dynclass, 'logger',

        enumerable : true

        configurable : false

        get : ->

            dynclass._logger

        set : (logger) ->

            if logger and typeof logger.debug isnt 'function'

                throw new TypeError 'The specified logger must have a debug method.'

            dynclass._logger = logger

