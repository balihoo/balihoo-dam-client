###
  Full tests for integration with third parties is not something we should
  run on a regular basis.  However, for initial development and periodic checking
  of remote API's it might be nice to have this script around and run in every
  once in a while.
  
  Don't include this in the gulpfile on checkin.

  To run this
  * delete the file in the fb database to that it replies with fileExists:false
  * turn on FB and make sure configs are pointed at it
###

assert = require 'assert'
config = require '../config'

dc = require '../lib/balihoo-dam-client'
rewire = require 'rewire'

clone = (obj) ->
  if typeof obj isnt 'object'
    return obj
  cl = {}
  for key,val of obj
    cl[key] = clone val
  return cl

filename = "#{__dirname}/testupload.txt"

describe 'full integration test', ->

  uploadSuccessfullResult = null

  authBase = null
  before (done) ->
    dc.authorizeUploadFilename filename, (err, result) ->
      #      console.log err, result #save this output to authorizeUploadResult below
      authBase = JSON.parse result
      done(err)
      
  describe 'uploadFile', ->
    auth = null
    
    beforeEach (done) ->
      auth = clone authBase
      done()
        
    it "doesn't allow field with incorrect content-md5", (done) ->
      assert auth.fileExists is false, 'file already exists, delete asset with id ' + auth.assetid + ' in the db'
      origMD5 = auth.data['content-md5']
      auth.data['content-md5'] = 'notahash'
      dc.uploadFile filename, auth, (err, result) ->
        assert err
        assert.strictEqual err.message,
            "AccessDenied: Invalid according to Policy: Policy Condition failed: [\"eq\", \"$content-md5\", \"#{origMD5}\"]"
        done()
    it "doesn't allow field with incorrect key", (done) ->
      origkey = auth.data['key']
      auth.data['key'] = 'wrongkey'
      dc.uploadFile filename, auth, (err, result) ->
        assert.strictEqual err.message,
            "AccessDenied: Invalid according to Policy: Policy Condition failed: [\"eq\", \"$key\", \"#{origkey}\"]"
        done()
    it "doesn't allow a file that doesn't match the approved md5", (done) ->
      dc.uploadFile "#{__dirname}/../package.json", auth, (err, result) ->
        assert.strictEqual err.message,
            "BadDigest: The Content-MD5 you specified did not match what we received."
        done()
    it 'fails if content-md5 key excluded', (done) -> #should fail the same for any excluded key in the policy
      origMD5 = auth.data['content-md5']
      delete auth.data['content-md5']
      dc.uploadFile filename, auth, (err, result) ->
        assert.strictEqual err.message,
            "AccessDenied: Invalid according to Policy: Policy Condition failed: [\"eq\", \"$content-md5\", \"#{origMD5}\"]"
        done()
    it 'fetches the auth if not prefetched, then uploads the file', (done) ->
      dc.uploadFile filename, (err, result) ->
        assert.ifError err
        assert result.assetid
        assert result.url
        done()
    it 'posts the file with prefetched auth', (done) ->
      console.log 'auth'
      dc.uploadFile filename, auth, (err, result) ->
        console.log 'done second upload'
        assert.ifError err
        assert result.assetid
        assert result.url
        uploadSuccessfullResult = result
        done()
  describe 'authorizeUploadHash', ->
    it 'requires an md5', (done) ->
      dc.authorizeUploadHash '', (err, response) ->
        assert.strictEqual err.message,  'Required parameter key not provided.'
        done()
    it 'returns existing data when file already exists', (done) ->
      dc.authorizeUploadFilename filename, (err, result) ->
        auth = JSON.parse result
        assert.strictEqual auth.fileExists, true
        delete auth.fileExists
        assert.deepEqual uploadSuccessfullResult, auth
        done()
     