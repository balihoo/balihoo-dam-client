request = require 'request'
config = require '../config'
fs = require 'fs'
md5 = require 'MD5'
{parseString} = require 'xml2js'
mime = require 'mime'

fbconfig = config.formbuilder

exports.authorizeUploadHash = (fileMD5, cb) ->
      
  request {
    url: "#{fbconfig.url}/dam/authorizeUpload"
    method: 'GET'
    qs:
      key: fileMD5
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    if error
      return cb error
    if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
      body = JSON.parse incomingMessage.body
      err = new Error body.message
      err.code = body.code
      return cb err
    cb error, response

exports.authorizeUploadFilename = (filename, cb) ->
  fs.readFile filename, (err, buf) ->
    return cb err if err
    fileMD5 = md5 buf
    exports.authorizeUploadHash fileMD5, cb

exports.uploadFile = (filename, authorizeUploadResponse, cb) ->
  if typeof authorizeUploadResponse is 'function' #don't have auth yet
    cb = authorizeUploadResponse
    exports.authorizeUploadFilename filename, (err, auth) ->
      return cb err if err
      uploadFileWithAuth filename, JSON.parse(auth), cb
  else
    uploadFileWithAuth filename, authorizeUploadResponse, cb
      
uploadFileWithAuth = (filename, authorizeUploadResponse, cb) ->
  
  console.log 'uploading with auth'
  
  formData = authorizeUploadResponse.data
  formData['content-type'] = mime.lookup filename
  formData.file = fs.createReadStream filename #note: Anything in formData after file is ignored.

  request {
    url: authorizeUploadResponse.url
    method: 'POST'
    formData: formData
    followAllRedirects: true # required to follow POST redirects
  }, (error, incomingMessage, response) ->

    console.log 'request response', error, incomingMessage.headers, incomingMessage.body, response, '<<<'
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