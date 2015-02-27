request = require 'request'
config = require '../config'
fs = require 'fs'
md5 = require 'MD5'

fbconfig = config.formbuilder

exports.authorizeUploadHash = (fileMD5, cb) ->
      
  request {
    url: "#{fbconfig.url}/dam/authorizeUpload"
    method: 'POST'
    json: true
    body:
      fileMD5: fileMD5
    auth:
      username: fbconfig.username
      password: fbconfig.password
  }, (error, incomingMessage, response) ->
    cb error, response

exports.authorizeUpload = (filename, cb) ->
  fs.readFile filename, (err, buf) ->
    cb err if err
    fileMD5 = md5 buf
    exports.authorizeUploadHash fileMD5, cb
    
#todo: allow no auth response.  fetch it here.  maybe wrapped elsewhere
exports.uploadFile = (filename, authorizeUploadResponse, cb) ->

  if !authorizeUploadResponse.authorized
    return cb new Error 'Upload not authorized'

  formData = authorizeUploadResponse.data
  formData.file = fs.createReadStream filename
  
  request {
    url: authorizeUploadResponse.url
    method: 'POST'
    formData: formData
  }, (error, incomingMessage, response) ->
    #todo: response might be something other than success
    console.log 'return from post', arguments
    cb error, response