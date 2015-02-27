###
  Full tests for integration with third parties is not something we should
  run on a regular basis.  However, for initial development and periodic checking
  of remote API's it might be nice to have this script around and run in every
  once in a while.
  
  Don't include this in the gulpfile on checkin.
###

assert = require 'assert'
config = require '../config'

dc = require '../lib/balihoo-dam-client'
rewire = require 'rewire'

describe 'uploadFile', ->
  it 'posts the file', (done) ->
    filename = "#{__dirname}/../config.js.default"
    dc.authorizeUpload filename, (err, authed) ->
      assert.ifError err
      dc.uploadFile filename, authed, (err, result) ->
        console.log 'uploadFile result', err, result
        assert.ifError err
        done()