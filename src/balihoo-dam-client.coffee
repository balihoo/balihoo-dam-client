request = require 'request'
fs = require 'fs'
SparkMD5 = require 'spark-md5'
async = require 'async'
{parseString} = require 'xml2js'
mime = require 'mime'

fbconfig = null

try
  config = require '../config'
  fbconfig = config.formbuilder
catch
finally

exports.config = (obj) ->
  fbconfig = obj.formbuilder

exports.authorizeUploadHash = (fileMD5, cb) ->
      
  request {
    url: "#{fbconfig.url}/dam/authorizeUpload"
    method: 'GET'
    qs:
      key: fileMD5
#    auth:
#      username: fbconfig.username
#      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
      catch ex
        err = new Error "Error authorizing upload (#{incomingMessage.statusCode}): #{incomingMessage.body}"
        err.code = 500
    cb error, response

# Spark takes ArrayBuffer, so convert here
# http://stackoverflow.com/questions/8609289/convert-a-binary-nodejs-buffer-to-javascript-arraybuffer/12101012#12101012
toArrayBuffer = (buffer, len) ->
  ab = new ArrayBuffer(len)
  view = new Uint8Array(ab)
  view[i] = buffer[i] for i in [0...len]
  view

bufSize = 1024 * 1024 * 2 # 2 MB
buf = new Buffer bufSize
readChunk = (fd, fileOffset, cb) ->
  fs.read fd, buf, 0, bufSize, fileOffset, (err, bytesRead) ->
    return callback err if err
    cb null, toArrayBuffer buf, bytesRead
    
exports.calculateFileMD5 = calculateFileMD5 = (filename, cb) ->
  fs.open filename, 'r', (err, fd) ->
    return cb err if err
    fs.fstat fd, (err, stats) ->
      return cb err if err
      fileSize = stats.size
      
      spark = new SparkMD5.ArrayBuffer()
      fileOffset = 0

      async.whilst -> #test first
        fileOffset < fileSize
      , (callback) -> #do this every loop
        readChunk fd, fileOffset, (err, chunk) ->
          return callback err if err
          spark.append chunk
          fileOffset += chunk.length
          callback()
      , (err) -> #finally do this
        cb err, spark.end()

exports.authorizeUploadFilename = (filename, cb) ->
  calculateFileMD5 filename, (err, md5) ->
    return cb err if err
    exports.authorizeUploadHash md5, cb

exports.uploadFile = (filename, authorizeUploadResponse, cb) ->
  if typeof authorizeUploadResponse is 'function' #don't have auth yet
    cb = authorizeUploadResponse
    exports.authorizeUploadFilename filename, (err, auth) ->
      return cb err if err
      uploadFileWithAuth filename, JSON.parse(auth), cb
  else
    uploadFileWithAuth filename, authorizeUploadResponse, cb
      
uploadFileWithAuth = (filename, authorizeUploadResponse, cb) ->
  if authorizeUploadResponse.fileExists is true
    return cb null, authorizeUploadResponse
  
  formData = authorizeUploadResponse.data
  formData['content-type'] = mime.lookup filename
  formData.file = fs.createReadStream filename #note: Anything in formData after file is ignored.

  request {
    url: authorizeUploadResponse.url
    method: 'POST'
    formData: formData
    followAllRedirects: true # required to follow POST redirects
  }, (error, incomingMessage, response) ->

    if error
      cb error
    if incomingMessage.headers['content-type'] is 'application/xml' #error uploading to s3
      parseString incomingMessage.body, (parseError, parseResult) ->
        if parseError
          cb new Error "Failed to parse upload response: #{parseError.message}"
        else
          cb  new Error "#{parseResult.Error.Code}: #{parseResult.Error.Message}"
    else
      cb null, JSON.parse response

exports.getForm = (formid, version = 1, cb) ->
  request "#{fbconfig.url}/forms/#{formid}/version/#{version}", {
    method: 'GET'
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
        return cb err
      catch ex
        console.log incomingMessage.body
        return cb new Error "Error getting form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
    cb error, incomingMessage, response

exports.saveForm = (formid, version, form, cb) ->
  request "#{fbconfig.url}/forms/#{formid}/version/#{version}", {
    method: 'PUT'
    json: form
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
        return cb err
      catch ex
        console.log incomingMessage.body
        return cb new Error "Error saving form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
    cb error, incomingMessage, response

exports.newForm = (form, cb) ->
  request "#{fbconfig.url}/forms", {
    method: 'POST'
    json: form
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
        return cb err
      catch ex
        console.log incomingMessage.body
        return cb new Error "Error creating new form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
    cb error, incomingMessage, response

exports.publishForm = (formid, form, cb) ->
  request "#{fbconfig.url}/forms/#{formid}/version/1/publish", {
    method: 'POST'
    json: form
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
        return cb err
      catch ex
        console.log incomingMessage.body
        return cb new Error "Error saving form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
    cb error, incomingMessage, response

exports.newDraft = (formid, form, cb) ->
  request "#{fbconfig.url}/forms/#{formid}/version", {
    method: 'POST'
    json: form
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      try
        body = JSON.parse incomingMessage.body
        err = new Error body.message
        err.code = body.code
        return cb err
      catch ex
        console.log incomingMessage.body
        return cb new Error "Error creating new form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
    cb error, incomingMessage, response