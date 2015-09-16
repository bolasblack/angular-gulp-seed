gulp = require 'gulp'
gulp_if = require 'gulp-if'
gulp_util = require 'gulp-util'
gulp_jade = require 'gulp-jade'
gulp_sass = require 'gulp-sass'
gulp_order = require 'gulp-order'
gulp_coffee = require 'gulp-coffee'
gulp_concat = require 'gulp-concat'
gulp_plumber = require 'gulp-plumber'
gulp_replace = require 'gulp-replace'
gulp_webserver = require 'gulp-webserver'
gulp_sourcemaps = require 'gulp-sourcemaps'
gulp_sourceStream = require 'vinyl-source-stream'
mergeStream = require 'merge-stream'
es = require 'event-stream'

sysPath = require 'path'

_ = require 'lodash'
glob = require 'glob'
browserify = require 'browserify'


PATHS = {
  assets:
    src: 'app/assets/**/*'
    dest: 'public/'
  partials:
    src: 'app/partials/**/*.jade'
    dest: 'public/partials/'
  scripts:
    src: 'app/scripts/**/*.coffee'
    dest: 'public/scripts/'
  styles:
    src: 'app/styles/**/*.sass'
    dest: 'public/styles/'
  vendor:
    src: 'app/vendor.coffee'
    dest: 'public/scripts/'
}


gulp.task 'assets', ->
  uneditableExts = 'png jpg gif eot ttf woff svg'.split ' '

  streams = []

  streams.push(gulp.src PATHS.assets.src
    .pipe gulp_plumber()
    .pipe gulp_if '**/*.jade', gulp_jade(pretty: true, locale: timestamp: Date.now())
    .pipe gulp.dest PATHS.assets.dest
  )

  streams.push(gulp.src 'node_modules/bootstrap-sass/assets/fonts/bootstrap/**/*'
    .pipe gulp_plumber()
    .pipe gulp.dest PATHS.assets.dest + 'fonts/'
  )

  mergeStream streams...

gulp.task 'partials', ->
  gulp.src PATHS.partials.src
    .pipe gulp_plumber()
    .pipe gulp_jade(pretty: true)
    .pipe gulp.dest PATHS.partials.dest

gulp.task 'scripts', ['assets'], ->
  stream = gulp.src PATHS.scripts.src
    .pipe gulp_plumber()
    .pipe gulp_order(['**/*.js', '**/index.coffee'])
    .pipe gulp_coffee()
    .pipe gulp_concat('app_tmp.js')
    .pipe es.map (data, callback) ->
      callback null, data.contents.toString()
  browserify(stream).bundle()
    .pipe gulp_sourceStream('app.js')
    .pipe gulp.dest PATHS.scripts.dest

gulp.task 'styles', ['assets'], ->
  gulp.src PATHS.styles.src
    .pipe gulp_plumber()
    .pipe gulp_sourcemaps.init()
    .pipe gulp_sass(indentedSyntax: true)
    .pipe gulp_sourcemaps.write('./maps')
    .pipe gulp.dest PATHS.styles.dest

gulp.task 'vendor', ->
  stream = gulp.src PATHS.vendor.src
    .pipe gulp_plumber()
    .pipe gulp_coffee()
    .pipe gulp_concat('vendor_tmp.js')
    .pipe es.map (data, callback) ->
      callback null, data.contents.toString()
  browserify(stream).bundle()
    .pipe gulp_sourceStream('vendor.js')
    .pipe gulp.dest PATHS.vendor.dest

gulp.task 'server', ->
  gulp.src('./public').pipe(gulp_webserver(
    port: 9000
    livereload:
      enable: true
  ))

  _.forEach PATHS, (paths, type) ->
    gulp.watch paths.src, [type]
    return

  return

gulp.task 'build', ['assets', 'partials', 'scripts', 'styles', 'vendor']

gulp.task 'default', ['build', 'server']
