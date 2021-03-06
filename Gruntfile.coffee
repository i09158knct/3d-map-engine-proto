path = require 'path'

module.exports = (grunt) ->
  grunt.initConfig
    watch:
      livereload:
        files: [
          '**/*'
          '!data/**/*'
          '!index.html'
        ]
        tasks: [
          # 'exec:build_index_page'
        ]
        options:
          cwd: 'public'
          livereload: true


    connect:
      server:
        options:
          port: 8000
          base: 'public'
          livereload: true


    exec:
      harp_base_command: 'node_modules/.bin/harp server public'
      harp: command: '<%= exec.harp_base_command %>'
      harp_background: command: '<%= exec.harp_base_command %> &'
      compile: command: 'node_modules/.bin/harp compile public www'
      build_index_page:
        command: 'node_modules/.bin/coffee scripts/build-index-page.coffee public > public/index.html'


    components:
      'public/js/vendor': [
        'bower_components/jquery/jquery.js'
        'bower_components/knockout.js/knockout.debug.js'
        'bower_components/threejs/build/three.js'

        'bower_components/underscore/underscore.js'
        'bower_components/underscore.string/lib/underscore.string.js'
        'bower_components/moment/moment.js'
        'bower_components/q/q.js'

        'bower_components/proj4/dist/proj4-src.js'
        'bower_components/d3/d3.js'
      ]
      'public/css/vendor': [
      ]
      'public/img': [
      ]



  grunt.loadNpmTasks task for task in [
    'grunt-exec'
    'grunt-contrib-watch'
    'grunt-contrib-connect'
  ]



  grunt.registerTask 'copy-components', ->
    for pathName, sources of grunt.config.get('components')
      grunt.file.mkdir pathName
      for source in sources
        fileName = path.basename source
        grunt.log.writeln "copying #{fileName}"
        grunt.file.copy source, "#{pathName}/#{fileName}"



  grunt.registerTask name, targets for name, targets of {
    'initialize': [
      'copy-components'
      'exec:build_index_page'
    ]
    'build': [
      'initialize'
      'exec:compile'
    ]
    'server': ['exec:harp']
    'default': [
      'exec:harp_background'
      'watch'
    ]
  }
