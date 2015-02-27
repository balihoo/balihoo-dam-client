gulp = require 'gulp'
del = require 'del'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
istanbul = require 'gulp-istanbul'
mocha = require 'gulp-mocha'

sources =
  js: 'lib/**/*.js'
  coffee: 'src/**/*.coffee'
  test:
    unit: 'test/**/*.unit.coffee'
    system: 'test/system.coffee'
    integration: 'test/**/*.integration.coffee'

sources.test.all = (value for key, value of sources.test)

forceEnd = ->
  process.nextTick ->
    process.exit 0


gulp.task 'clean', (callback) ->
  del [sources.js], callback

gulp.task 'lint', ->
  gulp.src sources.coffee
  .pipe coffeelint()
  .pipe coffeelint.reporter()
  .pipe coffeelint.reporter 'fail'

gulp.task 'compile', ->
  gulp.src sources.coffee
  .pipe coffee({ bare: true })
  .pipe gulp.dest('lib/')

gulp.task 'unitTest', ['compile'], ->
  gulp.src sources.test.unit
  .pipe mocha()

gulp.task 'test', ['compile'], ->
  gulp.src sources.test.all
  .pipe mocha()
  .on 'end', forceEnd

gulp.task 'cover', ['compile'], ->
  gulp.src sources.js
  .pipe istanbul()
  .pipe istanbul.hookRequire()
  .on 'finish', ->
    gulp.src sources.test.all
    .pipe mocha()
    .pipe istanbul.writeReports()
    .on 'end', forceEnd

gulp.task 'build', ['clean', 'lint', 'cover']