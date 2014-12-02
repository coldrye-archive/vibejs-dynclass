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

 - classes can be declared dynamically


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

    require('vibejs-dynclass');

    var DynClass = dynclass({

        name : 'DynClass',

        static : {
            staticMethod : function () {
                console.log('called DynClass#staticMethod');
            }
        },

        instance : {
            method : function () {
                console.log('called DynClass#method');
            }
        },

    });

    DynClass.staticMethod();
    var instance = new DynClass();
    instance.method();


### Node - Coffee-Script

TODO

### Meteor - Javascript (both Client and Server)

TODO

### Meteor - Coffee-Script (both Client and Server)

TODO
