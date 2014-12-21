# TODO:FILEHEADER

semver = require('semver').parse
path = require 'path'

require('coffee-script').register()


# we do not want the below grunt tasks to show up
# in our task list

lateBoundNpmTasks = [
    'grunt-coffee-coverage'
    'grunt-vows'
    'grunt-changelog'
    'grunt-contrib-copy'
    'grunt-contrib-uglify'
    'grunt-contrib-coffee'
]

latebound = false

latebind = (grunt) ->

    if not latebound

        for task in lateBoundNpmTasks

            grunt.loadNpmTasks task

        grunt.registerTask 'assemble-npm', 'assembles the npm package (./build/npm)', ->

            # write out package.json
            pkg = grunt.file.readJSON 'package.json'
            target = './build/npm/' + pkg.name + '/'

            grunt.file.mkdir target

            # we no longer have any dependencies except for node
            delete pkg.devDependencies
            delete pkg.dependencies
            delete pkg.scripts

            # the layout of the resulting package will be shallow
            pkg.main = './dynclass.js'

            grunt.file.write target + 'package.json', JSON.stringify pkg, null, '    '

            # copy uglified scripts
            for path in grunt.file.expand { cwd : './build/javascript/src' }, '*.js'

                grunt.file.copy './build/javascript/src/' + path, target + path

            # copy documentation
            for path in ['README.md', 'LICENSE', 'CHANGELOG']

                grunt.file.copy './' + path, target + path

        grunt.registerTask 'assemble-meteor', 'assembles the meteor package (./build/meteor)', ->

            pkg = grunt.config.get 'pkg'
            config = grunt.config.get 'meteor'

            packageName = "#{pkg.name.split('-')[0]}:#{pkg.name.substr(pkg.name.indexOf('-')+1)}"
            target = "./build/meteor/#{packageName}/"

            grunt.file.mkdir target

            # write out package.js
            content = "Package.describe({\n"
            content += "    name    : '#{packageName}',\n"
            content += "    version : '#{pkg.version}',\n"
            content += "    summary : '#{pkg.description}',\n"
            content += "    git     : '#{pkg.repository.url}'\n"
            content += "});\n\n"

            content += "Package.onUse(function (api) {\n"
            content += "    api.versionsFrom('#{config.dependencies.meteor}');\n"

            for file in config.files.common

                content += "    api.addFiles('#{file}');\n"

                grunt.file.copy config.srcdir + '/' + file, target + '/' + file

            content += "});\n"

            grunt.file.write target + 'package.js', content

            # copy documentation
            for path in ['README.md', 'LICENSE', 'CHANGELOG']

                grunt.file.copy './' + path, target + path

        grunt.registerTask 'prepare-coverage', 'prepares the coverage build (./build/coverage)', ->

            # prepare coverage src folder
            grunt.file.mkdir './build/coverage/src'

            # copy tests 
            grunt.file.recurse './test', (abspath, rootdir, subdir, filename) ->

                grunt.file.copy path.join(rootdir, filename), path.join('./build/coverage/test', filename)

        latebound = true


determinePreviousTag = (grunt, tag, callback) ->

    grunt.util.spawn { cmd : 'git', args : ['tag'] }, (error, result) ->

        if error

            grunt.fail.fatal(error)

        tags = result.toString().split('\n')

        index = tags.indexOf(tag)

        previousTag = null
        if index > 0

            previousTag = tags[index - 1]

        callback previousTag


changelogBuildPartial = (collectionName, entryName, title) ->

    return "{{#if #{collectionName}}}#{title}:\n\n{{#each #{collectionName}}}{{> #{entryName}}}{{/each}}\n{{/if}}"


changelogEntryPartial = ' - {{this}}\n'


module.exports = (grunt) ->

    grunt.initConfig

        pkg: grunt.file.readJSON 'package.json'

        clean :

            all : ['./build']
            javascript : ['./build/javascript']
            coverage : ['./build/coverage']
            npm : ['./build/npm']
            meteor : ['./build/meteor']

        vows :

            all :

                options :

                    # String {spec|json|dot-matrix|xunit|tap}
                    reporter: 'spec'
                    verbose: false
                    silent: false
                    colors: true 
                    isolate: false
                    coverage: 'json'

                src: ['./test/*.coffee']

            all_coverage :

                options :

                    # String {spec|json|dot-matrix|xunit|tap}
                    reporter: 'spec'
                    verbose: false
                    silent: false
                    colors: true 
                    isolate: false
                    coverage: 'html'

                src: ['./build/coverage/test/*.coffee']

        coffee :

            default :

                expand: true
                flatten : false
                src : ['./src/**/*.coffee', './test/**/*.coffee']
                dest : './build/javascript'
                ext : '.js'

            bare :

                options :

                    bare : true

                expand: true
                flatten : false
                src : ['./src/**/*.coffee', './test/**/*.coffee']
                dest : './build/javascript'
                ext : '.js'

        coffeeCoverage :

            options :

                path : 'relative'

            all :

                src : 'src/'

                dest : './build/coverage/src/'

        changelog :

            default :

                options :

                    others : true

                    dest : 'CHANGELOG'

                    insertType : 'prepend'

                    sections :

                        apichanges : /^\s*- changed (#\d+):?(.*)$/i
                        deprecations : /^\s*- deprecated (#\d+):?(.*)$/i
                        features : /^\s*- feature (#\d+):?(.*)$/i
                        fixes : /^\s*- fixes (#\d+):?(.*)$/i
                        others : /^\s*- (.*)$/

                    template : 'Release v<%= pkg.version %> ({{date}})\n\n{{> features }}{{> fixes }}{{> apichanges }}{{> deprecations }}{{> others }}' 

                    partials :

                        entry : changelogEntryPartial
                        apichanges : changelogBuildPartial 'apichanges', 'entry', 'API Changes'
                        deprecations : changelogBuildPartial 'deprecations', 'entry', 'Deprecated'
                        features : changelogBuildPartial 'features', 'entry', 'New Features'
                        fixes : changelogBuildPartial 'fixes', 'entry', 'Bug Fixes'
                        others : changelogBuildPartial 'others', 'entry', 'Miscellaneous'

        meteor :

            srcdir : './build/javascript/src'

            dependencies :

                meteor : '1.0'

            files :

                common : [
                    'dynclass.js'
                ]

    grunt.registerTask 'package-npm', 'assemble npm package (./build/npm)', ->

        latebind grunt

        grunt.task.run 'clean:javascript'
        grunt.task.run 'clean:npm'
        grunt.task.run 'test'
        grunt.task.run 'build-javascript'
        #grunt.task.run 'build-uglified'
        grunt.task.run 'assemble-npm'

    grunt.registerTask 'package-meteor', 'assemble meteor package (./build/meteor)', ->

        latebind grunt

        grunt.task.run 'clean:javascript'
        grunt.task.run 'clean:meteor'
        grunt.task.run 'test'
        grunt.task.run 'build-javascript:bare'
        #grunt.task.run 'build-uglified'
        grunt.task.run 'assemble-meteor'

    grunt.registerTask 'publish-npm', 'publish npm package', ->

        grunt.task.requires 'package-npm'

        throw new Error 'not implemented yet.'

    grunt.registerTask 'publish-meteor', 'publish npm package', ->

        grunt.task.requires 'package-meteor'

        throw new Error 'not implemented yet.'

    grunt.registerTask 'coverage', 'coverage analysis and reports (./build/coverage)', ->

        latebind grunt

        grunt.task.run 'clean:coverage'
        grunt.task.run 'prepare-coverage'
        grunt.task.run 'coffeeCoverage'
        grunt.task.run 'test:all_coverage'

    grunt.registerTask 'build-javascript', 'builds the javascript, options: default|bare (./build/javascript)', (mode = 'default') ->

        latebind grunt

        grunt.task.run 'coffee:' + mode

    grunt.registerTask 'build-uglified', 'builds the uglified javascript (./build/uglified)', ->

        #grunt.task.requires 'build-javascript'
        #latebind grunt

        throw new Error 'not implemented yet.'

    grunt.registerTask 'test', 'run all tests', (mode = 'all') ->

        latebind grunt

        grunt.task.run 'vows:' + mode

    grunt.registerTask 'bump-version', 'bumps the version number by one, either :major, :minor or :patch', (mode = 'patch') ->

        if not (mode in ['major', 'minor', 'patch'])

            throw new Error 'mode must be one of major, minor or patch which is the default'

        pkg = grunt.config.get 'pkg'
        version = semver pkg.version
        version.inc mode
        grunt.file.write 'package.json.old', JSON.stringify pkg, null, '    '
        pkg.version = version.toString()
        grunt.file.write 'package.json', JSON.stringify pkg, null, '    '
        grunt.log.write "bumped version to #{version}"

    grunt.registerTask 'default', [
        'clean', 'build-javascript', 'coverage', 'test', 
        #'build-uglified',
        'package-npm', 'package-meteor'
    ]

    grunt.registerTask 'update-changelog', (after, before) ->

        latebind grunt

        changelogTask = 'changelog:default'

        if after

            grunt.task.run "#{changelogTask}:#{after}:#{before}"

        else

            done = this.async()

            pkg = grunt.config.get 'pkg'
            tag = "v#{pkg.version}"
            determinePreviousTag grunt, tag, (previousTag) ->

                if previousTag is null

                    changelogTask += ":commit:#{tag}"

                else

                    changelogTask += ":#{previousTag}:#{tag}"

                grunt.task.run changelogTask

                done()

    grunt.loadNpmTasks 'grunt-contrib-clean'

