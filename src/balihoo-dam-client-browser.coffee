# The browser-based version of the dam client.

$ = require 'jquery-ajax'
SparkMD5 = require 'spark-md5'
mime = require 'mime'

exports = window.balihoo_dam_client = {}
exports.formbuilderUrl = null

blobSlice = File.prototype.slice or File.prototype.mozSlice or File.prototype.webkitSlice


exports.authorizeUploadHash = (fileMD5, cb) ->
  
  #allow config here or in window.formbuilderui
  base = exports.formbuilderUrl or window.formbuilderui?.formbuilderUrl
  unless base
    return cb new Error "Missing configs.  Please set window.balihoo_dam_client.fburl or window.formbuilderui.formbuilderUrl"
    
  # end with / for substition later
  if base[base.length-1] isnt '/'
    base += '/'
  
  $.ajax({
    url: "#{base}dam/authorizeUpload"
    method: 'GET'
    data: key: fileMD5
    crossDomain: true
  })
  .done (result)->
    cb null, result
  .fail (jqXHR, textStatus, errorThrown) ->
    cb new Error "Error authorizing upload (#{jqXHR.status}): #{errorThrown}"

exports.calculateFileMD5 = calculateFileMD5 = (file, cb) ->
  fileReader = new FileReader()
  chunkSize = 1024 * 1024 * 2 # 2MB
  chunks = Math.ceil file.size / chunkSize
  currentChunk = 0
  spark = new SparkMD5.ArrayBuffer()
  
  fileReader.onload = (e) ->
    spark.append e.target.result
    currentChunk += 1
    if currentChunk < chunks
      loadNext()
    else
      cb null, spark.end()
      
  fileReader.onerror = (e) ->
    cb new Error "Error reading file during MD5 calculation. #{e}"

  loadNext = ->
    start = currentChunk * chunkSize
    end = if start + chunkSize >= file.size then file.size else start + chunkSize
    fileReader.readAsArrayBuffer blobSlice.call file, start, end
    
  loadNext()


# file is a browser File object
exports.authorizeUploadFile = (file, cb) ->
  calculateFileMD5 file, (err, fileMD5) ->
    return cb err if err
    exports.authorizeUploadHash fileMD5, cb

# file is a browser File object
exports.uploadFile = (file, authorizeUploadResponse, cb) ->
  if typeof authorizeUploadResponse is 'function' #don't have auth yet
    cb = authorizeUploadResponse
    exports.authorizeUploadFile file, (err, auth) ->
      return cb err if err
      uploadFileWithAuth file, auth, cb
  else
    uploadFileWithAuth file, authorizeUploadResponse, cb

uploadFileWithAuth = (file, authorizeUploadResponse, cb) ->
  if authorizeUploadResponse.fileExists is true
    return cb null, authorizeUploadResponse

  formData = new FormData()
  for key,val of authorizeUploadResponse.data
    formData.append key, val
  formData.append 'content-type', mime.lookup file.name
  formData.append 'file', file

  $.ajax({
    url: authorizeUploadResponse.url
    method: 'POST'
    data: formData
    cache: false
    contentType: false
    processData: false
    crossDomain: true
  })
  .fail (jqXHR, textStatus, errorThrown) ->
    cb new Error "Error uploading file (#{jqXHR.status}): #{errorThrown}"
  .done (result) ->
    cb null, result
