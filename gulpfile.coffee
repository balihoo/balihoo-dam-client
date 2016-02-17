gulp = require 'gulp'
del = require 'del'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
istanbul = require 'gulp-istanbul'
mocha = require 'gulp-mocha'
coffeeify = require 'gulp-coffeeify'

sources =
  js: 'lib/**/*.js'
  coffee: 
    node: 'src/balihoo-dam-client.coffee'
    browser: 'src/balihoo-dam-client-browser.coffee'
  test:
    unit: 'test/**/*.unit.coffee'
    system: 'test/system.coffee'
#    integration: 'test/**/*.integration.coffee'

sources.test.all = (value for key, value of sources.test)
sources.coffee.all = (value for key, value of sources.coffee)

forceEnd = ->
  process.nextTick ->
    process.exit 0


gulp.task 'clean', (callback) ->
  del [sources.js], callback

gulp.task 'lint', ->
  gulp.src sources.coffee.all
  .pipe coffeelint()
  .pipe coffeelint.reporter()
  .pipe coffeelint.reporter 'fail'

gulp.task 'compile-browser', ->
  gulp.src sources.coffee.browser
  .pipe coffeeify() #coffee and browserify
  .pipe gulp.dest 'lib/'
  
gulp.task 'compile-node', ->
  gulp.src sources.coffee.node
  .pipe coffee({ bare: true })
  .pipe gulp.dest('lib/')
  
gulp.task 'compile', ['compile-node','compile-browser']

gulp.task 'unitTest', ['compile'], ->
  gulp.src sources.test.unit
  .pipe mocha()

gulp.task 'test', ['compile'], ->
  gulp.src sources.test.all
  .pipe mocha()
  .on 'end', forceEnd

gulp.task 'build', ['clean', 'lint', 'test']

gulp.task 'default', ['build']