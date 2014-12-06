# vibejs-dynclass

[![Build Status](https://travis-ci.org/vibejs/vibejs-dynclass.svg?branch=master)](https://travis-ci.org/vibejs/vibejs-dynclass)

## Introduction

*dynclass* is a factory for creating classes dynamically in your Javascript/Coffee-Script applications.


### Motivation

*vibejs-enum* required a way of dynamically creating new enum classes that needed to be named accordingly.
Here, either the user provided a custom name or the system determined a unique name such as AnonEnum_<N>.
Since none of these names could be applied using standard Javascript/Coffee-Script, dynclass was born.
dynclass uses eval in combination with some boilerplate code to make this work with Coffee-Script.


### Features

 - declarative API
 - named classes
 - *FUTURE* class modifiers: abstract, private and final
 - field modifiers: abstract, private, final, readonly and static
 - field types: method, property and *FUTURE* inner class


## LICENSE


   Copyright 2014 Carsten Klein

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
   

## Installation

You can install dynclass in multiple different ways.


### Node NPM

    npm [-g] install vibejs-dynclass


### Meteor

    meteor add vibejs:dynclass


## Usage

TODO

### Node - Javascript

```javascript
require('vibejs-dynclass');

var Tool = dynclass({

    name : 'Tool',

    constructor : function () {
        // ...
    },

    extend : {

        version : dynclass.property.readonly.static.final.defaultValue('1.0.0'),

        onAbout : dynclass.method.impl(function () {
           window.alert('About ' + Tool.name + ' ' + Tool.version);
        }),

       main : dynclass.method.static.impl(function () {
           var tool = new Tool();
           tool.onAbout();
       })
    }
});

Tool.main();
```

### Node - Coffee-Script

TODO

### Meteor - Javascript (both Client and Server)

TODO

### Meteor - Coffee-Script (both Client and Server)

TODO
