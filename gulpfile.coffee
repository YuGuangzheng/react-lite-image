
gulp = require('gulp')
sequence = require('run-sequence')
exec = require('child_process').exec
env =
  dev: true
  main: 'http://localhost:8080/build/main.js'
  vendor: 'http://localhost:8080/build/vendor.js'

gulp.task 'script', ->
  coffee = require('gulp-coffee')
  gulp
  .src 'src/**/*.coffee'
  .pipe coffee()
  .pipe gulp.dest('lib/')

gulp.task 'rsync', (cb) ->
  wrapper = require 'rsyncwrapper'
  wrapper.rsync
    ssh: true
    src: ['build/*']
    recursive: true
    args: ['--verbose']
    dest: 'talk-ui:/teambition/server/talk-ui/react-lite-image'
    deleteAll: true
  , (error, stdout, stderr, cmd) ->
    if error?
      throw error
    console.error stderr
    console.log cmd
    cb()

gulp.task 'html', (cb) ->
  if require.extensions?
    fs = require 'fs'
    require.extensions['.png'] = (module, filename) ->
      content = fs.readFileSync filename
      buf = new Buffer content
      module.exports = "data:image/png;base64," + buf.toString('base64')
      return module

  html = require('./template')
  fs = require('fs')
  assets = undefined

  unless env.dev
    assets = require('./build/assets.json')
    env.main = assets.main[0]
    env.vendor = assets.vendor
    env.style = assets.main[1]

  fs.writeFile 'build/index.html', html(env), cb

gulp.task 'del', (cb) ->
  del = require('del')
  del [ 'build' ], cb

gulp.task 'webpack', (cb) ->
  if env.dev
    command = 'webpack'
  else
    command = 'webpack --config webpack.min.coffee --progress'
  exec command, (err, stdout, stderr) ->
    console.log stdout
    console.log stderr
    cb err

gulp.task 'build', (cb) ->
  env.dev = false
  sequence 'del', 'webpack', 'html', cb
