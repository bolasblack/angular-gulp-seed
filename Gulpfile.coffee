gulp = require 'gulp'
gutil = require 'gulp-util'
gulp_jade = require 'gulp-jade'
gulp_order = require 'gulp-order'
gulp_coffee = require 'gulp-coffee'
gulp_concat = require 'gulp-concat'
gulp_filter = require 'gulp-filter'
gulp_replace = require 'gulp-replace'
gulp_livereload = require 'gulp-livereload'
gulp_rework = require './scripts/gulp-rework'

sysPath = require 'path'

Q = require 'q'
_ = require 'lodash'
glob = require 'glob'
readComponents = require 'read-components'


getVendorFiles = ->
  Q.all([
    Q.denodeify(readComponents)('.', 'bower')
    Q.denodeify(glob)('vendor/**/*')
  ]).then ([packages, vendorFiles]) ->
    _(packages)
      .tap (packages) ->
        packages.sort (a, b) ->
          b.sortingLevel - a.sortingLevel
      .map (packages) ->
        packages.files
      .flatten()
      .tap (filelist) ->
        vendorFiles.forEach (filepath) ->
          filelist.push filepath
      .groupBy (filepath) ->
        switch sysPath.extname filepath
          when '.js', '.coffee' then 'scripts'
          when '.css' then 'styles'
      .value()


PATHS = {
  assets:
    src: 'app/assets/**/*'
    dest: 'public/'
  partials:
    src: 'app/partials/**/*.jade'
    dest: 'public/partials/'
  scripts:
    src: 'app/**/*.coffee'
    dest: 'public/scripts/'
  styles:
    src: 'app/**/*.styl'
    dest: 'public/styles/'
}


gulp.task 'assets', ->
  editableFileFilter = gulp_filter (file) ->
    uneditableExts = 'png jpg gif eot ttf woff svg'.split(' ')
    sysPath.extname(file.path).replace(/^\./, '') not in uneditableExts

  jadeFilter = gulp_filter (file) ->
    sysPath.extname(file.path) is '.jade'

  gulp.src(PATHS.assets.src)
    .pipe editableFileFilter
    .pipe gulp_replace /{%timestamp%}/g, Date.now()
    .pipe editableFileFilter.restore()

    .pipe jadeFilter
    .pipe gulp_jade(pretty: true).on 'error', gutil.log
    .pipe jadeFilter.restore()

    .pipe gulp.dest PATHS.assets.dest

gulp.task 'partials', ->
  gulp.src(PATHS.partials.src)
    .pipe gulp_jade(pretty: true).on 'error', gutil.log
    .pipe gulp.dest PATHS.partials.dest

gulp.task 'scripts', ['assets'], ->
  jsFilter = gulp_filter (file) ->
    sysPath.extname(file.path) is '.js'

  glob PATHS.scripts.src, (err, filelist) ->
    throw err if err

    {true: indexfiles, false: otherfiles} = _.groupBy filelist, (filepath) ->
      sysPath.basename(filepath, '.coffee') in ['index', 'app']

    gulp.src (indexfiles or []).concat otherfiles or []
      .pipe gulp_coffee().on 'error', gutil.log
      .pipe(gulp_order [
        '**/index.js'
        '**/*.js'
      ])
      .pipe gulp_concat 'app.js'
      .pipe gulp.dest PATHS.scripts.dest

gulp.task 'styles', ['assets'], ->
  gulp.src(PATHS.styles.src)
    .pipe gulp_rework().on 'error', gutil.log
    .pipe gulp_concat 'app.css'
    .pipe gulp.dest PATHS.styles.dest

gulp.task 'vendor', ->
  coffeeFilter = gulp_filter (file) ->
    sysPath.extname(file.path) is '.coffee'

  jsFilter = gulp_filter (file) ->
    sysPath.extname(file.path) is '.js'

  getVendorFiles().then (vendorFiles) ->
    unless _(vendorFiles.scripts).isEmpty()
      gulp.src vendorFiles.scripts

        .pipe coffeeFilter
        .pipe gulp_coffee().on 'error', gutil.log
        .pipe coffeeFilter.restore()

        .pipe gulp_concat 'vendor.js'
        .pipe gulp.dest PATHS.scripts.dest

    unless _(vendorFiles.styles).isEmpty()
      gulp.src vendorFiles.styles
        .pipe gulp_concat 'vendor.css'
        .pipe gulp.dest PATHS.styles.dest

    vendorFiles

gulp.task 'watch', ->
  livereloadServer = gulp_livereload()

  livereload = (watcher) ->
    watcher.on 'change', triggerLivereload

  triggerLivereload = _.debounce (file) ->
    livereloadServer.changed file.path
  , 500

  livereload gulp.watch PATHS.assets.src, ['assets']
  livereload gulp.watch PATHS.partials.src, ['partials']
  livereload gulp.watch PATHS.scripts.src, ['scripts']
  livereload gulp.watch PATHS.styles.src, ['styles']
  livereload gulp.watch 'bower.json', ['vendor']
  return

gulp.task 'build', ['assets', 'partials', 'scripts', 'styles', 'vendor']

gulp.task 'default', ['build', 'watch']

