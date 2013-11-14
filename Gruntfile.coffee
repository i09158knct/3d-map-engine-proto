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
          'exec:build_index_page'
        ]
        options:
          cwd: 'public'
          livereload: true


    exec:
      server_base_command: 'python -m SimpleHTTPServer'
      server: command: '<%= exec.server_base_command %>'
      server_background: command: '<%= exec.server_base_command %> &'

      build_index_page:
        command: 'coffee scripts/build-index-page.coffee public > public/index.html'



  grunt.loadNpmTasks task for task in [
    'grunt-exec'
    'grunt-contrib-watch'
  ]



  grunt.registerTask 'copy-components', ->
    (
      grunt.file.mkdir pathName
      for source in sources
        fileName = path.basename source
        grunt.log.writeln "copying #{fileName}"
        grunt.file.copy source, "#{pathName}/#{fileName}"
    ) for pathName, sources of {
      'public/js/vendor': [
        'bower_components/backbone/backbone.js'
        'bower_components/underscore/underscore.js'
        'bower_components/underscore.string/lib/underscore.string.js'
        'bower_components/jquery/jquery.js'
        'bower_components/d3/d3.js'
        'bower_components/three/build/three.js'
        'bower_components/angular/angular.js'
        'bower_components/coffee-script/extras/coffee-script.js'
      ]
      'public/css/vendor': [
      ]
      'public/img': [
      ]
    }



  grunt.registerTask name, targets for name, targets of {
    'initialize': [
      'copy-components'
      'exec:build_index_page'
    ]
    'build': [
      'initialize'
    ]
    'server': ['exec:server']
    'default': [
      'exec:server_background'
      'watch'
    ]
  }
